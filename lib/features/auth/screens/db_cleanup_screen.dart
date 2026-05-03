import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// TEMPORARY SCREEN — remove after cleanup is done
class DbCleanupScreen extends StatefulWidget {
  const DbCleanupScreen({super.key});

  @override
  State<DbCleanupScreen> createState() => _DbCleanupScreenState();
}

class _DbCleanupScreenState extends State<DbCleanupScreen> {
  final _db = FirebaseFirestore.instance;
  bool _running = false;
  final List<String> _log = [];
  bool _done = false;

  void _addLog(String msg) {
    setState(() => _log.add(msg));
  }

  Future<void> _clearAll() async {
    setState(() {
      _running = true;
      _log.clear();
      _done = false;
    });

    try {
      // ── 1. Delete all groups and their subcollections ──────────────────────
      _addLog('Fetching groups...');
      final groups = await _db.collection('groups').get();
      _addLog('Found ${groups.docs.length} group(s)');

      for (final group in groups.docs) {
        final gRef = group.reference;

        // members
        final members = await gRef.collection('members').get();
        for (final d in members.docs) { await d.reference.delete(); }
        _addLog('  Deleted ${members.docs.length} members');

        // mealEntries
        final meals = await gRef.collection('mealEntries').get();
        for (final d in meals.docs) { await d.reference.delete(); }
        _addLog('  Deleted ${meals.docs.length} mealEntries');

        // marketEntries → items + verifications
        final markets = await gRef.collection('marketEntries').get();
        for (final me in markets.docs) {
          final items = await me.reference.collection('items').get();
          for (final d in items.docs) { await d.reference.delete(); }

          final verifs = await me.reference.collection('verifications').get();
          for (final d in verifs.docs) { await d.reference.delete(); }

          await me.reference.delete();
        }
        _addLog('  Deleted ${markets.docs.length} marketEntries');

        await gRef.delete();
        _addLog('  Group "${group.id}" deleted');
      }

      // ── 2. Delete all users except uzzal.biswas.cse@gmail.com ─────────────
      _addLog('Fetching users...');
      final users = await _db.collection('users').get();
      int kept = 0;
      int deleted = 0;
      for (final user in users.docs) {
        final email = user.data()['email'] as String? ?? '';
        if (email == 'uzzal.biswas.cse@gmail.com') {
          kept++;
          _addLog('  Kept user: $email');
        } else {
          await user.reference.delete();
          deleted++;
          _addLog('  Deleted user: ${email.isEmpty ? user.id : email}');
        }
      }
      _addLog('Users: kept $kept, deleted $deleted');

      _addLog('');
      _addLog('✓ All done! Database is clean.');
      setState(() => _done = true);
    } catch (e) {
      _addLog('ERROR: $e');
    } finally {
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('DB Cleanup', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('⚠ This will permanently delete:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('• All groups and their data'),
                  Text('• All meal entries'),
                  Text('• All market entries'),
                  Text('• All users except uzzal.biswas.cse@gmail.com'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _running ? null : _clearAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _done ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _running
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        _done ? '✓ Done — Go Back' : 'CLEAR ALL DATA',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            if (_done)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('← Back to Login'),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: SelectableText(
                    _log.isEmpty ? 'Tap button to start...' : _log.join('\n'),
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
