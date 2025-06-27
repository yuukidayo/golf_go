import 'package:cloud_firestore/cloud_firestore.dart';

class Plan {
  final String id;
  final String title;
  final String description;
  final String coachId; // プランを作成したコーチのID
  final bool isActive; // プランが有効かどうか
  final bool isPublic; // プランが公開されているかどうか
  final DateTime? createdAt; // 作成日時
  final DateTime? updatedAt; // 更新日時

  const Plan({
    required this.id,
    required this.title,
    required this.description,
    required this.coachId,
    this.isActive = true,
    this.isPublic = true,
    this.createdAt,
    this.updatedAt,
  });

  // FirestoreドキュメントからPlanオブジェクトを作成するファクトリーコンストラクタ
  factory Plan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Plan(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      coachId: data['coachId'] ?? '',
      isActive: data['isActive'] ?? true,
      isPublic: data['isPublic'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // PlanオブジェクトをFirestore用のMapに変換するメソッド
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'coachId': coachId,
      'isActive': isActive,
      'isPublic': isPublic,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // コピーメソッド - 値の一部を変更した新しいインスタンスを作成
  Plan copyWith({
    String? id,
    String? title,
    String? description,
    String? coachId,
    bool? isActive,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Plan(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coachId: coachId ?? this.coachId,
      isActive: isActive ?? this.isActive,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // モックデータを返すメソッド（開発用）
  static List<Plan> getMockPlans() {
    return [
      Plan(
        id: '1',
        title: 'スイング基礎マスタープラン',
        description: '初心者から中級者向けの4回コース。基本的なスイングフォームから実践的なショット技術まで、プロが丁寧に指導します。',
        coachId: 'mock_coach_id',
        isPublic: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Plan(
        id: '2',
        title: 'バッティングマスタリー',
        description: 'スコアアップに直結するパッティング技術を徹底的に磨くための特別コース。グリーンリーディングからストロークまで。',
        coachId: 'mock_coach_id',
        isPublic: true,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      Plan(
        id: '3',
        title: 'スイング分析プレミアム',
        description: '最新のスイング解析システムを使用した徹底分析と改善プラン。あなたのスイングの問題点を科学的に解明します。',
        coachId: 'mock_coach_id',
        isPublic: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Plan(
        id: '4',
        title: 'グループレッスンベーシック',
        description: '少人数制のグループレッスン。リラックスした雰囲気の中で基礎から学べます。初心者の方に特におすすめです。',
        coachId: 'mock_coach_id',
        isPublic: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Plan(
        id: '5',
        title: 'ショートゲーム特訓コース',
        description: 'アプローチ、バンカー、チッピングなどショートゲームに特化したレッスン。スコアアップの近道です。',
        coachId: 'mock_coach_id',
        isPublic: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }
}
