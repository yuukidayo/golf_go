import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../models/reservation.dart';
import '../models/time_slot.dart';

// メイン関数：Firebase初期化と予約作成を実行
void main() async {
  // Firebaseを初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await createTestReservations();
  print('テスト予約の作成が完了しました');
}

// テスト用予約データを作成する関数
Future<void> createTestReservations() async {
  try {
    // Firestoreのインスタンスを取得
    final firestore = FirebaseFirestore.instance;
    
    // 既存の予約枠を取得（最大5件）
    final timeSlotsSnapshot = await firestore
        .collection('timeSlots')
        .limit(5)
        .get();
    
    if (timeSlotsSnapshot.docs.isEmpty) {
      print('予約枠が見つかりません。先に予約枠を作成してください。');
      return;
    }
    
    print('取得した予約枠: ${timeSlotsSnapshot.docs.length}件');
    
    // テスト用ユーザーID（実際には実在するユーザーIDを使用）
    const testUserIds = ['test_user_1', 'test_user_2', 'test_user_3'];
    
    // 2025年6月の日付を生成
    final reservationDates = [
      DateTime(2025, 6, 3),  // 6月3日
      DateTime(2025, 6, 10), // 6月10日
      DateTime(2025, 6, 17), // 6月17日
    ];
    
    // 予約コレクションへの参照
    final reservationsRef = firestore.collection('reservations');
    
    // 各予約枠に対して予約を作成
    int createdCount = 0;
    for (int i = 0; i < timeSlotsSnapshot.docs.length && i < 3; i++) {
      final timeSlotDoc = timeSlotsSnapshot.docs[i];
      final timeSlot = TimeSlot.fromFirestore(timeSlotDoc);
      
      final reservation = Reservation(
        id: 'temp_id', // Firestoreが自動生成するので仮ID
        timeSlotId: timeSlot.id,
        userId: testUserIds[i % testUserIds.length],
        planId: timeSlot.planId,
        date: reservationDates[i % reservationDates.length],
        status: 'confirmed',
        createdAt: DateTime.now(),
      );
      
      // Firestoreに予約を追加
      final docRef = await reservationsRef.add(reservation.toFirestore());
      print('予約を作成しました: ${docRef.id}, 日付: ${reservationDates[i % reservationDates.length].toString().substring(0, 10)}');
      createdCount++;
    }
    
    print('$createdCount件の予約を作成しました');
  } catch (e) {
    print('エラーが発生しました: $e');
  }
}
