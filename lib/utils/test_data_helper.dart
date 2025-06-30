import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../models/reservation.dart';
import '../models/time_slot.dart';

class TestDataHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Firebaseが初期化されているか確認
  static Future<bool> ensureFirebaseInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        print('TestDataHelper: Firebaseが初期化されていないため初期化を開始します');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('TestDataHelper: Firebase初期化完了');
        return true;
      }
      print('TestDataHelper: Firebaseは既に初期化されています');
      return true;
    } catch (e) {
      print('TestDataHelper: Firebase初期化エラー: $e');
      return false;
    }
  }

  /// テスト用の予約データを作成する
  static Future<List<String>> createTestReservations() async {
    try {
      print('TestDataHelper: 予約データ作成開始');
      
      // Firebase初期化を確認
      await ensureFirebaseInitialized();
      final List<String> createdReservationIds = [];
      
      // 既存の予約枠を取得（最大5件）
      print('TestDataHelper: Firestoreから予約枠を検索中...');
      final timeSlotsSnapshot = await _firestore
          .collection('timeSlots')
          .limit(5)
          .get();
      
      print('TestDataHelper: 検索結果 - ${timeSlotsSnapshot.docs.length}件の予約枠が見つかりました');
      
      if (timeSlotsSnapshot.docs.isEmpty) {
        print('TestDataHelper: 予約枠が見つからないため、新しい予約枠を作成します');
        // 予約枠がない場合は作成
        final timeSlotIds = await createTestTimeSlots();
        print('TestDataHelper: ${timeSlotIds.length}件の予約枠を作成しました');
        
        // 再度予約枠を取得
        final newTimeSlotsSnapshot = await _firestore
            .collection('timeSlots')
            .limit(5)
            .get();
            
        if (newTimeSlotsSnapshot.docs.isEmpty) {
          throw Exception('予約枠の作成に成功しましたが、取得できませんでした。');
        }
        
        return createTestReservations(); // 再帰的に呼び出し
      }
      
      // テスト用ユーザーID（実際には実在するユーザーIDを使用）
      const testUserIds = ['test_user_1', 'test_user_2', 'test_user_3'];
      
      // 2025年6月の日付を生成
      final reservationDates = [
        DateTime(2025, 6, 3),  // 6月3日
        DateTime(2025, 6, 10), // 6月10日
        DateTime(2025, 6, 17), // 6月17日
      ];
      
      // 予約コレクションへの参照
      final reservationsRef = _firestore.collection('reservations');
      
      // 各予約枠に対して予約を作成
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
        createdReservationIds.add(docRef.id);
      }
      
      return createdReservationIds;
    } catch (e) {
      throw Exception('テスト予約の作成中にエラーが発生しました: $e');
    }
  }

  /// テスト用の予約枠を作成する（予約枠が存在しない場合用）
  static Future<List<String>> createTestTimeSlots() async {
    try {
      final List<String> createdTimeSlotIds = [];
      
      // プランを取得または作成
      final planId = await _getOrCreateTestPlan();
      
      // テスト用の予約枠を作成
      final timeSlotData = [
        {'startTime': '09:00', 'endTime': '10:00', 'price': 5000},
        {'startTime': '10:30', 'endTime': '11:30', 'price': 5000},
        {'startTime': '13:00', 'endTime': '14:00', 'price': 5500},
      ];
      
      // 予約枠コレクションへの参照
      final timeSlotsRef = _firestore.collection('timeSlots');
      
      for (final slotData in timeSlotData) {
        final timeSlot = TimeSlot(
          id: 'temp_id',
          planId: planId,
          startTime: slotData['startTime'] as String,
          endTime: slotData['endTime'] as String,
          price: slotData['price'] as int,
          createdAt: DateTime.now(),
        );
        
        final docRef = await timeSlotsRef.add(timeSlot.toFirestore());
        createdTimeSlotIds.add(docRef.id);
      }
      
      return createdTimeSlotIds;
    } catch (e) {
      throw Exception('テスト予約枠の作成中にエラーが発生しました: $e');
    }
  }

  /// テスト用のプランを取得または作成する
  static Future<String> _getOrCreateTestPlan() async {
    try {
      // 既存のプランを確認
      final plansSnapshot = await _firestore
          .collection('plans')
          .limit(1)
          .get();
      
      // プランが存在する場合はそのIDを返す
      if (plansSnapshot.docs.isNotEmpty) {
        return plansSnapshot.docs.first.id;
      }
      
      // プランが存在しない場合は新規作成
      final testCoachId = await _getOrCreateTestCoach();
      
      final planRef = await _firestore.collection('plans').add({
        'title': 'テストレッスンプラン',
        'description': '予約テスト用のサンプルプラン',
        'coachId': testCoachId,
        'isActive': true,
        'isPublic': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return planRef.id;
    } catch (e) {
      throw Exception('テストプランの取得/作成中にエラーが発生しました: $e');
    }
  }

  /// テスト用のコーチを取得または作成する
  static Future<String> _getOrCreateTestCoach() async {
    try {
      // 既存のコーチユーザーを確認
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .limit(1)
          .get();
      
      // コーチが存在する場合はそのIDを返す
      if (usersSnapshot.docs.isNotEmpty) {
        return usersSnapshot.docs.first.id;
      }
      
      // コーチが存在しない場合はテスト用ユーザーを返す
      return 'test_coach_id';
    } catch (e) {
      throw Exception('テストコーチの取得/作成中にエラーが発生しました: $e');
    }
  }
}
