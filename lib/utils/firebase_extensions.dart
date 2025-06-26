import 'package:cloud_firestore/cloud_firestore.dart';

/// FirebaseFirestore 4.15.8用の拡張メソッド
/// 
/// Firestore 5.0.0ではプラットフォームによってsource/listenSourceパラメータの
/// 不整合があったため、バージョン4.15.8にダウングレードした後の実装です。
/// 4.15.8ではこのような不整合はないため、Source enumを使用したシンプルな実装に変更しました。

/// FirebaseFirestoreのQueryに対する拡張メソッド
extension FirestoreQueryExtensions<T> on Query<T> {
  /// sourceパラメータが省略された場合、デフォルト値を使用するsnapshots()取得拡張メソッド
  Stream<QuerySnapshot<T>> snapshotsCompat({
    bool includeMetadataChanges = false,
    Source? source,
  }) {
    // cloud_firestore 4.15.8では、Source enumを使用し、プラットフォーム間の不整合はない
    return snapshots(
      includeMetadataChanges: includeMetadataChanges,
      source: source ?? Source.serverAndCache,
    );
  }
}

/// FirestoreのDocumentReferenceに対する拡張メソッド
extension DocumentReferenceExtensions<T> on DocumentReference<T> {
  /// sourceパラメータが省略された場合、デフォルト値を使用するsnapshots()取得拡張メソッド
  Stream<DocumentSnapshot<T>> snapshotsCompat({
    bool includeMetadataChanges = false,
    Source? source,
  }) {
    // cloud_firestore 4.15.8では、Source enumを使用し、プラットフォーム間の不整合はない
    return snapshots(
      includeMetadataChanges: includeMetadataChanges,
      source: source ?? Source.serverAndCache,
    );
  }
}

/// Firebase Documentation
/// 
/// Source 利用可能な値:
/// - Source.serverAndCache: デフォルトの動作。キャッシュから初期スナップショットを取得し、Firestoreサーバーから最新スナップショットを取得するよう試みます。
/// - Source.server: 常にサーバーからデータを取得します。
/// - Source.cache: ローカルFirestoreキャッシュのみからデータを取得します。
