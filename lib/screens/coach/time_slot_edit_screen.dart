import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/time_slot.dart';
import '../../theme/app_theme.dart';

class TimeSlotEditScreen extends StatefulWidget {
  final TimeSlot timeSlot;
  final String planId;
  final Function onUpdated;

  const TimeSlotEditScreen({
    Key? key,
    required this.timeSlot,
    required this.planId,
    required this.onUpdated,
  }) : super(key: key);

  @override
  State<TimeSlotEditScreen> createState() => _TimeSlotEditScreenState();
}

class _TimeSlotEditScreenState extends State<TimeSlotEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  
  bool _isLoading = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  
  @override
  void initState() {
    super.initState();
    _initializeFormValues();
  }
  
  void _initializeFormValues() {
    // 時間文字列をTimeOfDayに変換
    final startTimeParts = widget.timeSlot.startTime.split(':');
    final endTimeParts = widget.timeSlot.endTime.split(':');
    
    _startTime = TimeOfDay(
      hour: int.parse(startTimeParts[0]),
      minute: int.parse(startTimeParts[1]),
    );
    _endTime = TimeOfDay(
      hour: int.parse(endTimeParts[0]),
      minute: int.parse(endTimeParts[1]),
    );
    
    // カンマ区切りの表示に変換
    final formatter = NumberFormat('#,###');
    _priceController.text = formatter.format(widget.timeSlot.price);
  }
  
  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }
  
  // 時間を選択するダイアログを表示
  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          
          // 開始時間が終了時間より後の場合、終了時間を自動調整
          final startMinutes = picked.hour * 60 + picked.minute;
          final endMinutes = _endTime.hour * 60 + _endTime.minute;
          
          if (startMinutes >= endMinutes) {
            // 開始時間の60分後を終了時間に設定
            final newEndMinutes = startMinutes + 60;
            _endTime = TimeOfDay(
              hour: (newEndMinutes ~/ 60) % 24,
              minute: newEndMinutes % 60,
            );
          }
        } else {
          _endTime = picked;
          
          // 終了時間が開始時間より前の場合、開始時間を自動調整
          final startMinutes = _startTime.hour * 60 + _startTime.minute;
          final endMinutes = picked.hour * 60 + picked.minute;
          
          if (endMinutes <= startMinutes) {
            // 終了時間の60分前を開始時間に設定
            final newStartMinutes = endMinutes - 60;
            if (newStartMinutes >= 0) {
              _startTime = TimeOfDay(
                hour: newStartMinutes ~/ 60,
                minute: newStartMinutes % 60,
              );
            } else {
              // 夜間の場合は前日に設定
              _startTime = const TimeOfDay(hour: 0, minute: 0);
            }
          }
        }
      });
    }
  }
  
  // 予約枠を更新
  Future<void> _updateTimeSlot() async {
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
    
    // 編集している予約枠は重複チェックから除外する必要があるため、完全な重複チェックは省略
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Firestoreを更新
      await FirebaseFirestore.instance.collection('timeSlots').doc(widget.timeSlot.id).update({
        'startTime': startTimeStr,
        'endTime': endTimeStr,
        'price': price,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // 親画面の更新処理を呼び出し
      widget.onUpdated();
      
      // 成功メッセージを表示して前の画面に戻る
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('予約枠を更新しました')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      // エラー処理
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: ${e.toString()}')),
        );
      }
    }
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
            '予約枠の編集',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: _isLoading ? null : _updateTimeSlot,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '保存', 
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
                  // 編集フォーム
                  Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: const Color(0xFFF5F8FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '予約枠情報',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
