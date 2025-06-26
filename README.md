# Golf Go

![Golf Go Logo](./assets/images/logo.png)

ゴルフ上達を目指す富裕層ユーザー（プレミアムゴルファー）と、ゴルフ指導を行うプロユーザー（プロコーチ）をマッチングするラグジュアリーなアプリケーション。

## 環境設定

### バージョン情報
- Flutter SDK: 3.8.1（固定バージョン）
- Dart: 3.8.1（固定バージョン）
- iOS: 最低 iOS 12.0 以上
- Android: minSdkVersion 21 (Android 5.0) 以上

### 使用プラグイン
| パッケージ名 | バージョン | 用途 |
|------------|----------|------|
| flutter_animate | 4.4.0 | アニメーション効果 |
| google_sign_in | 6.1.6 | Googleログイン |
| sign_in_with_apple | 5.0.0 | Appleログイン |
| provider | 6.1.1 | 状態管理 |
| flutter_lints | 5.0.0 | コード品質 |

### パッケージのインストール
```bash
flutter pub get
```

### ビルド方法

#### iOS
```bash
flutter build ios --no-codesign
```

#### Android
```bash
flutter build apk
```

## プロジェクト構造

```
lib/
├── constants/         # 定数定義
│   └── app_assets.dart  # ロゴなどの定義
├── screens/           # 画面
│   └── register_screen.dart  # アカウント登録画面
├── theme/             # テーマ定義
│   └── app_theme.dart  # 高級感のある白ベース・ゴールドアクセントのテーマ
├── widgets/           # 再利用可能なウィジェット
│   ├── luxury_button.dart    # 高級感のあるボタン
│   ├── luxury_text_field.dart  # 高級感のあるテキストフィールド
│   └── user_type_segment.dart  # ユーザータイプ選択セグメント
└── main.dart          # アプリのエントリーポイント

docs/
└── spec.md           # 設計仕様書
```

## 画面構成

### アカウント登録画面
**ファイル**: `lib/screens/register_screen.dart`

**機能**:
- ユーザータイプ選択（プロコーチ/プレミアムゴルファー）
- ユーザー情報入力フォーム（氏名、メールアドレス、パスワード）
- ユーザータイプに応じた追加情報入力
  - プロコーチ: ライセンス番号、経歴/指導スタイル
  - プレミアムゴルファー: ゴルフ歴、目標
- Google/Appleログインオプション

**デザイン特徴**:
- 純白の背景（#FFFFFF）をベースとした高級感のあるUI
- ゴールドカラー（#D4AF37, #FFD700）のアクセント
- 十分な余白とエレガントなタイポグラフィ
- スムーズなアニメーションと遷移効果
- 洗練されたフォーム要素と影効果

## カスタムウィジェット

### LuxuryButton
**ファイル**: `lib/widgets/luxury_button.dart`

高級感のあるボタンコンポーネント。通常版と枠線のみ（アウトライン）版の2種類を提供。

### LuxuryTextField
**ファイル**: `lib/widgets/luxury_text_field.dart`

高級感のあるテキストフィールド。下線スタイルでフォーカス時にゴールドカラーになる効果を実装。

### UserTypeSegment
**ファイル**: `lib/widgets/user_type_segment.dart`

プロコーチとプレミアムゴルファーを選択するためのセグメントコントロール。選択時にアニメーション効果を適用。

## テーマ設定

**ファイル**: `lib/theme/app_theme.dart`

### 配色
- 基調：ホワイト（#FFFFFF）- 背景・ベースUI
- 補助：ダークグレー（#212121）- メインテキスト
- 二次補助：ミディアムグレー（#757575）- 二次テキスト、ラベル
- アクセント：ゴールド（#D4AF37, #FFD700）- ボタン、ポイント、セグメント
- 区切り：ライトグレー（#EEEEEE）- 区切り線、ボーダー

### フォントスタイル
- サンセリフ系フォント
- 適切な余白と行間で高級感を演出

## 設計仕様

詳細な設計仕様は `docs/spec.md` に記載されています。
