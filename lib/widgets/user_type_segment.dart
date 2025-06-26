import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ユーザータイプの定数
class UserType {
  static const int proCoach = 0;
  static const int premiumGolfer = 1;
}

class UserTypeSegment extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelectionChanged;

  const UserTypeSegment({
    super.key,
    required this.selectedIndex,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.luxuryDivider, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 40, // プロコーチの幅
            child: _buildSegmentButton(
              context: context,
              title: "プロコーチ",
              isSelected: selectedIndex == UserType.proCoach,
              onTap: () => onSelectionChanged(UserType.proCoach),
            ),
          ),
          Expanded(
            flex: 60, // プレミアムゴルファーの幅（より広く）
            child: _buildSegmentButton(
              context: context,
              title: "プレミアムゴルファー",
              isSelected: selectedIndex == UserType.premiumGolfer,
              onTap: () => onSelectionChanged(UserType.premiumGolfer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.gold.withAlpha(50),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFD4AF37), // より鮮やかなゴールド
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, // 選択されていない時も少し太く
            fontSize: 13, // フォントサイズを少し小さくしてフィット
            letterSpacing: 0.1, // 文字間隔を狭く
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis, // 必要な場合は省略
        ),
      ).animate(target: isSelected ? 1 : 0)
        .fadeIn(duration: 200.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0)),
    );
  }
}
