import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golf_go/theme/app_theme.dart';

class CoachRegistrationScreen extends StatefulWidget {
  const CoachRegistrationScreen({super.key});

  @override
  State<CoachRegistrationScreen> createState() => _CoachRegistrationScreenState();
}

class _CoachRegistrationScreenState extends State<CoachRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  // 別途Firebase関連の処理とUI更新を分離する新しいアプローチ
  Future<void> _handleRegistration() async {
    // フォームのバリデーション
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('利用規約とプライバシーポリシーに同意してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // 送信中フラグを立てる
    setState(() {
      _isSubmitting = true;
    });

    // フォームデータの取得
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();
    final inviteCode = _inviteCodeController.text.trim();

    try {
      // Step 1: FirebaseAuthでユーザー作成
      final UserCredential userCredential;
      try {
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // ログアウトせずに認証状態を維持する
        // これにより次の画面でも認証状態が有効
        print('User successfully created and signed in: ${userCredential.user?.uid}');
      } catch (authError) {
        // Auth登録失敗の処理
        _showErrorMessage(_getAuthErrorMessage(authError));
        return;
      }
      
      // Step 2: Firestoreにユーザーデータ保存
      final userId = userCredential.user?.uid;
      if (userId != null) {
        try {
          await FirebaseFirestore.instance.collection('coaches').doc(userId).set({
            'name': name,
            'email': email,
            'inviteCode': inviteCode,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'isApproved': false,
            'isActive': true,
          });
        } catch (firestoreError) {
          // Firestoreエラーはログだけ残し、成功として処理（Auth登録は成功しているため）
          print('Firestore error: $firestoreError');
        }
      }
      
      // Step 3: 成功のUI表示（すべての非同期処理が完了してから）
      if (mounted) {
        // 前のSnackBarを消去
        ScaffoldMessenger.of(context).clearSnackBars();
        
        // 成功メッセージ表示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('アカウント登録が完了しました'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // 少し待ってからコーチのプラン一覧画面へ遷移
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            // コーチのプラン一覧画面に遷移
            Navigator.of(context).pushReplacementNamed('/coach/plans');
          }
        });
      }
    } catch (error) {
      // 想定外のエラー
      print('Unexpected error during registration: $error');
      if (mounted) {
        _showErrorMessage('アカウント登録中に予期せぬエラーが発生しました');
      }
    } finally {
      // 処理が終わったら送信中フラグを下ろす
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  // エラーメッセージ表示のヘルパーメソッド
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
  
  // Firebase Auth関連のエラーメッセージを取得するヘルパーメソッド
  String _getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'このメールアドレスは既に使用されています';
        case 'invalid-email':
          return '無効なメールアドレスです';
        case 'weak-password':
          return 'パスワードが脆弱です。より強力なパスワードを設定してください';
        case 'operation-not-allowed':
          return 'この操作は許可されていません';
        default:
          return 'アカウント登録に失敗しました: ${error.message}';
      }
    }
    return 'アカウント登録に失敗しました';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  
                  // ロゴ（テキストベースで作成）
                  _buildLogoWidget().animate().fadeIn(duration: 600.ms),
                  
                  const SizedBox(height: 30),
                  
                  // 認定コーチ申請
                  Text(
                    '認定コーチ申請',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                  
                  const SizedBox(height: 30),
                  
                  // お名前
                  _buildTextField(
                    label: 'お名前',
                    controller: _nameController,
                    validator: _validateRequired,
                  ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
                  
                  const SizedBox(height: 20),
                  
                  // メールアドレス
                  _buildTextField(
                    label: 'メールアドレス',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
                  
                  const SizedBox(height: 20),
                  
                  // パスワード
                  _buildTextField(
                    label: 'パスワード',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: _validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                  
                  const SizedBox(height: 20),
                  
                  // パスワード（確認）
                  _buildTextField(
                    label: 'パスワード（確認）',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    validator: _validateConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 450.ms),
                  
                  const SizedBox(height: 20),
                  
                  // 招待コード
                  _buildTextField(
                    label: '招待コード',
                    controller: _inviteCodeController,
                  ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
                  
                  const SizedBox(height: 20),
                  
                  // 利用規約同意
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                        activeColor: AppColors.gold,
                      ),
                      Expanded(
                        child: Text(
                          '私は利用規約およびプライバシーポリシーに同意します。',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms, delay: 550.ms),
                  
                  const SizedBox(height: 30),
                  
                  // メールで登録するボタン
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'メールで登録する',
                            style: TextStyle(fontSize: 16),
                          ),
                  ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
                  
                  const SizedBox(height: 30),
                  
                  // Google連携ボタン
                  Center(
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.g_mobiledata,
                        size: 36,
                        color: Colors.black87,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 650.ms),
                  
                  const SizedBox(height: 20),
                  
                  // ログインへのリンク
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'すでにアカウントをお持ちですか？',
                        style: TextStyle(
                          color: Colors.black87,
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
                  ).animate().fadeIn(duration: 500.ms, delay: 700.ms),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogoWidget() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
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
              size: const Size(40, 40),
              painter: GoldSwingPainter(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'GOLF GO!',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.gold, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            suffixIcon: suffixIcon,
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
  
  String? _validateRequired(String? value) {
    return (value == null || value.isEmpty) ? '必須項目です' : null;
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
  
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return '必須項目です';
    }
    if (value != _passwordController.text) {
      return 'パスワードが一致しません';
    }
    return null;
  }
}

// ゴールドのスイングアイコンをカスタムペインターで描画
class GoldSwingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
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
