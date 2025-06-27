import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/plan.dart';
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
  int _currentIndex = 1; // レッスンタブを初期選択
  bool _isLoading = true;
  String? _errorMessage;
  List<Plan> _plans = [];
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    // プランのロードは_getCurrentUserの中で行うように変更
  }

  // 現在ログインしているユーザーを取得
  // 登録直後の遷移の場合に対応するためにリトライ処理を追加
  Future<void> _getCurrentUser() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPlans,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.white,
                expandedHeight: 100,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'コーチプラン一覧',
                    style: TextStyle(
                      color: AppColors.luxuryText, 
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  background: Container(color: Colors.white),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.gold),
                    onPressed: _navigateToCreatePlan,
                    tooltip: '新しいプランを作成',
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              if (_isLoading)
                const SliverFillRemaining(
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
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadPlans,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                          ),
                          child: const Text('再読み込み'),
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
                        const SizedBox(height: 16),
                        Text(
                          'まだプランがありません',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        const Text('新しいプランを作成しましょう'),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _navigateToCreatePlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('プランを作成'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 80), // Bottom navigationのため
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _navigateToCreatePlan,
        tooltip: '新しいプランを作成',
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // TODO: タブに応じた画面遷移を実装
        },
        selectedItemColor: AppColors.gold,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'レッスン',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'コーチ',
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
