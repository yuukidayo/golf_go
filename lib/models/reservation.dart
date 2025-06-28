import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String timeSlotId; // 予約枠ID
  final String userId; // 予約者のユーザーID
  final String planId; // プランID
  final DateTime date; // 予約日
  final String status; // 予約ステータス（confirmed, cancelled, etc.）
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Reservation({
    required this.id,
    required this.timeSlotId,
    required this.userId,
    required this.planId,
    required this.date,
    this.status = 'confirmed',
    this.createdAt,
    this.updatedAt,
  });

  // FirestoreドキュメントからReservationオブジェクトを作成するファクトリーコンストラクタ
  factory Reservation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reservation(
      id: doc.id,
      timeSlotId: data['timeSlotId'] ?? '',
      userId: data['userId'] ?? '',
      planId: data['planId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      status: data['status'] ?? 'confirmed',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // ReservationオブジェクトをFirestore用のMapに変換するメソッド
  Map<String, dynamic> toFirestore() {
    return {
      'timeSlotId': timeSlotId,
      'userId': userId,
      'planId': planId,
      'date': Timestamp.fromDate(date),
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // コピーメソッド - 値の一部を変更した新しいインスタンスを作成
  Reservation copyWith({
    String? id,
    String? timeSlotId,
    String? userId,
    String? planId,
    DateTime? date,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      timeSlotId: timeSlotId ?? this.timeSlotId,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      date: date ?? this.date,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
