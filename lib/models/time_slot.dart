import 'package:cloud_firestore/cloud_firestore.dart';

class TimeSlot {
  final String id;
  final String planId; // 紐づくプランのID
  final String startTime; // 開始時間 (HH:MM形式)
  final String endTime; // 終了時間 (HH:MM形式)
  final int price; // 料金（整数値・円）
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TimeSlot({
    required this.id,
    required this.planId,
    required this.startTime,
    required this.endTime,
    required this.price,
    this.createdAt,
    this.updatedAt,
  });

  // FirestoreドキュメントからTimeSlotオブジェクトを作成するファクトリーメソッド
  factory TimeSlot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TimeSlot(
      id: doc.id,
      planId: data['planId'] ?? '',
      startTime: data['startTime'] ?? '09:00',
      endTime: data['endTime'] ?? '10:00',
      price: (data['price'] ?? 0).toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // TimeSlotオブジェクトをFirestore用のMapに変換するメソッド
  Map<String, dynamic> toFirestore() {
    return {
      'planId': planId,
      'startTime': startTime,
      'endTime': endTime,
      'price': price,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // コピーメソッド - 値の一部を変更した新しいインスタンスを作成
  TimeSlot copyWith({
    String? id,
    String? planId,
    String? startTime,
    String? endTime,
    int? price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
