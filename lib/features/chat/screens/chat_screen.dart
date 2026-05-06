import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/app_state.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/services/chat_service.dart';

class ChatBody extends StatefulWidget {
  const ChatBody({super.key});

  @override
  State<ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends State<ChatBody> {
  final _textCtrl = TextEditingController();
  StreamSubscription<QuerySnapshot>? _sub;
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _groupId;
  ChatMessage? _replyingTo;

  static const _palette = [
    Color(0xFFE3F2FD),
    Color(0xFFE8F5E9),
    Color(0xFFFFF3E0),
    Color(0xFFFCE4EC),
    Color(0xFFEDE7F6),
    Color(0xFFE0F2F1),
    Color(0xFFFFF9C4),
    Color(0xFFFFE0B2),
  ];

  static const _accentPalette = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFFE65100),
    Color(0xFFAD1457),
    Color(0xFF4527A0),
    Color(0xFF00695C),
    Color(0xFFF9A825),
    Color(0xFFBF360C),
  ];

  Color _bgColor(String memberId) {
    final h = memberId.codeUnits.fold(0, (a, b) => a + b);
    return _palette[h % _palette.length];
  }

  Color _accentColor(String memberId) {
    final h = memberId.codeUnits.fold(0, (a, b) => a + b);
    return _accentPalette[h % _accentPalette.length];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gid = context.read<AppState>().groupId;
    if (gid != null && gid != _groupId) {
      _groupId = gid;
      _sub?.cancel();
      _sub = ChatService.watchMessages(gid).listen((snap) {
        if (!mounted) return;
        setState(() {
          _messages =
              snap.docs.map((d) => ChatMessage.fromFirestore(d)).toList();
          _loading = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _sub?.cancel();
    super.dispose();
  }

  // ── Send ────────────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _groupId == null || _sending) return;
    final appState = context.read<AppState>();
    final userId = appState.userId;
    final name = appState.displayName;
    if (userId == null || name == null) return;

    final reply = _replyingTo;
    final replyText = reply != null
        ? (reply.text.length > 80
            ? '${reply.text.substring(0, 80)}…'
            : reply.text)
        : null;

    setState(() {
      _sending = true;
      _replyingTo = null;
    });
    _textCtrl.clear();
    try {
      await ChatService.sendMessage(
        groupId: _groupId!,
        memberId: userId,
        memberName: name,
        text: text,
        replyToId: reply?.id,
        replyToName: reply?.memberName,
        replyToText: replyText,
      );
    } catch (e) {
      if (!mounted) return;
      _textCtrl.text = text;
      setState(() => _replyingTo = reply);
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Single delete (long press) ───────────────────────────────────────────────

  Future<void> _confirmDeleteOne(ChatMessage msg) async {
    final groupId = _groupId;
    if (groupId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Delete this message? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ChatService.deleteMessage(
          groupId: groupId, messageId: msg.id);
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  // ── Delete all ──────────────────────────────────────────────────────────────

  Future<void> _confirmDeleteAll() async {
    final groupId = _groupId;
    if (groupId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Messages'),
        content: const Text(
            'This will permanently delete every message in the group chat. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.redAccent),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ChatService.deleteAllMessages(groupId);
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(color: Colors.white, fontSize: 13)),
      backgroundColor: AppColors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _formatTime(DateTime dt) {
    const mo = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '$h:$m';
    }
    return '${mo[dt.month - 1]} ${dt.day}  $h:$m';
  }

  // ── Reply preview bar ────────────────────────────────────────────────────────

  Widget _buildReplyBar() {
    final r = _replyingTo!;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.reply_rounded,
                        size: 13, color: AppColors.primaryBlue),
                    const SizedBox(width: 4),
                    Text(
                      r.memberName,
                      style: AppTextStyles.badgeText.copyWith(
                          color: AppColors.primaryBlue, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  r.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _replyingTo = null),
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final myId = appState.userId ?? '';
    final isManager = appState.role == 'manager';

    return Column(
      children: [
        // ── Manager toolbar ──────────────────────────────────────────────────
        if (isManager)
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.chat_rounded,
                    size: 16, color: AppColors.primaryBlue),
                const SizedBox(width: 6),
                Text('Group Chat',
                    style: AppTextStyles.headingSmall.copyWith(fontSize: 13)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _messages.isEmpty ? null : _confirmDeleteAll,
                  icon: const Icon(Icons.delete_sweep_rounded,
                      size: 18, color: AppColors.redAccent),
                  label: Text(
                    'Delete All',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.redAccent),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                  ),
                ),
              ],
            ),
          ),

        // ── Message list ─────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final msg = _messages[i];
                        final isMe = msg.memberId == myId;
                        return _MessageBubble(
                          message: msg,
                          isMe: isMe,
                          isManager: isManager,
                          bgColor: isMe
                              ? AppColors.primaryBlue
                              : _bgColor(msg.memberId),
                          accentColor: isMe
                              ? Colors.white
                              : _accentColor(msg.memberId),
                          formatTime: _formatTime,
                          onDelete: () => _confirmDeleteOne(msg),
                          onReply: () =>
                              setState(() => _replyingTo = msg),
                        );
                      },
                    ),
        ),

        // ── Reply preview bar ────────────────────────────────────────────────
        if (_replyingTo != null) _buildReplyBar(),

        // ── Input bar ────────────────────────────────────────────────────────
        _buildInputBar(context),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              size: 56, color: AppColors.greyBorder),
          const SizedBox(height: 12),
          Text('No messages yet',
              style: AppTextStyles.headingSmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('Be the first to say something!',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.greyBorder),
              ),
              child: TextField(
                controller: _textCtrl,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.tableCell,
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: AppTextStyles.bodySmall,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _sending
                    ? AppColors.primaryBlue.withValues(alpha: 0.5)
                    : AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isManager;
  final Color bgColor;
  final Color accentColor;
  final String Function(DateTime) formatTime;
  final VoidCallback onDelete;
  final VoidCallback onReply;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isManager,
    required this.bgColor,
    required this.accentColor,
    required this.formatTime,
    required this.onDelete,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMe) ...[
            Text(
              message.memberName,
              style: AppTextStyles.badgeText.copyWith(
                color: accentColor,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
          ],
          // ── Quoted reply block ─────────────────────────────────────────────
          if (message.replyToText != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : accentColor,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.replyToName ?? '',
                    style: AppTextStyles.badgeText.copyWith(
                      fontSize: 10,
                      color: isMe ? Colors.white : accentColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.replyToText ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.metaText.copyWith(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Text(
            message.text,
            style: AppTextStyles.tableCell.copyWith(
              color: isMe ? Colors.white : AppColors.textPrimary,
              height: 1.4,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatTime(message.createdAt),
            style: AppTextStyles.metaText.copyWith(
              fontSize: 10,
              color: isMe
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: 6,
        left: isMe ? 52 : 0,
        right: isMe ? 0 : 52,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () => _showMessageActions(context),
          child: bubble,
        ),
      ),
    );
  }

  void _showMessageActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE1E7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.reply_rounded,
                  color: AppColors.primaryBlue),
              title: Text(
                'Reply to this message',
                style: AppTextStyles.headingSmall
                    .copyWith(color: AppColors.primaryBlue),
              ),
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            if (isManager) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.redAccent),
                title: Text(
                  'Delete this message',
                  style: AppTextStyles.headingSmall
                      .copyWith(color: AppColors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.close_rounded,
                  color: AppColors.textSecondary),
              title: Text('Cancel', style: AppTextStyles.bodyMedium),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
