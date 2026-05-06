import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference _col(String groupId) =>
      _db.collection('groups').doc(groupId).collection('messages');

  /// Live stream of the last 200 messages, newest first.
  static Stream<QuerySnapshot> watchMessages(String groupId) =>
      _col(groupId)
          .orderBy('createdAt', descending: true)
          .limit(200)
          .snapshots();

  static Future<void> sendMessage({
    required String groupId,
    required String memberId,
    required String memberName,
    required String text,
    String? replyToId,
    String? replyToName,
    String? replyToText,
  }) =>
      _col(groupId).add({
        'memberId': memberId,
        'memberName': memberName.trim(),
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        if (replyToId != null)   'replyToId':   replyToId,
        if (replyToName != null) 'replyToName': replyToName,
        if (replyToText != null) 'replyToText': replyToText,
      });

  /// Deletes a single message by its document ID.
  static Future<void> deleteMessage({
    required String groupId,
    required String messageId,
  }) =>
      _col(groupId).doc(messageId).delete();

  /// Deletes every message in the group chat (batch in chunks of 500).
  static Future<void> deleteAllMessages(String groupId) async {
    const chunkSize = 500;
    while (true) {
      final snap = await _col(groupId).limit(chunkSize).get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snap.docs.length < chunkSize) break;
    }
  }
}
