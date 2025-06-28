import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/plan.dart';
import '../../models/time_slot.dart';
import '../../theme/app_theme.dart';
import '../../widgets/coach/plan_card.dart';
import 'plan_create_screen.dart';
import 'time_slot_management_screen.dart';

class PlanListScreen extends StatefulWidget {
  const PlanListScreen({super.key});

  @override
  State<PlanListScreen> createState() => _PlanListScreenState();
}

class _PlanListScreenState extends State<PlanListScreen> {
  // タブ管理
  int _currentIndex = 0; // 0: プラン管理, 1: 予約管理
  
  // プラン管理関連
  bool _isLoading = true;
  String? _errorMessage;
  List<Plan> _plans = [];
  User? _currentUser;
  
  // 予約管理関連
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isReservationLoading = false;
  List<TimeSlot> _reservations = [];
  Map<DateTime, List<TimeSlot>> _eventsByDay = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadPlans();
    _selectedDay = _focusedDay;
    _loadMonthEvents(_focusedDay);
  }

  // 現在ログインしているユーザーを取得
  // 登録直後の遷移の場合に対応するためにリトライ処理を追加
  Future<void> _loadCurrentUser() async {
    print('Checking current user authentication state...');
    
    // 最初のチェック
    _currentUser = FirebaseAuth.instance.currentUser;
    
    // 遅延読み込みやFirebase認証状態の同期対応のために少し待つ
    if (_currentUser == null) {
      print('User not found on first check, waiting for auth state to sync');
      // 認証状態が同期されるまで少し待つ
      await Future.delayed(const Duration(milliseconds: 500));
      _currentUser = FirebaseAuth.instance.currentUser;
      print('After delay, currentUser: ${_currentUser?.uid}');
    }
    
    // UI更新
    setState(() {});
    
    // ユーザーがまだログインしていない場合のみウェルカム画面に戻る
    if (_currentUser == null) {
      print('User still not logged in after retry, redirecting to welcome screen');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ログインが必要です'), 
          backgroundColor: Colors.red,
        ),
      );
      
      // 少し待ってから遷移する
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && FirebaseAuth.instance.currentUser == null) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      });
    } else {
      print('User authenticated: ${_currentUser?.uid}');
      // ユーザーが認証済みであることを確認した後でプランを読み込む
      _loadPlans();
    }
  }

  // ログイン中のコーチのプラン一覧を読み込む
  Future<void> _loadPlans() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ログインユーザーが見つかりません';
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('plans')
          .where('coachId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final plans = snapshot.docs.map((doc) => Plan.fromFirestore(doc)).toList();
      
      setState(() {
        _plans = plans;
        _isLoading = false;
      });

      // 初期データがない場合はモックデータを表示（開発用）
      if (_plans.isEmpty && userId == 'mock_coach_id') {
        setState(() {
          _plans = Plan.getMockPlans();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'データの読み込みに失敗しました: $e';
      });
    }
  }

  // プラン新規作成画面に遷移
  Future<void> _navigateToCreatePlan() async {
    // 画面遷移し、戻ってきたら再読み込みを行う
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlanCreateScreen()),
    );
    
    // 画面から戻ってきたらプラン一覧を再読み込み
    if (result == true) {
      _loadPlans();
    }
  }

  // プランの操作オプションを表示
  Future<void> _navigateToPlanEdit(Plan plan) async {
    showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.gold),
                title: const Text('プラン情報を編集'),
                onTap: () {
                  Navigator.pop(context, 'edit');
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month, color: AppColors.gold),
                title: const Text('予約枠を管理'),
                onTap: () {
                  Navigator.pop(context, 'time_slots');
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.grey),
                title: const Text('キャンセル'),
                onTap: () {
                  Navigator.pop(context, 'cancel');
                },
              ),
            ],
          ),
        );
      },
    ).then((value) async {
      if (value == 'edit') {
        // プラン編集画面へ遷移
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlanCreateScreen(plan: plan)),
        );
        
        // 画面から戻ってきたらプラン一覧を再読み込み
        if (result == true) {
          _loadPlans();
        }
      } else if (value == 'time_slots') {
        // 予約枠管理画面へ遷移
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TimeSlotManagementScreen(plan: plan)),
        );
        
        // 画面から戻ってきたらプラン一覧を再読み込み
        if (result == true) {
          _loadPlans();
        }
      }
    });
  }

  List<TimeSlot> _getEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _eventsByDay[normalizedDate] ?? [];
  }

  Future<void> _loadMonthEvents(DateTime month) async {
    setState(() {
      _isReservationLoading = true;
    });
    
    try {
      // TODO: Firestoreから月全体の予約データを取得する実装
      // この部分は次のステップで実装
      
      // 仮データを設定（開発中のみ）
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 仮データでいくつかの日に予約を設定
      final Map<DateTime, List<TimeSlot>> mockEvents = {};
      
      // 複数の日に予約を追加（開発用サンプル）
      final DateTime lastDay = DateTime(month.year, month.month + 1, 0);
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
        _loadSelectedDayEvents();
      });
      
    } catch (e) {
      debugPrint('月間予約データ読み込みエラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('予約データの読み込みに失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isReservationLoading = false;
      });
    }
  }

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
      onWillPop: () async => false, // 戻るボタンを無効化
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _currentIndex == 0 
            ? _buildPlanManagement() // プラン管理画面
            : _buildReservationCalendar(), // 予約管理画面
        ),
        floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
          backgroundColor: AppColors.gold,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: _navigateToCreatePlan,
          tooltip: '新しいプランを作成',
        ) : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              // マイページ（準備中）
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('マイページは準備中です')),
              );
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
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
  
  // プラン管理画面のビルド
  Widget _buildPlanManagement() {
    return RefreshIndicator(
      onRefresh: _loadPlans,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,  // これが重要：戻るボタンを非表示にします
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              background: Container(
                color: Colors.white,
                child: const Center(
                  child: Image(
                    image: AssetImage('assets/images/logo.png'),
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            actions: [
              SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                'プラン一覧',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.luxuryText,
                ),
              ),
            ),
          ),
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadPlans,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                      ),
                      child: Text('再読み込み'),
                    ),
                  ],
                ),
              ),
            )
          else if (_plans.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.golf_course, size: 48, color: Colors.grey.shade300),
                    SizedBox(height: 16),
                    Text(
                      'まだプランがありません',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    SizedBox(height: 8),
                    Text('新しいプランを作成しましょう'),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _navigateToCreatePlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      icon: Icon(Icons.add),
                      label: Text('プランを作成'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.only(bottom: 80), // Bottom navigationのため
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final plan = _plans[index];
                    return PlanCard(
                      key: ValueKey(plan.id),
                      plan: plan,
                      onTap: () => _navigateToPlanEdit(plan),
                    );
                  },
                  childCount: _plans.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 予約管理画面のビルド
  Widget _buildReservationCalendar() {
    return Column(
      children: [
        // カレンダー部分
        Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar<TimeSlot>(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _loadSelectedDayEvents();
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                _loadMonthEvents(focusedDay);
              },
              calendarStyle: const CalendarStyle(
                markersMaxCount: 3,
                markersAlignment: Alignment.bottomCenter,
                markerDecoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0xFFDEB887), // 薄い金色
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: AppColors.gold),
                ),
                formatButtonTextStyle: const TextStyle(color: AppColors.gold),
                titleTextStyle: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold
                ),
                headerPadding: const EdgeInsets.symmetric(vertical: 4.0),
                leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.gold),
                rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.gold),
                headerMargin: const EdgeInsets.only(bottom: 8.0),
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
            '${DateFormat('yyyy年MM月dd日').format(_selectedDay ?? _focusedDay)} の予約',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 予約一覧
        Expanded(
          child: _isReservationLoading 
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
}
