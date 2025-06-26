import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:golf_go/widgets/luxury_button.dart';
import 'package:golf_go/widgets/luxury_text_field.dart';
import 'package:golf_go/widgets/user_type_segment.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenseController = TextEditingController();
  final _bioController = TextEditingController();
  final _golfExperienceController = TextEditingController();
  final _goalController = TextEditingController();
  
  int _selectedUserType = UserType.proCoach;
  bool _isSubmitting = false; // _isLoading から _isSubmitting に変更

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
    _bioController.dispose();
    _golfExperienceController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (_formKey.currentState?.validate() != true) {
      // バリデーションエラーがある場合は処理を中断
      return;
    }
    
    // スナックバー表示前にcontextを保存しておく
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    setState(() {
      _isSubmitting = true;
    });

    // 登録処理のシミュレーション
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSubmitting = false;
    });

    // 登録完了メッセージを表示
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('アカウント登録が完了しました'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    // 登録完了後、ユーザータイプに基づいて適切な画面に遷移
    if (_selectedUserType == UserType.proCoach) {
      // コーチの場合はプラン一覧画面に遷移
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, '/coach/plans');
      });
    } else {
      // ゴルファーの場合は別の画面に遷移する予定（現在は未実装）
      // TODO: プレミアムゴルファー向け画面への遷移を追加
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '必須項目です';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return '有効なメールアドレスを入力してください';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '必須項目です';
    }
    if (value.length < 8) {
      return '8文字以上の英数字を入力してください';
    }
    return null;
  }

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return '必須項目です';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxuryBackground, // 純白の背景に変更
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ロゴ
                  _buildLogo().animate().fadeIn(duration: 800.ms),
                  
                  const SizedBox(height: 24),
                  
                  // ようこそテキスト
                  Text(
                    'ゴルフの世界へようこそ',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 40), // 余白を増やす
                  
                  // アカウントタイプ選択
                  Text(
                    'アカウントタイプを選択',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.luxuryTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ユーザータイプセグメント - 高級感のあるスタイルに
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.luxuryShadow,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: UserTypeSegment(
                      selectedIndex: _selectedUserType,
                      onSelectionChanged: (index) {
                        setState(() => _selectedUserType = index);
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 共通フィールド
                  LuxuryTextField(
                    label: '氏名',
                    required: true,
                    controller: _nameController,
                    validator: _validateRequired,
                  ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
                  
                  const SizedBox(height: 24),
                  
                  LuxuryTextField(
                    label: 'メールアドレス',
                    required: true,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                  
                  const SizedBox(height: 24),
                  
                  LuxuryTextField(
                    label: 'パスワード',
                    required: true,
                    controller: _passwordController,
                    obscureText: true,
                    hintText: '8文字以上の英数字',
                    validator: _validatePassword,
                  ).animate().fadeIn(duration: 300.ms, delay: 300.ms),
                  
                  const SizedBox(height: 24),
                  
                  // ユーザータイプに応じたフィールド
                  ..._buildUserTypeFields(),
                  
                  const SizedBox(height: 32),
                  
                  // 登録ボタン
                  LuxuryButton(
                    text: '登録する',
                    onPressed: _handleRegistration,
                    isLoading: _isSubmitting,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ログインリンク
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'すでにアカウントをお持ちの方は',
                        style: TextStyle(
                          color: AppColors.luxuryTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'ログイン',
                          style: TextStyle(
                            color: AppColors.luxuryText,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // または区切り
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0), // 余白を増やす
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppColors.luxuryDivider,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'または',
                            style: TextStyle(
                              color: AppColors.luxuryTextSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppColors.luxuryDivider,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // ソーシャルログイン
                  _buildSocialLoginButton(
                    icon: Icons.g_mobiledata,
                    text: 'Googleで続ける',
                    onPressed: () {},
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSocialLoginButton(
                    icon: Icons.apple,
                    text: 'Appleで続ける',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildUserTypeFields() {
    if (_selectedUserType == UserType.proCoach) {
      return [
        LuxuryTextField(
          label: '所属団体・ライセンス番号',
          hintText: 'PGA公認プロ #12345',
          controller: _licenseController,
        ).animate().fadeIn(duration: 300.ms),
        
        const SizedBox(height: 24),
        
        LuxuryTextField(
          label: 'あなたの経歴や指導スタイルについて',
          controller: _bioController,
          maxLines: 3,
        ).animate().fadeIn(duration: 300.ms),
      ];
    } else {
      return [
        LuxuryTextField(
          label: 'ゴルフ歴（年数）',
          controller: _golfExperienceController,
          keyboardType: TextInputType.number,
        ).animate().fadeIn(duration: 300.ms),
        
        const SizedBox(height: 24),
        
        LuxuryTextField(
          label: '目標',
          controller: _goalController,
        ).animate().fadeIn(duration: 300.ms),
      ];
    }
  }

  Widget _buildSocialLoginButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.luxuryText,
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: AppColors.luxuryDivider, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(double.infinity, 56), // 高さを少し大きく
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.luxuryText),
          const SizedBox(width: 12), // 余白を増やす
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.luxuryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo.png',
      width: 140,
      height: 140,
    );
  }
}
