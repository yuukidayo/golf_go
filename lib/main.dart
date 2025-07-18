import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:golf_go/firebase_options.dart';
import 'package:golf_go/screens/coach/plan_list_screen.dart';
import 'package:golf_go/screens/coach_registration_screen.dart';
import 'package:golf_go/screens/golfer/golfer_main_screen.dart';
import 'package:golf_go/screens/golfer_registration_screen.dart';
import 'package:golf_go/screens/login_screen.dart';
import 'package:golf_go/screens/register_screen.dart';
import 'package:golf_go/screens/welcome_screen_safe.dart'; // 安全版のウェルカム画面
import 'package:golf_go/services/auth_service.dart';
import 'package:golf_go/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // アプリの起動時に画面の向きを縦向きに固定
  WidgetsFlutterBinding.ensureInitialized();
  
  // 日本語ロケールデータの初期化
  await initializeDateFormatting('ja_JP', null);
  Intl.defaultLocale = 'ja_JP';
  
  // Firebase初期化 - DefaultFirebaseOptionsを使用
  try {
    // Firebase optionsを明示的に指定して初期化
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully with options: ${DefaultFirebaseOptions.currentPlatform.projectId}');
    
    // Firebase Messagingの初期化
    final messaging = FirebaseMessaging.instance;
    
    // 通知権限をリクエスト
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    print('User granted permission: ${settings.authorizationStatus}');
    
    // FCMトークンを取得
    String? token = await messaging.getToken();
    print('FCM Token: $token');
    
    // フォアグラウンドでのメッセージ処理
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
    
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
  
  // ログイン状態とユーザーロールを確認し、適切な初期画面を選択
  String initialRoute = '/';
  
  // AuthServiceのインスタンスを作成
  final authService = AuthService();
  
  // ユーザーがログイン済みの場合
  if (authService.currentUser != null) {
    // ロールに基づいて適切な画面に遷移
    try {
      initialRoute = await authService.getHomeRouteForCurrentUser();
      print('User logged in with role-based route: $initialRoute');
    } catch (e) {
      print('Error determining user role: $e');
      initialRoute = '/';
    }
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
        '/': (context) => const WelcomeScreenSafe(), // 安全版のウェルカム画面を使用
        '/register': (context) => const RegisterScreen(),
        '/register/coach': (context) => const CoachRegistrationScreen(), // 認定コーチ申請画面
        '/register/golfer': (context) => const GolferRegistrationScreen(), // レッスン受講者登録画面
        '/coach/plans': (context) => const PlanListScreen(), // コーチ用メイン画面
        '/golfer/home': (context) => const GolferMainScreen(), // ゴルファー用メイン画面
        '/login': (context) => const LoginScreen(), // ログイン画面
      },
    );
  }
}
