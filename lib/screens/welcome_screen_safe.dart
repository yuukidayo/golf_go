import 'package:flutter/material.dart';
import 'package:golf_go/theme/app_theme.dart';

/// 安全な表示のためにアニメーションを無効化したシンプルなウェルカム画面
class WelcomeScreenSafe extends StatelessWidget {
  const WelcomeScreenSafe({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // シンプルなロゴ表示
              _buildSimpleLogo(),
              
              const SizedBox(height: 24),
              
              // ゴルフの世界へようこそ
              Text(
                'ゴルフの世界へようこそ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // アカウントタイプを選択
              Text(
                'アカウントタイプを選択',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // コーチの方はこちら
              _buildSimpleOptionCard(
                context: context,
                title: 'コーチの方はこちら',
                onTap: () => Navigator.pushNamed(context, '/register/coach'),
              ),
              
              const SizedBox(height: 16),
              
              // レッスンを受けたい方はこちら
              _buildSimpleOptionCard(
                context: context,
                title: 'レッスンを受けたい方はこちら',
                onTap: () => Navigator.pushNamed(context, '/register/golfer'),
              ),
              
              const SizedBox(height: 24),
              
              // すでにアカウントをお持ちの方はログイン
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'すでにアカウントをお持ちの方は',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: Text(
                      'ログイン',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSimpleLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: AppColors.gold,
              width: 2,
            ),
          ),
          child: const Center(
            child: Icon(Icons.sports_golf, color: AppColors.gold, size: 40),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'GOLF GO!',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSimpleOptionCard({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
