import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../models/time_slot.dart';

class ReservationCalendarScreen extends StatefulWidget {
  const ReservationCalendarScreen({super.key});

  @override
  State<ReservationCalendarScreen> createState() => _ReservationCalendarScreenState();
}

class _ReservationCalendarScreenState extends State<ReservationCalendarScreen> {
  // 表示モード
  bool _isCalendarView = false; // デフォルトはリスト表示
  
  // カレンダー関連
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // 予約データ
  bool _isLoading = false;
  List<Map<String, dynamic>> _reservations = []; // カレンダー選択日の予約
  List<Map<String, dynamic>> _upcomingReservations = []; // 直近の予約(リスト表示用)
  
  // イベントマーカー用のマップ
  Map<DateTime, List<Map<String, dynamic>>> _eventsByDay = {};

  // 選択日の予約データにマーカーを表示するための関数
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _eventsByDay[normalizedDate] ?? [];
  }
  
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _isCalendarView = false; // 明示的にリスト表示に設定
    _loadUpcomingReservations(); // リスト表示用の直近予約を読み込む
    print('初期表示モード: ${_isCalendarView ? "カレンダー表示" : "リスト表示"}');
  }

  // 月の予約データを読み込む - カレンダーのイベントマーカー用
  Future<void> _loadMonthEvents(DateTime month) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 現在ログインしているコーチのIDを取得
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('ログインされていません');
      }
      final coachId = currentUser.uid;
      
      print('📅 月間予約データを読み込み中: ${month.year}年${month.month}月, コーチID: $coachId');
      
      // 月の期間情報
      final DateTime monthStart = DateTime(month.year, month.month, 1);
      final DateTime monthEnd = DateTime(month.year, month.month + 1, 0);
      debugPrint('📅 対象期間: ${monthStart.toString().substring(0, 10)} ~ ${monthEnd.toString().substring(0, 10)}');
      
      // 1. コーチのプランIDを取得
      final plansSnapshot = await FirebaseFirestore.instance
          .collection('plans')
          .where('coachId', isEqualTo: coachId)
          .get();
      
      final planIds = plansSnapshot.docs.map((doc) => doc.id).toList();
      if (planIds.isEmpty) {
        setState(() {
          _eventsByDay = {};
          _loadSelectedDayEvents();
          _isLoading = false;
        });
        return;
      }
      
      print('🔍 ${planIds.length}件のプランが見つかりました');
      
      // 2. プランに関連する予約枠を取得
      final timeSlotsSnapshot = await FirebaseFirestore.instance
          .collection('timeSlots')
          .where('planId', whereIn: planIds)
          .get();
      
      final timeSlotIds = timeSlotsSnapshot.docs.map((doc) => doc.id).toList();
      if (timeSlotIds.isEmpty) {
        setState(() {
          _eventsByDay = {};
          _loadSelectedDayEvents();
          _isLoading = false;
        });
        return;
      }
      
      print('🔍 ${timeSlotIds.length}件の予約枠が見つかりました');
      
      // 予約枠データをマップに格納
      final Map<String, dynamic> timeSlotMap = {};
      for (final doc in timeSlotsSnapshot.docs) {
        final timeSlot = TimeSlot.fromFirestore(doc);
        timeSlotMap[timeSlot.id] = {
          'id': timeSlot.id,
          'planId': timeSlot.planId,
          'startTime': timeSlot.startTime,
          'endTime': timeSlot.endTime,
          'price': timeSlot.price,
        };
      }
      
      // 3. 予約枠に紐づく予約を取得
      final reservationsSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('timeSlotId', whereIn: timeSlotIds)
          .get();
      
      print('🔍 ${reservationsSnapshot.docs.length}件の予約が見つかりました');
      
      // 予約データを日付ごとにグループ化
      final Map<DateTime, List<Map<String, dynamic>>> eventsByDay = {};
      
      for (final doc in reservationsSnapshot.docs) {
        final reservationData = doc.data();
        final timeSlotId = reservationData['timeSlotId'] as String;
        final reservationDate = (reservationData['date'] as Timestamp).toDate();
        
        // 対象の月の予約のみ処理
        if (reservationDate.year == month.year && reservationDate.month == month.month) {
          final eventDate = DateTime(reservationDate.year, reservationDate.month, reservationDate.day);
          
          // 予約枠情報を結合
          final timeSlotInfo = timeSlotMap[timeSlotId];
          if (timeSlotInfo != null) {
            final combinedData = {
              'id': doc.id,
              'userId': reservationData['userId'],
              'date': eventDate,
              'startTime': timeSlotInfo['startTime'],
              'endTime': timeSlotInfo['endTime'],
              'price': timeSlotInfo['price'],
              'status': reservationData['status'] ?? 'confirmed',
              'userName': reservationData['userName'] ?? '名前未登録',
            };
            
            if (eventsByDay[eventDate] == null) {
              eventsByDay[eventDate] = [];
            }
            
            eventsByDay[eventDate]!.add(combinedData);
          }
        }
      }
      
      setState(() {
        _eventsByDay = eventsByDay;
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

  // 選択した日の予約を読み込む
  Future<void> _loadSelectedDayEvents() async {
    if (_selectedDay == null) return;
    
    final normalizedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    setState(() {
      _reservations = _eventsByDay[normalizedDate] ?? [];
      _reservations.sort((a, b) => (a['startTime'] as String).compareTo(b['startTime'] as String));
    });
  }
  
  // 直近の予約データを読み込む（リスト表示用）
  Future<void> _loadUpcomingReservations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // 今日の日付
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      // コーチのプランを取得
      final planSnapshot = await FirebaseFirestore.instance
          .collection('plans')
          .where('coachId', isEqualTo: user.uid)
          .get();

      if (planSnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _upcomingReservations.clear();
        });
        return;
      }

      final planIds = planSnapshot.docs.map((doc) => doc.id).toList();
      
      // 予約枠を取得
      final timeSlotSnapshot = await FirebaseFirestore.instance
          .collection('timeSlots')
          .where('planId', whereIn: planIds)
          .get();

      if (timeSlotSnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _upcomingReservations.clear();
        });
        return;
      }

      final timeSlotIds = timeSlotSnapshot.docs.map((doc) => doc.id).toList();
      final Map<String, dynamic> timeSlotMap = {};
      for (var doc in timeSlotSnapshot.docs) {
        timeSlotMap[doc.id] = doc.data();
      }

      // 今日以降の予約を取得（最大30件）
      final reservationSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('timeSlotId', whereIn: timeSlotIds)
          .limit(30)
          .get();

      // 予約情報をマッピングし、日付でソート
      final List<Map<String, dynamic>> upcomingList = [];
      
      for (var doc in reservationSnapshot.docs) {
        final reservationData = doc.data();
        final timeSlotId = reservationData['timeSlotId'] as String;
        
        // 対応する予約枠データを取得
        final timeSlotData = timeSlotMap[timeSlotId];
        if (timeSlotData == null) continue;
        
        // 日付の処理
        final date = (timeSlotData['date'] as Timestamp).toDate();
        
        // 今日以降の予約のみフィルター
        if (date.isBefore(todayStart)) continue;
        
        // 予約情報をマージ
        final Map<String, dynamic> reservationInfo = {
          'id': doc.id,
          'date': date,
          'timeSlotId': timeSlotId,
          'planId': timeSlotData['planId'] as String,
          'startTime': timeSlotData['startTime'] as String,
          'endTime': timeSlotData['endTime'] as String,
          'price': timeSlotData['price'] as int,
          'userId': reservationData['userId'] as String,
          'userName': reservationData['userName'] as String,
          'status': reservationData['status'] as String,
        };
        
        upcomingList.add(reservationInfo);
      }

      // 日付と開始時間でソート
      upcomingList.sort((a, b) {
        final dateCompare = (a['date'] as DateTime).compareTo(b['date'] as DateTime);
        if (dateCompare != 0) return dateCompare;
        return (a['startTime'] as String).compareTo(b['startTime'] as String);
      });

      setState(() {
        _upcomingReservations = upcomingList;
        _isLoading = false;
      });

    } catch (e) {
      print('Error loading upcoming reservations: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('予約データの読み込みに失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final japaneseFormatter = DateFormat('M月d日(E)', 'ja_JP');
    final currencyFormatter = NumberFormat('#,###', 'ja_JP');

    return Scaffold(
      appBar: AppBar(
        // 戻るボタンを表示
        automaticallyImplyLeading: true,
        centerTitle: true,
        title: const Text(
          '予約管理',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          // カレンダー/リスト切替アイコン - サイズを大きくして見やすく
          IconButton(
            icon: Icon(
              _isCalendarView ? Icons.list : Icons.calendar_month,
              color: AppColors.gold,
              size: 28,  // サイズを大きく設定
            ),
            tooltip: _isCalendarView ? 'リスト表示に切替' : 'カレンダー表示に切替',  // ツールチップを追加
            onPressed: () {
              setState(() {
                _isCalendarView = !_isCalendarView;
                print('表示切替: ${_isCalendarView ? "カレンダー表示" : "リスト表示"}'); // デバッグログ
              });
            },
          ),
          // 余白追加
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _isCalendarView
              ? _buildCalendarView()
              : _buildUpcomingReservationsView(japaneseFormatter, currencyFormatter),
      // デバッグ情報（開発中のみ）
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isCalendarView = !_isCalendarView;
            print('FAB表示切替: ${_isCalendarView ? "カレンダー表示" : "リスト表示"}');
          });
        },
        backgroundColor: AppColors.gold,
        child: Icon(_isCalendarView ? Icons.list : Icons.calendar_month),
      ),  // 表示切替用の別のボタン（開発中のみ）
    );
  }

  // カレンダー表示ビルド
  Widget _buildCalendarView() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _loadSelectedDayEvents();
                  });
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                _loadMonthEvents(focusedDay);
              },
              calendarStyle: const CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0xFFDCE9F6),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonDecoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                formatButtonTextStyle: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _reservations.isEmpty
              ? const Center(child: Text('この日の予約はありません'))
              : ListView.builder(
                  itemCount: _reservations.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final reservation = _reservations[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text(
                          '${reservation['startTime']} 〜 ${reservation['endTime']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${reservation['userName']} 様',
                        ),
                        trailing: Text(
                          '¥${reservation['price'].toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
                            (Match m) => '${m[1]},'
                          )}',
                          style: const TextStyle(
                            color: AppColors.gold, 
                            fontWeight: FontWeight.w500
                          ),
                        ),
                        onTap: () {
                          // 予約詳細表示処理
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
    );
  }

  // 直近の予約一覧表示ビルド
  Widget _buildUpcomingReservationsView(DateFormat dateFormatter, NumberFormat currencyFormatter) {
    return _upcomingReservations.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  "今後の予約はありません",
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
                TextButton(
                  onPressed: () => _loadUpcomingReservations(),
                  child: const Text("更新", style: TextStyle(color: AppColors.gold)),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            color: AppColors.gold,
            onRefresh: _loadUpcomingReservations,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _upcomingReservations.length,
              itemBuilder: (context, index) {
                final reservation = _upcomingReservations[index];
                final date = reservation['date'] as DateTime;
                final price = reservation['price'] as int;
                final startTime = reservation['startTime'] as String;
                final endTime = reservation['endTime'] as String;
                final userName = reservation['userName'] as String;
                
                // 日付ヘッダーを表示（前のアイテムと日付が異なる場合）
                final showHeader = index == 0 || 
                    (reservation['date'] as DateTime).day != 
                    (_upcomingReservations[index - 1]['date'] as DateTime).day;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          dateFormatter.format(date),
                          style: const TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(
                          children: [
                            Text(
                              "$startTime ~ $endTime",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              "¥${currencyFormatter.format(price)}",
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          "$userName 様",
                          style: const TextStyle(fontSize: 15),
                        ),
                        onTap: () {
                          // 予約の詳細表示処理（必要に応じて実装）
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final japaneseFormatter = DateFormat('M月d日(E)', 'ja_JP');
    final currencyFormatter = NumberFormat('#,###', 'ja_JP');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
        title: const Text(
          '予約管理',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          // カレンダー/リスト切替アイコン
          IconButton(
            icon: Icon(
              _isCalendarView ? Icons.list : Icons.calendar_month,
              color: AppColors.gold,
            ),
            onPressed: () {
              setState(() {
                _isCalendarView = !_isCalendarView;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _isCalendarView
              ? _buildCalendarView()
              : _buildUpcomingReservationsView(japaneseFormatter, currencyFormatter),
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
    );
  }
}
