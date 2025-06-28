import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
// TODO: Firestoreとの連携時に使用
// import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../models/time_slot.dart';
// TODO: プラン情報と連携時に使用
// import '../../models/plan.dart';

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
  
  // イベントマーカー用のマップ
  Map<DateTime, List<TimeSlot>> _eventsByDay = {};

  // 選択日の予約データにマーカーを表示するための関数
  List<TimeSlot> _getEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _eventsByDay[normalizedDate] ?? [];
  }
  
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMonthEvents(_focusedDay);
  }

  // 月の予約データを読み込む - カレンダーのイベントマーカー用
  Future<void> _loadMonthEvents(DateTime month) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Firestoreから月全体の予約データを取得する実装
      // この部分は次のステップで実装
      
      // 仮データを設定（開発中のみ）
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 仮データでいくつかの日に予約を設定
      final Map<DateTime, List<TimeSlot>> mockEvents = {};
      
      // 今月の複数の日に予約を割り当て
      // TODO: Firestore実装時にこの日付範囲を使用してクエリ
      // final DateTime firstDay = DateTime(month.year, month.month, 1);
      final DateTime lastDay = DateTime(month.year, month.month + 1, 0);
      
      // いくつかの日に予約を追加（開発用サンプル）
      for (int i = 5; i < 28; i += 4) {
        if (i <= lastDay.day) {
          final eventDate = DateTime(month.year, month.month, i);
          mockEvents[eventDate] = [
            TimeSlot(
              id: 'event$i-1',
              planId: 'plan1',
              startTime: '10:00',
              endTime: '11:00',
              price: 5000,
            ),
            TimeSlot(
              id: 'event$i-2',
              planId: 'plan2',
              startTime: '14:00',
              endTime: '15:30',
              price: 7500,
            ),
          ];
        }
      }
      
      setState(() {
        _eventsByDay = mockEvents;
        // 選択されている日の予約を設定
        _loadSelectedDayEvents();
      });
      
    } catch (e) {
      debugPrint('月間予約データ読み込みエラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('予約データの読み込みに失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 選択した日付の予約を読み込む
  void _loadSelectedDayEvents() {
    if (_selectedDay != null) {
      final selectedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      setState(() {
        _reservations = _eventsByDay[selectedDate] ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // 戻るボタンの操作を無効化
      onWillPop: () async => false,
      child: Scaffold(
      appBar: AppBar(
        // 戻るボタンを非表示に設定
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          '予約管理',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.gold,
        elevation: 0,
        actions: [
          // 更新ボタン
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadMonthEvents(_focusedDay);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('予約データを更新しました')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // カレンダー部分
          Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TableCalendar<TimeSlot>(
                firstDay: DateTime.utc(2022, 1, 1),
                lastDay: DateTime.utc(2026, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                eventLoader: _getEventsForDay, // イベントローダーを設定
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _loadSelectedDayEvents(); // 選択した日の予約を表示
                  });
                },
                onPageChanged: (focusedDay) {
                  // 月が変わった時にそのデータを再取得
                  _focusedDay = focusedDay;
                  _loadMonthEvents(focusedDay);
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                calendarStyle: CalendarStyle(
                  // カレンダーのスタイル設定
                  isTodayHighlighted: true,
                  todayDecoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  markerSize: 7.0,
                  markersMaxCount: 3,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  headerPadding: const EdgeInsets.symmetric(vertical: 4.0),
                  titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  formatButtonShowsNext: false,
                  // 月表示を日本語形式に変更
                  titleTextFormatter: (date, locale) {
                    return '${date.year}年${date.month}月';
                  },
                ),
              ),
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
      // 同じナビゲーションメニューを実装
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // 予約管理タブ選択
        onTap: (_) {
          // タブのタップは親画面(CoachMainScreen)で処理するため何もしない
        },
        selectedItemColor: AppColors.gold,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list_outlined),
            activeIcon: Icon(Icons.view_list),
            label: 'プラン管理',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: '予約管理',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: 'マイページ',
          ),
        ],
      ),
      ),
    );
  }
}
