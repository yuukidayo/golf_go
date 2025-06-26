import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:golf_go/theme/app_theme.dart';
import 'package:golf_go/widgets/luxury_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
              // ロゴ（テキストベースで作成）
              _buildLogoWidget().animate().fadeIn(duration: 600.ms),
              
              const SizedBox(height: 40),
              
              // ゴルフの世界へようこそ
              Text(
                'ゴルフの世界へようこそ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
              
              const SizedBox(height: 24),
              
              // アカウントタイプを選択
              Text(
                'アカウントタイプを選択',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
              
              const SizedBox(height: 32),
              
              // コーチの方はこちら
              _buildOptionCard(
                context: context,
                title: 'コーチの方はこちら',
                onTap: () => Navigator.pushNamed(context, '/register/coach'),
                delay: 400,
              ),
              
              const SizedBox(height: 16),
              
              // レッスンを受けたい方はこちら
              _buildOptionCard(
                context: context,
                title: 'レッスンを受けたい方はこちら',
                onTap: () => Navigator.pushNamed(context, '/register/golfer'),
                delay: 500,
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
              ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
              
              const Spacer(),
              
              // または区切り
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'または',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Googleでサインイン
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.g_mobiledata,
                      size: 28,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Googleで続ける',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 700.ms),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogoWidget() {
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
          child: Center(
            child: CustomPaint(
              size: const Size(60, 60),
              painter: GoldSwingPainter(),
            ),
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
  
  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
    required int delay,
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
    ).animate().fadeIn(duration: 500.ms, delay: delay.ms);
  }
}

// ゴールドのスイングアイコンをカスタムペインターで描画
class GoldSwingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    
    // 円弧を描く（ゴルフスイングのイメージ）
    path.moveTo(size.width * 0.3, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.5, size.height * 0.1,
      size.width * 0.7, size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.9, size.height * 0.5,
      size.width * 0.7, size.height * 0.7,
    );
    
    // ゴルフクラブのシャフト
    path.moveTo(size.width * 0.3, size.height * 0.3);
    path.lineTo(size.width * 0.2, size.height * 0.7);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
