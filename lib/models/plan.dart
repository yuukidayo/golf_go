class Plan {
  final String id;
  final String title;
  final double price;
  final String description;

  const Plan({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
  });

  // モックデータを返すメソッド
  static List<Plan> getMockPlans() {
    return [
      const Plan(
        id: '1',
        title: 'スイング基礎マスタープラン',
        price: 12800,
        description: '初心者から中級者向けの4回コース。基本的なスイングフォームから実践的なショット技術まで、プロが丁寧に指導します。',
      ),
      const Plan(
        id: '2',
        title: 'バッティングマスタリー',
        price: 8500,
        description: 'スコアアップに直結するパッティング技術を徹底的に磨くための特別コース。グリーンリーディングからストロークまで。',
      ),
      const Plan(
        id: '3',
        title: 'スイング分析プレミアム',
        price: 15000,
        description: '最新のスイング解析システムを使用した徹底分析と改善プラン。あなたのスイングの問題点を科学的に解明します。',
      ),
      const Plan(
        id: '4',
        title: 'グループレッスンベーシック',
        price: 6500,
        description: '少人数制のグループレッスン。リラックスした雰囲気の中で基礎から学べます。初心者の方に特におすすめです。',
      ),
      const Plan(
        id: '5',
        title: 'ショートゲーム特訓コース',
        price: 9800,
        description: 'アプローチ、バンカー、チッピングなどショートゲームに特化したレッスン。スコアアップの近道です。',
      ),
    ];
  }
}
