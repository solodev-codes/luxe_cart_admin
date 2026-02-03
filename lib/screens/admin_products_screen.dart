import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luxe_cart_admin/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState
    extends State<AdminProductsScreen> {
  final _supabase = Supabase.instance.client;

  Future<void> _deleteProduct(String id) async {
    try {
      // 1. Perform the delete
      final response = await _supabase
          .from('products')
          .delete()
          .eq('id', id)
          .select();

      if (response.isNotEmpty) {
        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                "Successfully removed from database",
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      } else {
        throw "No rows were deleted. Check RLS policies.";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Delete Failed: $e",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 2. Update the StreamBuilder to be more specific
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(
          context,
        ).scaffoldBackgroundColor,
        foregroundColor: Theme.of(
          context,
        ).colorScheme.onSurface,
        title: const Text("Manage All Listings"),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Explicitly ordering by created_at helps the stream stay consistent
        stream: _supabase
            .from('products')
            .stream(primaryKey: ['id'])
            .order('created_at'),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final products = snapshot.data!;

          if (products.isEmpty) {
            return const Center(
              child: Text("No products listed yet."),
            );
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final item = products[index];
              return Card(
                color: darkCharcoalSurface,
                elevation: 0,
                margin: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      item['image_url'],
                    ),
                  ),
                  title: Text(item['title']),
                  subtitle: Text(
                    "${NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 2).format(double.tryParse(item['price'].toString()) ?? 0.0)} | ${item['seller_phone']}",
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () => _showDeleteDialog(
                      item['id'].toString(),
                      item['title'],
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

  void _showDeleteDialog(String id, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(
          context,
        ).scaffoldBackgroundColor,
        title: const Text("Delete Listing?"),
        content: Text(
          "Are you sure you want to remove '$title'? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(id);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
