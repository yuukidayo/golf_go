import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:golf_go/services/auth_service.dart';
import 'package:golf_go/theme/app_theme.dart';
import 'package:golf_go/widgets/luxury_button.dart';
import 'package:golf_go/widgets/luxury_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // エラーメッセージをクリア
    setState(() {
      _errorMessage = null;
    });
    
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      // AuthServiceのログインメソッドを呼び出す
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(), 
        _passwordController.text,
      );
      
      // ユーザーのロールに基づいて適切な画面に遷移
      final homeRoute = await _authService.getHomeRouteForCurrentUser();
      
      // コンテキストがまだ有効か確認（非同期処理のため）
      if (!mounted) return;
      
      // ログイン成功メッセージ
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('ログインに成功しました'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // ホーム画面に遷移
      Navigator.pushReplacementNamed(context, homeRoute);
    } catch (e) {
      // ログインエラーを表示
      setState(() {
        _errorMessage = '認証エラー: メールアドレスまたはパスワードが正しくありません';
      });
    } finally {
      // コンテキストがまだ有効か確認
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxuryBackground,
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
                  
                  const SizedBox(height: 16),
                  
                  // ログインタイトル
                  Text(
                    'ログイン',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.luxuryText,
                    ),
                  ).animate().fadeIn(duration: 800.ms),
                  
                  const SizedBox(height: 32),
                  
                  // エラーメッセージ表示
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(duration: 300.ms).shake(),
                  
                  if (_errorMessage != null)
                    const SizedBox(height: 16),
                  
                  // メールアドレスフィールド
                  LuxuryTextField(
                    label: 'メールアドレス',
                    hintText: 'example@golf.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ).animate().fadeIn(duration: 800.ms),
                  
                  const SizedBox(height: 24),
                  
                  // パスワードフィールド
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      LuxuryTextField(
                        label: 'パスワード',
                        hintText: 'パスワードを入力',
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        validator: _validatePassword,
                      ).animate().fadeIn(duration: 800.ms),
                      Positioned(
                        right: 0,
                        bottom: 16,
                        child: IconButton(
                          icon: Icon(
                            _isPasswordVisible 
                              ? Icons.visibility_outlined 
                              : Icons.visibility_off_outlined,
                            color: AppColors.luxuryTextSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // パスワードを忘れた場合のリンク
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // パスワードリセット画面への遷移
                      },
                      child: Text(
                        'パスワードをお忘れの方',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // ログインボタン
                  LuxuryButton(
                    text: 'ログイン',
                    onPressed: _isSubmitting ? () {} : () => _handleLogin(),
                    isLoading: _isSubmitting,
                    isFullWidth: true,
                  ).animate().fadeIn(duration: 800.ms),
                  
                  const SizedBox(height: 24),
                  
                  // 新規登録リンク
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'アカウントをお持ちでない方は',
                        style: TextStyle(
                          color: AppColors.luxuryTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/');
                        },
                        child: Text(
                          '新規登録',
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
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
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
                    text: 'Googleでログイン',
                    onPressed: () {
                      // Googleログイン処理
                    },
                  ),
                  
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
        minimumSize: const Size(double.infinity, 56),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.luxuryText),
          const SizedBox(width: 12),
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
      'assets/images/ゴルフGOロゴ_背景透過.png',
      width: 140,
      height: 140,
    );
  }
}
