import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:luxe_cart_admin/screens/admin_products_screen.dart';
import 'package:luxe_cart_admin/screens/admin_users_screen.dart';
import 'package:luxe_cart_admin/screens/banned_users_screen.dart';
import 'package:luxe_cart_admin/screens/pending_products.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() =>
      _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _supabase = Supabase.instance.client;

  final String _paystackSecretKey =
      dotenv.env['PAYSTACK_SECRET_KEY']!;

  final String _recipientCode =
      dotenv.env['RECIPIENT_CODE']!;

  bool _isLoading = true;
  double _totalRevenue = 0.0;
  int _totalProducts = 0;
  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _fetchAdminStats();
    // _getOneTimeCode();
  }

  // Future<void> _getOneTimeCode() async {
  //   final response = await http.post(
  //     Uri.parse(
  //       'https://api.paystack.co/transferrecipient',
  //     ),
  //     headers: {
  //       'Authorization': 'Bearer $_paystackSecretKey',
  //       'Content-Type': 'application/json',
  //     },
  //     body: jsonEncode({
  //       "type": "nuban",
  //       "name": "Solomon David Solomon",
  //       "account_number":
  //           "7070649554", // Paystack Test Account
  //       "bank_code": "999992", // Paystack Test Bank Code
  //       "currency": "NGN",
  //     }),
  //   );
  //   print(
  //     "PAYSTACK RESPONSE: ${response.body}",
  //   ); // This shows the raw error if any
  // }

  Future<void> _fetchAdminStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final revenueData = await _supabase
          .from('admin_settings')
          .select('value_num')
          .eq('key', 'total_commissions')
          .maybeSingle();

      final productRes = await _supabase
          .from('products')
          .select()
          .count(CountOption.exact);

      // We only count active (non-banned) users for the dashboard total
      final userRes = await _supabase
          .from('profiles')
          .select()
          .eq('is_banned', false)
          .count(CountOption.exact);

      if (mounted) {
        setState(() {
          _totalRevenue =
              (revenueData != null &&
                  revenueData['value_num'] != null)
              ? double.parse(
                  revenueData['value_num'].toString(),
                )
              : 0.0;
          _totalProducts = productRes.count;
          _totalUsers = userRes.count;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Admin Stats Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- PAYSTACK TRANSFER LOGIC ---
  Future<void> _payoutViaPaystack(double amount) async {
    final response = await http.post(
      Uri.parse('https://api.paystack.co/transfer'),
      headers: {
        'Authorization': 'Bearer $_paystackSecretKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "source": "balance",
        "amount": (amount * 100)
            .toInt(), // Convert Naira to Kobo
        "recipient": _recipientCode,
        "reason": "Admin Commission Withdrawal",
      }),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode != 200 ||
        responseData['status'] == false) {
      throw responseData['message'] ??
          "Paystack transfer failed";
    }
  }

  Future<void> _handleWithdrawal(double amount) async {
    if (amount <= 0 || amount > _totalRevenue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Invalid amount or insufficient balance",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Call Paystack
      await _payoutViaPaystack(amount);

      // 2. Update Supabase
      final newBalance = _totalRevenue - amount;
      await _supabase
          .from('admin_settings')
          .update({'value_num': newBalance})
          .eq('key', 'total_commissions');

      await _fetchAdminStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              "Withdrawal successful! Check Paystack dashboard.",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: $e",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showWithdrawDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(
          context,
        ).scaffoldBackgroundColor,
        title: const Text("Withdraw Commissions"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Balance: ${NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 2).format(_totalRevenue)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
              decoration: const InputDecoration(
                labelText: "Amount",
                prefixText: "₦ ",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final val =
                  double.tryParse(controller.text) ?? 0;
              Navigator.pop(context);
              _handleWithdrawal(val);
            },
            child: const Text("Confirm Withdrawal"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor,
      appBar: AppBar(
        foregroundColor: Theme.of(
          context,
        ).colorScheme.onSurface,
        title: const Text("Admin Dashboard"),
        backgroundColor: Theme.of(
          context,
        ).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAdminStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildRevenueCard(),
                  const SizedBox(height: 25),
                  const Text(
                    "Quick Stats",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          "Products",
                          "$_totalProducts",
                          Icons.shopping_bag,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStatTile(
                          "Active Users",
                          "$_totalUsers",
                          Icons.people,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Controls",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 1. Manage Products
                  _buildControlTile(
                    "Manage Products",
                    "Review and remove listings",
                    Icons.edit_note,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AdminProductsScreen(),
                      ),
                    ),
                  ),

                  // 2. User Directory
                  _buildControlTile(
                    "User Directory",
                    "Manage active user accounts",
                    Icons.person_search,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AdminUsersScreen(),
                      ),
                    ),
                  ),

                  // 3. Banned Users (The new addition)
                  _buildControlTile(
                    "Banned Accounts",
                    "View and restore restricted users",
                    Icons.block_flipped,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const BannedUsersScreen(),
                      ),
                    ),
                  ),

                  _buildControlTile(
                    "Pending Products",
                    "Review pending product listings",
                    Icons.pending,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PendingProductsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Available Revenue",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            NumberFormat.currency(
              locale: 'en_NG',
              symbol: '₦',
              decimalDigits: 2,
            ).format(_totalRevenue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showWithdrawDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Withdraw to Bank"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.black),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
      ),
    );
  }
}
