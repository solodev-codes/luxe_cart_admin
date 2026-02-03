import 'package:flutter/material.dart';
import 'package:luxe_cart_admin/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BannedUsersScreen extends StatefulWidget {
  const BannedUsersScreen({super.key});

  @override
  State<BannedUsersScreen> createState() =>
      _BannedUsersScreenState();
}

class _BannedUsersScreenState
    extends State<BannedUsersScreen> {
  final _supabase = Supabase.instance.client;

  Future<void> _unbanUser(
    String userId,
    String username,
  ) async {
    try {
      await _supabase
          .from('profiles')
          .update({'is_banned': false})
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              "$username has been restored.",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
        setState(() {}); // Refresh list
      }
    } catch (e) {
      debugPrint("Error unbanning: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Banned Accounts")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        key: UniqueKey(),
        future: _supabase
            .from('profiles')
            .select()
            .eq('is_banned', true), // Only get banned users
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text(
                "No banned users. Everyone is behaving!",
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: darkCharcoalSurface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.red.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(
                      Icons.block,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    user['username'] ?? "Unknown User",
                  ),
                  subtitle: const Text(
                    "Access Restricted",
                    style: TextStyle(color: Colors.red),
                  ),
                  trailing: TextButton.icon(
                    onPressed: () => _unbanUser(
                      user['id'],
                      user['username'],
                    ),
                    icon: const Icon(
                      Icons.restore,
                      size: 18,
                    ),
                    label: const Text("Unban"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
