# Golf GO アプリケーション - ルート構造とナビゲーションフロー

## ルート定義コード (main.dart)

```dart
// MyApp ウィジェットのルート定義
MaterialApp(
  title: 'Golf Go',
  debugShowCheckedModeBanner: false, // デバッグバナーを非表示
  theme: AppTheme.luxuryTheme, // 高級感のある白ベースのテーマを適用
  initialRoute: initialRoute, // ログイン状態に応じた初期ルート
  routes: {
    '/': (context) => const WelcomeScreen(),
    '/register': (context) => const RegisterScreen(),
    '/register/coach': (context) => const CoachRegistrationScreen(), // 認定コーチ申請画面
    '/register/golfer': (context) => const GolferRegistrationScreen(), // レッスン受講者登録画面
    '/coach/plans': (context) => const PlanListScreen(), // コーチ用メイン画面
    '/golfer/home': (context) => const GolferMainScreen(), // ゴルファー用メイン画面
    '/login': (context) => const LoginScreen(), // ログイン画面
  },
)
```

## 初期ルート決定ロジック (main.dart)

```dart
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
```

## 画面パス一覧

### 認証関連

| ルート | 画面クラス | 説明 |
| --- | --- | --- |
| `/` | `WelcomeScreen` | ウェルカム画面（アプリ初期画面） |
| `/login` | `LoginScreen` | ログイン画面 |
| `/register` | `RegisterScreen` | 登録タイプ選択画面 |
| `/register/coach` | `CoachRegistrationScreen` | コーチ登録画面 |
| `/register/golfer` | `GolferRegistrationScreen` | ゴルファー登録画面 |

### コーチ用画面

| ルート | 画面クラス | 説明 |
| --- | --- | --- |
| `/coach/plans` | `PlanListScreen` | コーチ用メイン画面・プラン管理 |

### ゴルファー用画面

| ルート | 画面クラス | 説明 |
| --- | --- | --- |
| `/golfer/home` | `GolferMainScreen` | ゴルファー用メイン画面 |

## ナビゲーションフロー

### ログイン・登録フロー

1. アプリ起動時は `WelcomeScreen` (`/`) から開始
2. ログインボタンを押すと `LoginScreen` (`/login`) に遷移
3. 新規登録ボタンを押すとユーザータイプに応じて：
   - コーチの場合: `CoachRegistrationScreen` (`/register/coach`)
   - ゴルファーの場合: `GolferRegistrationScreen` (`/register/golfer`)

### 認証後のフロー

- ログイン成功後、ユーザーロールに基づいて自動的に適切なホーム画面に遷移
  - コーチの場合: `PlanListScreen` (`/coach/plans`)
  - ゴルファーの場合: `GolferMainScreen` (`/golfer/home`)

### ユーザーロール判定ロジック

Firestoreのコレクション構造に基づいてユーザーロールを判定:

```dart
// AuthService.getUserRole() メソッドでの判定ロジック
Future<UserRole> getUserRole() async {
  final user = currentUser;
  
  if (user == null) {
    return UserRole.unknown;
  }
  
  try {
    // コーチとして登録されているか確認
    final coachDoc = await _firestore.collection('coaches').doc(user.uid).get();
    if (coachDoc.exists) {
      return UserRole.coach;
    }
    
    // ゴルファーとして登録されているか確認
    final golferDoc = await _firestore.collection('golfers').doc(user.uid).get();
    if (golferDoc.exists) {
      return UserRole.golfer;
    }
    
    // どちらにも登録されていない場合
    return UserRole.unknown;
  } catch (e) {
    print('Error getting user role: $e');
    return UserRole.unknown;
  }
}
```
