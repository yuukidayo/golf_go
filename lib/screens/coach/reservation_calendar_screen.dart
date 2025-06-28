import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../models/time_slot.dart';
import '../../models/plan.dart';

class ReservationCalendarScreen extends StatefulWidget {
  const ReservationCalendarScreen({super.key});

  @override
  State<ReservationCalendarScreen> createState() => _ReservationCalendarScreenState();
}

class _ReservationCalendarScreenState extends State<ReservationCalendarScreen> {
  // カレンダー関連
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // 予約データ
  bool _isLoading = false;
  List<TimeSlot> _reservations = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadReservationsForDate(_selectedDay!);
  }
  
  // 選択した日付の予約を読み込む
  Future<void> _loadReservationsForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
      _reservations = []; // リセット
    });
    
    try {
      // TODO: Firestoreから選択日の予約データを取得する実装
      // この部分は次のステップで実装
      
      // 仮データを設定（開発中のみ）
      await Future.delayed(const Duration(seconds: 1)); // 読み込み中の表示をテスト
      
      setState(() {
        // 仮データ
        _reservations = [
          TimeSlot(
            id: '1',
            planId: 'plan1',
            startTime: '09:00',
            endTime: '10:00',
            price: 5000,
          ),
          TimeSlot(
            id: '2',
            planId: 'plan2',
            startTime: '14:00',
            endTime: '15:30',
            price: 7500,
          ),
        ];
      });
      
      debugPrint('予約データ読み込み完了: ${_reservations.length}件');
    } catch (e) {
      debugPrint('予約データ読み込みエラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('予約データの読み込みに失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('予約管理'),
        backgroundColor: AppColors.gold,
        actions: [], // 必要に応じてアクションを追加
      ),
      body: Column(
        children: [
          // カレンダー部分
          TableCalendar(
            firstDay: DateTime.utc(2022, 1, 1),
            lastDay: DateTime.utc(2026, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadReservationsForDate(selectedDay);
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarStyle: const CalendarStyle(
              // カレンダーのスタイル設定
              todayDecoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 選択日の表示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              '${DateFormat('yyyy年MM月dd日').format(_selectedDay!)} の予約',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 予約一覧
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _reservations.isEmpty
                ? const Center(child: Text('この日の予約はありません'))
                : ListView.builder(
                    itemCount: _reservations.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final reservation = _reservations[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            '${reservation.startTime} 〜 ${reservation.endTime}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '¥${reservation.price.toString().replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
                              (Match m) => '${m[1]},'
                            )}',
                            style: const TextStyle(
                              color: AppColors.gold, 
                              fontWeight: FontWeight.w500
                            ),
                          ),
                          trailing: const Icon(Icons.info_outline),
                          onTap: () {
                            // TODO: 予約詳細画面への遷移
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('予約詳細表示機能は次のステップで実装します')),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
