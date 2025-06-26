import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class LuxuryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool isFullWidth;
  final bool isLoading;

  const LuxuryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.isFullWidth = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 56, // ボタンの高さを高級感のあるサイズに調整
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : AppColors.gold,
          foregroundColor: isOutlined ? AppColors.gold : Colors.white, // テキスト色を白に変更
          elevation: isOutlined ? 0 : 0.5, // わずかな影を追加
          shadowColor: isOutlined ? Colors.transparent : Colors.black.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isOutlined
              ? const BorderSide(color: AppColors.gold, width: 1.5) // 太めのボーダー
              : BorderSide.none,
          ),
        ),
        child: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOutlined ? AppColors.gold : Colors.white,
                ),
                strokeWidth: 2,
              ),
            )
          : Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600, // セミボールドに調整
                letterSpacing: 0.5, // 文字間隔を微調整して高級感を出す
                color: isOutlined ? AppColors.gold : Colors.white, // テキスト色を白に変更
              ),
            ),
      ).animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 250.ms, curve: Curves.easeOutQuad),
    );
  }
}
