import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  coach,
  golfer,
  unknown
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 現在のユーザーを取得
  User? get currentUser => _auth.currentUser;
  
  // ユーザーのロールを確認
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
  
  // ロールに基づいて適切なホーム画面ルートを取得
  Future<String> getHomeRouteForCurrentUser() async {
    final role = await getUserRole();
    
    switch (role) {
      case UserRole.coach:
        return '/coach/plans';
      case UserRole.golfer:
        return '/golfer/home';
      case UserRole.unknown:
        // ロールが不明な場合はウェルカム画面に戻す
        return '/';
    }
  }
  
  // サインアウト
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
