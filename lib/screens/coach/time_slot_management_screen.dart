import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/plan.dart';
import '../../models/time_slot.dart';
import '../../theme/app_theme.dart';
import 'time_slot_edit_screen.dart';

class TimeSlotManagementScreen extends StatefulWidget {
  final Plan plan; // 予約枠を管理するプラン

  const TimeSlotManagementScreen({
    Key? key,
    required this.plan,
  }) : super(key: key);

  @override
  State<TimeSlotManagementScreen> createState() => _TimeSlotManagementScreenState();
}

class _TimeSlotManagementScreenState extends State<TimeSlotManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  
  List<TimeSlot> _timeSlots = [];
  bool _isLoading = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  
  @override
  void initState() {
    super.initState();
    _loadTimeSlots();
  }
  
  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }
  
  // フォームをリセット
  void _resetForm() {
    setState(() {
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 0);
      _priceController.clear();
      _isLoading = false;
    });
  }
  
  // 編集画面に遷移する
  void _editTimeSlot(TimeSlot timeSlot) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TimeSlotEditScreen(
          timeSlot: timeSlot,
          planId: widget.plan.id,
          onUpdated: () {
            _loadTimeSlots();
          },
        ),
      ),
    );
  }
  
  // 予約枠を読み込む
  Future<void> _loadTimeSlots() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('time_slots')
          .where('planId', isEqualTo: widget.plan.id)
          .get();
      
      setState(() {
        _timeSlots = snapshot.docs
            .map((doc) => TimeSlot.fromFirestore(doc))
            .toList();
            
        // 手動でソート
        _timeSlots.sort((a, b) => a.startTime.compareTo(b.startTime));
      });
    } catch (e, stackTrace) {
      debugPrint('予約枠読み込みエラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('予約枠の読み込みに失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 予約枠が時間的に重複しているかチェック
  bool _isTimeSlotOverlapping(String newStartTime, String newEndTime) {
    for (final timeSlot in _timeSlots) {
      final existingStartMinutes = _timeStringToMinutes(timeSlot.startTime);
      final existingEndMinutes = _timeStringToMinutes(timeSlot.endTime);
      final newStartMinutes = _timeStringToMinutes(newStartTime);
      final newEndMinutes = _timeStringToMinutes(newEndTime);
      
      if (newStartMinutes < existingEndMinutes && newEndMinutes > existingStartMinutes) {
        return true;
      }
    }
    return false;
  }
  
  // 時間文字列（HH:MM）を分単位の整数に変換
  int _timeStringToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // 予約枠を追加
  Future<void> _addTimeSlot() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final priceText = _priceController.text.replaceAll(',', '').replaceAll('¥', '');
    final price = int.tryParse(priceText) ?? 0;
    
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('有効な料金を入力してください')),
      );
      return;
    }
    
    final startTimeStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';
    
    if (_isTimeSlotOverlapping(startTimeStr, endTimeStr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('他の予約枠と時間が重複しています。別の時間を選択してください。'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final docRef = await FirebaseFirestore.instance.collection('time_slots').add({
        'planId': widget.plan.id,
        'startTime': startTimeStr,
        'endTime': endTimeStr,
        'price': price,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final newTimeSlot = TimeSlot(
        id: docRef.id,
        planId: widget.plan.id,
        startTime: startTimeStr,
        endTime: endTimeStr,
        price: price,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      setState(() {
        _timeSlots.add(newTimeSlot);
        _timeSlots.sort((a, b) => a.startTime.compareTo(b.startTime));
      });
      
      _priceController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('予約枠を追加しました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('予約枠の追加に失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 予約枠を削除
  Future<void> _deleteTimeSlot(TimeSlot timeSlot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予約枠の削除'),
        content: Text('${timeSlot.startTime}〜${timeSlot.endTime}の予約枠を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirmed) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await FirebaseFirestore.instance
          .collection('time_slots')
          .doc(timeSlot.id)
          .delete();
      
      setState(() {
        _timeSlots.removeWhere((slot) => slot.id == timeSlot.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('予約枠を削除しました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('予約枠の削除に失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 時刻選択ダイアログを表示
  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.gold,
              onPrimary: Colors.white,
              onSurface: AppColors.luxuryText,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          if (_timeToMinutes(_startTime) >= _timeToMinutes(_endTime)) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          if (_timeToMinutes(picked) <= _timeToMinutes(_startTime)) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          } else {
            _endTime = picked;
          }
        }
      });
    }
  }
  
  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Center(
          child: Text(
            '予約枠管理 - ${widget.plan.title}',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: _isLoading ? null : _addTimeSlot,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '追加', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 予約枠追加フォーム
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '新しい予約枠を追加',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // 時間設定
                            const Text('予約時間'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime(context, true),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        labelText: '開始時間',
                                      ),
                                      child: Text(
                                        '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime(context, false),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        labelText: '終了時間',
                                      ),
                                      child: Text(
                                        '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // 料金設定
                            const Text('料金（円）'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: '例: 5000',
                                prefixText: '¥ ',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '料金を入力してください';
                                }
                                final priceValue = int.tryParse(value.replaceAll(',', ''));
                                if (priceValue == null) {
                                  return '数値を入力してください';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                // カンマ区切りの表示に変換
                                final text = value.replaceAll(',', '');
                                if (text.isEmpty) return;
                                
                                final number = int.tryParse(text);
                                if (number == null) return;
                                
                                final formatter = NumberFormat('#,###');
                                final formattedText = formatter.format(number);
                                
                                if (formattedText != value) {
                                  _priceController.value = TextEditingValue(
                                    text: formattedText,
                                    selection: TextSelection.collapsed(
                                      offset: formattedText.length,
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // ボタンを非表示に
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // 登録済み予約枠リスト
                  const Text(
                    '登録済み予約枠',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  _timeSlots.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Text('登録済みの予約枠はありません'),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _timeSlots.length,
                          itemBuilder: (context, index) {
                            final timeSlot = _timeSlots[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: Text(
                                  '${timeSlot.startTime} 〜 ${timeSlot.endTime}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '¥${timeSlot.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w500),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 編集ボタン
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editTimeSlot(timeSlot),
                                      tooltip: '編集',
                                    ),
                                    // 削除ボタン
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteTimeSlot(timeSlot),
                                      tooltip: '削除',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
