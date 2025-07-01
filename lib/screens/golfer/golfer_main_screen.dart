import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';

class GolferMainScreen extends StatefulWidget {
  const GolferMainScreen({super.key});

  @override
  State<GolferMainScreen> createState() => _GolferMainScreenState();
}

class _GolferMainScreenState extends State<GolferMainScreen> {
  int _currentIndex = 0;
  
  // タブ切り替えで表示する画面
  final List<Widget> _screens = [
    const GolferHomeScreen(),
    const GolferReservationsScreen(),
    const GolferProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _currentIndex == 0
              ? 'レッスン予約'
              : _currentIndex == 1
                  ? '予約履歴'
                  : 'プロフィール',
        ),
        actions: [
          // ログアウトボタン（プロフィール画面のみ表示）
          if (_currentIndex == 2)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                // ログアウト処理
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              },
              tooltip: 'ログアウト',
            ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.gold,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.golf_course_outlined),
            activeIcon: Icon(Icons.golf_course),
            label: 'レッスン予約',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: '予約履歴',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'プロフィール',
          ),
        ],
      ),
    );
  }
}

// 簡易的なホーム画面（レッスン予約）
class GolferHomeScreen extends StatelessWidget {
  const GolferHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.golf_course,
            size: 80,
            color: AppColors.gold.withOpacity(0.7),
          ),
          const SizedBox(height: 24),
          const Text(
            'レッスン予約画面',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            '近日公開予定...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// 簡易的な予約履歴画面
class GolferReservationsScreen extends StatelessWidget {
  const GolferReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: AppColors.gold.withOpacity(0.7),
          ),
          const SizedBox(height: 24),
          const Text(
            '予約履歴画面',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            '近日公開予定...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// 簡易的なプロフィール画面
class GolferProfileScreen extends StatelessWidget {
  const GolferProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.gold.withOpacity(0.2),
            child: Icon(
              Icons.person,
              size: 60,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            user?.email ?? 'ゲストユーザー',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }
}
