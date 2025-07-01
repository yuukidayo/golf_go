import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../models/time_slot.dart';

class ReservationCalendarScreen extends StatefulWidget {
  final bool showAppBar; // AppBar表示フラグを追加
  final bool initialCalendarView; // 初期表示モード (カレンダーorリスト)
  final Function(bool)? onViewModeChanged; // 表示モード変更時のコールバック
  
  const ReservationCalendarScreen({
    super.key,
    this.showAppBar = true, // デフォルトではAppBarを表示
    this.initialCalendarView = false, // デフォルトはリスト表示
    this.onViewModeChanged,
  });

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
    _isCalendarView = widget.initialCalendarView; // 親から渡された初期表示モードを使用
    _loadUpcomingReservations(); // リスト表示用の直近予約を読み込む
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

    // アプリバーを表示するかどうかをウィジェットから取得
    final showAppBar = widget.showAppBar;
    
    // カレンダー/リスト切替アイコン
    final switchViewButton = IconButton(
      icon: Icon(
        _isCalendarView ? Icons.list : Icons.calendar_month,
        color: AppColors.gold,
        size: 28,
      ),
      tooltip: _isCalendarView ? 'リスト表示に切替' : 'カレンダー表示に切替',
      onPressed: () {
        setState(() {
          _isCalendarView = !_isCalendarView;
          // 親コンポーネントに表示モードの変更を通知
          widget.onViewModeChanged?.call(_isCalendarView);
        });
      },
    );
    
    return Scaffold(
      // AppBarを条件付きで表示
      appBar: showAppBar ? AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: null,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          switchViewButton,
          const SizedBox(width: 12),
        ],
      ) : null,
      // AppBarを表示しない場合、ビュー切替ボタンをbodyの上部に配置
      floatingActionButtonLocation: showAppBar ? null : FloatingActionButtonLocation.endTop,
      floatingActionButton: showAppBar ? null : Padding(
        padding: const EdgeInsets.only(top: 12, right: 8),
        child: FloatingActionButton(
          elevation: 2,
          backgroundColor: Colors.white,
          mini: true,
          child: Icon(
            _isCalendarView ? Icons.list : Icons.calendar_month,
            color: AppColors.gold,
          ),
          onPressed: () {
            setState(() {
              _isCalendarView = !_isCalendarView;
              // 親コンポーネントに表示モードの変更を通知
              widget.onViewModeChanged?.call(_isCalendarView);
            });
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _isCalendarView
              ? _buildCalendarView()
              : _buildUpcomingReservationsView(japaneseFormatter, currencyFormatter),
    );
  }

  // カレンダー表示ビルド
  Widget _buildCalendarView() {
    return Column(
      children: [
        // カレンダーウィジェットを改善
        Container(
          margin: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 16.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              daysOfWeekHeight: 36,  // 曜日表示の高さを増加
              rowHeight: 48,  // 日付行の高さを増加
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
              calendarStyle: CalendarStyle(
                // 予約マーカーのスタイル
                markersMaxCount: 3,  // 表示するマーカーの最大数
                markerDecoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  // マーカーサイズを調整
                ),
                markerSize: 6.0,  // マーカーサイズを小さく
                markersAnchor: 0.7,  // マーカー位置を調整
                // 今日の日付のスタイル
                todayDecoration: const BoxDecoration(
                  color: Color(0xFFE9F2FF),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                // 選択日のスタイル
                selectedDecoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                // 通常の日のスタイル
                defaultTextStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                // 週末の色を変更
                weekendTextStyle: const TextStyle(
                  color: Color(0xFFE57373),
                  fontWeight: FontWeight.w500,
                ),
                // 範囲外の日付のスタイル
                outsideTextStyle: const TextStyle(
                  color: Color(0x99999999),  // Grey with 60% opacity
                ),
              ),
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: true,
                formatButtonDecoration: BoxDecoration(
                  color: const Color(0x26D4AF37),  // Gold with 15% opacity
                  borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                ),
                formatButtonTextStyle: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
                titleTextStyle: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: AppColors.gold,
                  size: 28,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right,
                  color: AppColors.gold,
                  size: 28,
                ),
              ),
              // 曜日スタイルを改善
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                weekendStyle: TextStyle(
                  color: Color(0xFFE57373),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        // 選択日の表示
        if (_selectedDay != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    DateFormat('yyyy年M月d日(E)', 'ja_JP').format(_selectedDay!),
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'の予約',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        // 予約リスト表示を改善
        Expanded(
          child: _reservations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[350]),
                      const SizedBox(height: 16),
                      Text(
                        'この日の予約はありません',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _reservations.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final reservation = _reservations[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.gold.withOpacity(0.15),
                          child: Icon(Icons.person, color: AppColors.gold),
                        ),
                        title: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${reservation['startTime']} 〜 ${reservation['endTime']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        subtitle: Text(
                          '${reservation['userName']} 様',
                          style: TextStyle(fontSize: 14),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '¥${NumberFormat('#,###', 'ja_JP').format(reservation['price'])}',
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          // 予約詳細表示処理
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('予約詳細表示機能は次のステップで実装します'),
                              backgroundColor: AppColors.gold,
                            ),
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

  // 重複したbuildメソッドを削除（303行目のメソッドとの重複）
}
