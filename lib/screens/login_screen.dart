import 'package:flutter/material.dart';
import 'package:luxe_cart_admin/components/my_button.dart';
import 'package:luxe_cart_admin/components/my_textfield.dart';
import 'package:luxe_cart_admin/screens/admin_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final accessKeyController = TextEditingController();
  final String _adminSecret = "<h1>ADMIN</h1>";
  final _supabase = Supabase.instance.client;

  Future<void> loginWithKey() async {
    final enteredKey = accessKeyController.text.trim();

    // 1. Basic Key Check (First Gate)
    if (enteredKey != _adminSecret) {
      _showErrorDialog("Invalid Secret Key");
      return;
    }

    // 2. Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator()),
    );

    try {
      // 3. Trigger Google Sign-In (Second Gate)
      // Note: Use your existing Google Sign-In logic here
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // Ensure this matches your Supabase redirect settings
        redirectTo:
            'io.supabase.luxecartadmin://login-callback',
      );

      // Give Supabase a moment to catch the session
      await Future.delayed(
        const Duration(milliseconds: 2000),
      );
      final user = _supabase.auth.currentUser;

      if (user == null) throw Exception("Login failed");

      // 4. Verify User ID in Profiles Table (Third Gate - The "Boss" check)
      final profile = await _supabase
          .from('profiles')
          .select('is_admin')
          .eq('id', user.id)
          .single();

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (profile['is_admin'] == true) {
        // SUCCESS: Welcome to the Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboard(),
          ),
        );
      } else {
        // FAIL: Signed in, but not an admin in the DB
        await _supabase.auth.signOut();
        _showErrorDialog(
          "Unauthorized: Your User ID is not on the Admin list.",
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorDialog("Connection Error: ${e.toString()}");
    }
  }

  // Helper to keep the code clean
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Access Denied",
          style: TextStyle(color: Colors.red),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    accessKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 25.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Large Lock Icon
                Icon(
                  Icons.lock_person_rounded,
                  size: 100,
                  color: theme.colorScheme.primary,
                ),

                const SizedBox(height: 30),

                // 2. Title & Subtitle
                Text(
                  "ADMIN PANEL",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Enter secure access key to proceed",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.inversePrimary,
                  ),
                ),

                const SizedBox(height: 50),

                // 3. The Single Access Key TextField
                MyTextfield(
                  leading: Icons.vpn_key_rounded,
                  hintText: "Enter Secret Key",
                  obscureText:
                      true, // Hide the key as it's typed
                  controller: accessKeyController,
                ),

                const SizedBox(height: 25),

                // 4. Login Button
                MyButton(
                  text: "Authenticate",
                  onTap: loginWithKey,
                ),

                const SizedBox(height: 40),

                // Version Footer
                Text(
                  "Luxe Cart Admin • v1.0.0",
                  style: TextStyle(
                    color: theme.colorScheme.inversePrimary
                        .withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
