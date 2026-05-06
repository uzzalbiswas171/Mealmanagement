import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String memberId;
  final String memberName;
  final String text;
  final DateTime createdAt;
  final String? replyToId;
  final String? replyToName;
  final String? replyToText;

  const ChatMessage({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.text,
    required this.createdAt,
    this.replyToId,
    this.replyToName,
    this.replyToText,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final ts = d['createdAt'] as Timestamp?;
    return ChatMessage(
      id: doc.id,
      memberId: d['memberId'] as String? ?? '',
      memberName: d['memberName'] as String? ?? 'Unknown',
      text: d['text'] as String? ?? '',
      createdAt: ts?.toDate().toLocal() ?? DateTime.now(),
      replyToId:   d['replyToId']   as String?,
      replyToName: d['replyToName'] as String?,
      replyToText: d['replyToText'] as String?,
    );
  }
}
