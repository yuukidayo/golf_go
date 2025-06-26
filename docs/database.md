# Golf Go! データベース構造設計書

このドキュメントは Golf Go! アプリケーションのデータベース構造を記録するためのものです。Firebase Firestore を使用したコレクションとドキュメント構造、各フィールドの説明を含みます。

## 認証システム

Firebase Authentication を使用したユーザー認証システムを実装しています。
- メールアドレス/パスワード認証
- Google認証（実装予定）
- Apple認証（iOS向け、実装予定）

## Firestore コレクション構造

### `coaches` コレクション

認定コーチ申請者のプロフィール情報を格納するコレクションです。

**ドキュメントID**: Firebase Authentication の UID と同一

**フィールド一覧**:

| フィールド名 | 型 | 説明 |
|------------|-------|-------------|
| `name` | string | コーチの名前 |
| `email` | string | コーチのメールアドレス（Firebase Auth と同一） |
| `inviteCode` | string | 招待コード（任意、空の場合あり） |
| `createdAt` | timestamp | アカウント作成日時（サーバータイムスタンプ） |
| `updatedAt` | timestamp | アカウント情報更新日時（サーバータイムスタンプ） |
| `isApproved` | boolean | 管理者による承認ステータス（デフォルト: false） |
| `isActive` | boolean | アカウントの有効状態（デフォルト: true） |

**インデックス**:
- `email`（検索効率化）
- `isApproved`（承認ステータスでのフィルタリング）

**セキュリティルール**:
```
match /coaches/{coachId} {
  allow read: if request.auth != null && request.auth.uid == coachId;
  allow write: if request.auth != null && request.auth.uid == coachId;
  // 管理者ユーザーによる読み取り/更新は別途定義予定
}
```

## Firestore クエリガイドライン

### スナップショット取得（cloud_firestore v5.x以降）

cloud_firestore v5.0.0 以降では、`snapshots()` メソッドに `listenSource` パラメータが必須となりました。以下の形式で実装してください：

```dart
// 正しい実装方式1: すべてのパラメータを指定
collectionRef.snapshots(
  includeMetadataChanges: true,
  listenSource: ListenSource.serverAndCache, // 初期対応では serverAndCache を使用
)

// 正しい実装方式2: 拡張メソッドを使用（推奨）
import 'package:golf_go/utils/firebase_extensions.dart';

// snapshotsCompat() を使用することで自動的にパラメータが設定される
collectionRef.snapshotsCompat(includeMetadataChanges: true)
```

利用可能な `ListenSource` オプション：
- `ListenSource.serverAndCache` - サーバーとキャッシュの両方からデータを取得
- `ListenSource.serverOnly` - サーバーからのみデータを取得
- `ListenSource.cacheOnly` - キャッシュからのみデータを取得
- `ListenSource.defaultSource` - デフォルトの振る舞い（通常は serverAndCache と等価）

### 拡張メソッド（utils/firebase_extensions.dart）

アプリ内では、Firebase Firestoreのクエリを簡素化するため、`firebase_extensions.dart`で拡張メソッドを提供しています：

```dart
// Query<T>に対する拡張メソッド - コレクションクエリ用
Stream<QuerySnapshot<T>> snapshotsCompat({
  bool includeMetadataChanges = false,
});

// DocumentReference<T>に対する拡張メソッド - 単一ドキュメント用
Stream<DocumentSnapshot<T>> snapshotsCompat({
  bool includeMetadataChanges = false,
});
```

**重要**: Firebase Firestoreを使う際は、直接`.snapshots()`を呼び出す代わりに、必ず`.snapshotsCompat()`を使用してください。

## 将来的な拡張予定

### `golfers` コレクション（実装予定）
レッスン受講者のプロフィール情報を格納するコレクション

### `plans` コレクション（実装予定）
コーチが提供するレッスンプランを格納するコレクション

### `lessons` コレクション（実装予定）
実際のレッスン予約および履歴を格納するコレクション
