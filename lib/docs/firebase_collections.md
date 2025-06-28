# Firebase データモデルとコレクション対応表

## データモデルとコレクション対応表

| モデルクラス | Firebaseコレクション名 | 用途 |
|------------|---------------------|------|
| Coach      | `coaches`           | コーチ情報（プロフィール、資格など） |
| Plan       | `plans`             | レッスンプラン情報（タイトル、説明、価格など） |
| TimeSlot   | `time_slots`        | 予約枠情報（日時、プランID、コーチID） |
| Reservation | `reservations`      | 予約情報（予約枠ID、ユーザーID） |

## コレクション構造

### coaches
- id: UID（Firebase Auth）
- name: String
- email: String
- profileImageUrl: String
- bio: String
- qualification: String
- isActive: boolean

### plans
- id: auto-generated
- title: String
- description: String
- coachId: String (ref: coaches.id)
- price: number
- duration: number (分単位)
- isActive: boolean
- isPublic: boolean
- createdAt: timestamp
- updatedAt: timestamp

### time_slots
- id: auto-generated
- planId: String (ref: plans.id)
- coachId: String (ref: coaches.id)
- startTime: timestamp
- endTime: timestamp
- price: number
- isBooked: boolean
- createdAt: timestamp

### reservations
- id: auto-generated
- timeSlotId: String (ref: time_slots.id)
- userId: String (ref: users.id)
- status: String (confirmed, cancelled, completed)
- createdAt: timestamp
- updatedAt: timestamp

## コード修正が必要な箇所

### TestDataHelper.dart
```dart
// 修正前
final timeSlotsSnapshot = await _firestore
    .collection('timeSlots')
    .limit(5)
    .get();

// 修正後
final timeSlotsSnapshot = await _firestore
    .collection('time_slots')
    .limit(5)
    .get();
```

### TimeSlot.dart のtoJson/fromJson メソッド
※モデルクラスとFirestoreコレクション名の一致を確認する

## 注意事項

- すべてのコードでコレクション名を統一する
- 新規コレクション作成時は命名規則を統一する（スネークケース推奨）
- デプロイ前に開発環境のFirestoreルールを本番環境に反映する
