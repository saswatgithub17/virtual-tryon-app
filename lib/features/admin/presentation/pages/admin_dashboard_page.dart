import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';
import 'package:virtual_tryon_app/core/services/local_database_service.dart';
import 'package:virtual_tryon_app/core/router/app_router.dart';
import 'package:virtual_tryon_app/core/network/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

@RoutePage()
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentIndex = 0;
  Map<String, dynamic> _stats = {};
  List<dynamic> _orders = [];
  List<dynamic> _receipts = [];
  List<dynamic> _tryOnHistory = [];
  List<dynamic> _dresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await LocalDatabaseService.getAdminStats();
      final orders = await LocalDatabaseService.getAllOrders();
      final receipts = await LocalDatabaseService.getAllReceipts();
      final tryOnHistory = await LocalDatabaseService.getTryOnHistory();

      try {
        final response =
            await http.get(Uri.parse(ApiConfig.dresses));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (mounted) {
            setState(() {
              _dresses = data is List ? data : [];
            });
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _stats = stats;
          _orders = orders;
          _receipts = receipts;
          _tryOnHistory = tryOnHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content:
                      const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.router.popUntilRoot();
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag), label: 'Orders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Receipts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.checkroom), label: 'Dresses'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'Try-On'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildOrders();
      case 2:
        return _buildReceipts();
      case 3:
        return _buildDresses();
      case 4:
        return _buildTryOnHistory();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overview',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Total Try-Ons',
                    '${_stats['try_on_count'] ?? 0}', Icons.camera_alt, Colors.blue),
                _buildStatCard('Wishlist Items',
                    '${_stats['wishlist_count'] ?? 0}', Icons.favorite, Colors.red),
                _buildStatCard('Total Orders',
                    '${_stats['orders_count'] ?? 0}', Icons.shopping_cart, Colors.green),
                // Fix 3: ₹ instead of $
                _buildStatCard(
                  'Total Revenue',
                  '₹${(_stats['total_revenue'] ?? 0.0).toStringAsFixed(2)}',
                  Icons.currency_rupee,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Recent Orders',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_orders.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No orders yet'),
                ),
              )
            else
              ...(_orders.take(5).map((o) => _buildOrderCard(o))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child:
              const Icon(Icons.shopping_bag, color: Colors.white),
        ),
        title: Text('Order #${order['order_id']}'),
        // Fix 3: ₹ instead of $
        subtitle:
            Text('₹${order['total_amount']} — ${order['status']}'),
        trailing: Text(_formatDate(order['created_at']),
            style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildOrders() {
    if (_orders.isEmpty) {
      return const Center(child: Text('No orders found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${order['order_id']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    _buildStatusChip(order['status']),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Customer: ${order['customer_name'] ?? 'N/A'}'),
                Text('Phone: ${order['customer_phone'] ?? 'N/A'}'),
                Text('Email: ${order['customer_email'] ?? 'N/A'}'),
                const Divider(),
                // Fix 3: ₹ instead of $
                Text('Total: ₹${order['total_amount']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (order['status'] == 'pending')
                      ElevatedButton(
                        onPressed: () async {
                          await LocalDatabaseService
                              .updateOrderStatus(
                                  order['order_id'], 'completed');
                          _loadData();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        child: const Text('Mark Complete'),
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12)),
    );
  }

  Widget _buildReceipts() {
    if (_receipts.isEmpty) {
      return const Center(child: Text('No receipts found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _receipts.length,
      itemBuilder: (context, index) {
        final receipt = _receipts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.receipt, color: Colors.white),
            ),
            title: Text('Receipt #${receipt['receipt_id']}'),
            // Fix 3: ₹
            subtitle: Text(
                'Order #${receipt['order_id']}\n₹${receipt['total_amount']}'),
            isThreeLine: true,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatDate(receipt['created_at']),
                    style: const TextStyle(fontSize: 12)),
                Text(receipt['payment_method'] ?? 'N/A',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            onTap: () => _showReceiptDetails(receipt),
          ),
        );
      },
    );
  }

  void _showReceiptDetails(dynamic receipt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Receipt Details',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const Divider(),
              Text('Receipt ID: ${receipt['receipt_id']}'),
              Text('Order ID: ${receipt['order_id']}'),
              Text('Customer: ${receipt['customer_name']}'),
              Text('Phone: ${receipt['customer_phone']}'),
              Text('Email: ${receipt['customer_email']}'),
              Text('Payment: ${receipt['payment_method']}'),
              const Divider(),
              // Fix 3: ₹
              Text('Total: ₹${receipt['total_amount']}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDresses() {
    if (_dresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No dresses found'),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadData, child: const Text('Refresh')),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _dresses.length,
      itemBuilder: (context, index) {
        final dress = _dresses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl:
                      ApiConfig.getUploadUrl(dress['imageUrl'] ?? ''),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[200],
                      child: const Center(
                          child: CircularProgressIndicator())),
                  errorWidget: (context, url, error) => Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[200],
                      child: const Icon(Icons.error)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dress['name'] ?? 'Unknown',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Category: ${dress['category'] ?? 'N/A'}'),
                      // Fix 3: ₹
                      Text('₹${dress['price'] ?? 0}',
                          style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(
                              dress['isUpcoming'] == true
                                  ? Icons.upcoming
                                  : Icons.check_circle,
                              size: 16,
                              color: dress['isUpcoming'] == true
                                  ? Colors.orange
                                  : Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            dress['isUpcoming'] == true
                                ? 'Upcoming'
                                : 'Available',
                            style: TextStyle(
                                color: dress['isUpcoming'] == true
                                    ? Colors.orange
                                    : Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTryOnHistory() {
    if (_tryOnHistory.isEmpty) {
      return const Center(child: Text('No try-on history found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tryOnHistory.length,
      itemBuilder: (context, index) {
        final item = _tryOnHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: ApiConfig.getUploadUrl(
                      item['dress_image'] ?? ''),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(width: 80, height: 80, color: Colors.grey[200]),
                  errorWidget: (context, url, error) =>
                      Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.error)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['dress_name'] ?? 'Unknown',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      Text('Tried on: ${_formatDate(item['created_at'])}',
                          style: const TextStyle(fontSize: 12)),
                      Row(
                        children: [
                          Icon(
                              item['is_favorite'] == 1
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                              color: item['is_favorite'] == 1
                                  ? Colors.red
                                  : Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                              item['is_favorite'] == 1
                                  ? 'Favorited'
                                  : 'Not favorited',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}