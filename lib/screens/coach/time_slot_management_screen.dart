import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/plan.dart';
import '../../models/time_slot.dart';
import '../../theme/app_theme.dart';

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
  bool _isLoading = false;
  List<TimeSlot> _timeSlots = [];
  
  // 新規タイムスロット用コントローラー
  final TextEditingController _priceController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0); // デフォルト開始時間
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0); // デフォルト終了時間
  
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
  
  // TimeOfDayを分単位に変換（比較用）
  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }
  
  // 予約枠を読み込む
  Future<void> _loadTimeSlots() async {
    setState(() {
      _isLoading = true;
    });
    
    debugPrint('予約枠読み込み開始 - プランID: ${widget.plan.id}');
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('time_slots')
          .where('planId', isEqualTo: widget.plan.id)
          .get(); // orderByを一時的に削除して基本的なクエリだけで動作確認
      
      debugPrint('予約枠クエリ結果: ${snapshot.docs.length} 件のドキュメントを取得');
      
      // ドキュメントのデバッグ出力
      for (var doc in snapshot.docs) {
        final data = doc.data();
        debugPrint('取得したドキュメント - ID: ${doc.id}, データ: $data');
      }
      
      setState(() {
        _timeSlots = snapshot.docs
            .map((doc) => TimeSlot.fromFirestore(doc))
            .toList();
            
        // 手動でソート
        _timeSlots.sort((a, b) => a.startTime.compareTo(b.startTime));
      });
      
      debugPrint('予約枠の読み込み完了: ${_timeSlots.length} 件');
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
  
  // 予約枠を追加
  Future<void> _addTimeSlot() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // 金額をパース
    final priceText = _priceController.text.replaceAll(',', '').replaceAll('¥', '');
    final price = int.tryParse(priceText) ?? 0;
    
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('有効な料金を入力してください')),
      );
      return;
    }
    
    // 開始・終了時刻をフォーマット
    final startTimeStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Firestoreに保存
      final docRef = await FirebaseFirestore.instance.collection('time_slots').add({
        'planId': widget.plan.id,
        'startTime': startTimeStr,
        'endTime': endTimeStr,
        'price': price,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // UIに追加
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
        // 開始時刻順にソート
        _timeSlots.sort((a, b) => a.startTime.compareTo(b.startTime));
      });
      
      // フォームをクリア
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
      // Firestoreから削除
      await FirebaseFirestore.instance
          .collection('time_slots')
          .doc(timeSlot.id)
          .delete();
      
      // UIから削除
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
          // 開始時刻が終了時刻より遅い場合、終了時刻を調整
          if (_timeToMinutes(_startTime) >= _timeToMinutes(_endTime)) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          // 終了時刻が開始時刻より早い場合は調整
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('予約枠管理 - ${widget.plan.title}'),
        backgroundColor: AppColors.gold,
        actions: [], // 右上のplusIconsを非表示にするため空のリストを設定
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
                            
                            // 追加ボタン
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.gold,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _addTimeSlot,
                                child: const Text('予約枠を追加'),
                              ),
                            ),
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
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteTimeSlot(timeSlot),
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
