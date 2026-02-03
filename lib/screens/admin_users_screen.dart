import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luxe_cart_admin/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() =>
      _AdminUsersScreenState();
}

class _AdminUsersScreenState
    extends State<AdminUsersScreen> {
  final _supabase = Supabase.instance.client;

  // Function to delete user profile
  Future<void> _deleteUser(
    String userId,
    String username,
  ) async {
    try {
      await _supabase
          .from('profiles')
          .update({'is_banned': true})
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              "User '$username' has been moved to banned list successfully.",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        // Refresh the UI
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error restricting user: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error restricting user: $e",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Confirmation Dialog
  void _confirmDelete(String userId, String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(
          context,
        ).scaffoldBackgroundColor,
        title: const Text("Confirm Restriction"),
        content: Text(
          "Are you sure you want to ban $username? You can unban it later!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(userId, username);
            },
            child: const Text(
              "Ban User",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Directory"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Added a key to FutureBuilder to force refresh when setState is called
        key: UniqueKey(),
        future: _supabase
            .from('profiles')
            .select()
            .eq('is_banned', false)
            .order('wallet_balance', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text("No users found."),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final String userId = user['id'];
              final String username =
                  user['username'] ??
                  user['email'] ??
                  "New Member";
              final double balance =
                  double.tryParse(
                    user['wallet_balance'].toString(),
                  ) ??
                  0.0;

              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: darkCharcoalSurface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: ListTile(
                  onLongPress: () => _confirmDelete(
                    userId,
                    username,
                  ), // Extra safety
                  leading: CircleAvatar(
                    backgroundImage:
                        user['avatar_url'] != null
                        ? NetworkImage(user['avatar_url'])
                        : null,
                    child: user['avatar_url'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    NumberFormat.currency(
                      locale: 'en_NG',
                      symbol: '₦',
                    ).format(balance),
                    style: TextStyle(
                      color: balance > 0
                          ? Colors.green
                          : Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.app_blocking_outlined,
                      color: Colors.redAccent,
                    ),
                    onPressed: () =>
                        _confirmDelete(userId, username),
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
