import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/plan.dart';
import '../../theme/app_theme.dart';
import '../../utils/test_data_helper.dart';
import '../../widgets/coach/plan_card.dart';
import 'plan_create_screen.dart';
import 'time_slot_management_screen.dart';
import 'reservation_calendar_screen.dart';

class PlanListScreen extends StatefulWidget {
  const PlanListScreen({super.key});

  @override
  State<PlanListScreen> createState() => _PlanListScreenState();
}

class _PlanListScreenState extends State<PlanListScreen> with SingleTickerProviderStateMixin {
  // プラン管理関連の状態管理
  bool _isLoading = true;
  String? _errorMessage;
  List<Plan> _plans = [];
  User? _currentUser;
  
  // カレンダー/リスト表示モード切替用の変数
  bool _isCalendarView = false;
  
  // アニメーション用コントローラー
  late AnimationController _animationController;
  
  // ナビゲーション関連
  int _currentIndex = 0;
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    
    // アニメーションコントローラーの初期化
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    
    _screens = [
      Container(), // プラン管理画面は現在の画面なので空のコンテナ
      _buildReservationCalendarScreen(), // 予約管理画面をビルダー関数で生成
    ];
    _loadCurrentUser();
    _loadPlans();
  }
  
  @override
  void dispose() {
    _animationController.dispose(); // アニメーションコントローラーを破棄
    super.dispose();
  }
  
  // 予約管理画面を構築するメソッド
  Widget _buildReservationCalendarScreen() {
    // 予約カレンダー画面を埋め込む際にAppBarを非表示に設定し、表示モードを親から渡す
    return ReservationCalendarScreen(
      showAppBar: false,
      initialCalendarView: _isCalendarView,
      onViewModeChanged: (isCalendarView) {
        setState(() {
          _isCalendarView = isCalendarView;
        });
      },
    );
  }

  // 現在ログインしているユーザーを取得
  Future<void> _loadCurrentUser() async {
    print('Checking current user authentication state...');
    
    _currentUser = FirebaseAuth.instance.currentUser;
    
    // 遅延読み込み対応のため少し待つ
    if (_currentUser == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      _currentUser = FirebaseAuth.instance.currentUser;
    }
    
    setState(() {});
    
    // ユーザーがログインしていない場合
    if (_currentUser == null) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ログインが必要です'), 
          backgroundColor: Colors.red,
        ),
      );
      
      // ウェルカム画面に戻る
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && FirebaseAuth.instance.currentUser == null) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      });
    } else {
      // ユーザーが認証済みならプランを読み込む
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlanCreateScreen()),
    );
    
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
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('プランを削除'),
                onTap: () {
                  Navigator.pop(context, 'delete');
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
        
        if (result == true) {
          _loadPlans();
        }
      } else if (value == 'time_slots') {
        // 予約枠管理画面へ遷移
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TimeSlotManagementScreen(plan: plan)),
        );
        
        if (result == true) {
          _loadPlans();
        }
      } else if (value == 'delete') {
        // プラン削除の確認ダイアログを表示
        _showDeleteConfirmationDialog(plan);
      }
    });
  }
  
  // プラン削除の確認ダイアログ
  Future<void> _showDeleteConfirmationDialog(Plan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プラン削除の確認'),
        content: Text('「${plan.title}」を削除してもよろしいですか？\n\n※予約枠や予約データも全て削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除する'),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed && mounted) {
      await _deletePlan(plan);
    }
  }
  
  // プラン削除処理
  Future<void> _deletePlan(Plan plan) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // プランを論理削除（isActive = false）に更新
      await FirebaseFirestore.instance
          .collection('plans')
          .doc(plan.id)
          .update({'isActive': false});
      
      // 一覧を再読み込み
      _loadPlans();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('プランを削除しました'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('プラン削除に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // テスト用の予約データを作成するメソッド
  Future<void> _createTestReservations() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Firebase初期化を確認
      final isInitialized = await TestDataHelper.ensureFirebaseInitialized();
      if (!isInitialized) {
        throw Exception('Firebase初期化に失敗しました');
      }
      
      // テストデータを作成
      final createdIds = await TestDataHelper.createTestReservations();

      // 成功メッセージを表示
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${createdIds.length}件のテスト予約を作成しました'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // エラーメッセージを表示
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('テスト予約の作成に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // 読み込み状態を元に戻す
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 戻るボタンを非表示
        title: Text(_currentIndex == 0 ? 'プラン管理' : '予約管理'),
        actions: [
          // テスト予約作成ボタン（開発用）
          if (kDebugMode && _currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _createTestReservations,
              tooltip: 'テスト予約を作成',
            ),
          // 右側に余白を追加
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: _navigateToCreatePlan,
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add),
      ) : null,
      body: _currentIndex == 0 ? _buildPlanManagement() : _screens[_currentIndex],
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
    );
  }

  // プラン管理画面を構築
  Widget _buildPlanManagement() {
    return CustomScrollView(
      slivers: <Widget>[
        // エラー表示
        if (_errorMessage != null)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
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
        // ローディング表示
        else if (_isLoading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          )
        // プランがない場合
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
        // プラン一覧
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
    );
  }
}