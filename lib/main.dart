import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:golf_go/screens/coach/plan_list_screen.dart';
import 'package:golf_go/screens/coach_registration_screen.dart';
import 'package:golf_go/screens/golfer_registration_screen.dart';
import 'package:golf_go/screens/register_screen.dart';
import 'package:golf_go/screens/welcome_screen.dart';
import 'package:golf_go/theme/app_theme.dart';

void main() async {
  // アプリの起動時に画面の向きを縦向きに固定
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // ステータスバーを透明に設定
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  
  // ログイン状態を確認し、適切な初期画面を選択
  User? currentUser = FirebaseAuth.instance.currentUser;
  String initialRoute = '/';
  
  if (currentUser != null) {
    // ユーザーがログイン済みの場合はプラン管理画面を表示
    print('User already logged in: ${currentUser.uid}');
    initialRoute = '/coach/plans';
  } else {
    print('No user logged in');
    // ログインしていない場合はウェルカム画面を表示
    initialRoute = '/';
  }
  
  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Golf Go',
      debugShowCheckedModeBanner: false, // デバッグバナーを非表示
      theme: AppTheme.luxuryTheme, // 高級感のある白ベースのテーマを適用
      initialRoute: initialRoute, // ログイン状態に応じた初期ルート
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/register/coach': (context) => const CoachRegistrationScreen(), // 認定コーチ申請画面
        '/register/golfer': (context) => const GolferRegistrationScreen(), // レッスン受講者登録画面
        '/coach/plans': (context) => const PlanListScreen(),
        '/login': (context) => const RegisterScreen(), // 一時的に登録画面を使用 (後で修正)
      },
    );
  }
}
