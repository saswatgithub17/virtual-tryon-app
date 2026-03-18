import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:virtual_tryon_app/core/network/api_config.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';
import 'package:virtual_tryon_app/core/utils/app_config.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

class AdminDashboardPage extends StatefulWidget {
  final String token;
  final String adminName;

  const AdminDashboardPage({
    super.key,
    required this.token,
    required this.adminName,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _tab = 0;

  final List<String> _titles = [
    'Overview',
    'Orders',
    'Receipts',
    'Dresses',
    'Try-Ons',
  ];

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _OverviewTab(token: widget.token),
      _OrdersTab(token: widget.token),
      _ReceiptsTab(token: widget.token),
      _DressesTab(token: widget.token),
      _TryOnsTab(token: widget.token),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(_titles[_tab],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white, size: 18),
              label: const Text('Logout',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: tabs[_tab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Overview'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'Orders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Receipts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.checkroom_outlined),
              activeIcon: Icon(Icons.checkroom),
              label: 'Dresses'),
          BottomNavigationBarItem(
              icon: Icon(Icons.auto_fix_high_outlined),
              activeIcon: Icon(Icons.auto_fix_high),
              label: 'Try-Ons'),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Map<String, String> _authHeaders(String token) => {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

String _fmt(String? dateStr) {
  if (dateStr == null) return 'N/A';
  try {
    final d = DateTime.parse(dateStr).toLocal();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}  '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return dateStr;
  }
}

Widget _statusBadge(String status) {
  Color color;
  switch (status.toLowerCase()) {
    case 'completed':
      color = AppTheme.successColor;
      break;
    case 'pending':
      color = AppTheme.warningColor;
      break;
    case 'failed':
    case 'cancelled':
      color = AppTheme.errorColor;
      break;
    default:
      color = Colors.grey;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status.toUpperCase(),
      style: TextStyle(
          color: color, fontSize: 11, fontWeight: FontWeight.bold),
    ),
  );
}

Widget _loadingCenter() =>
    const Center(child: CircularProgressIndicator());

Widget _errorCenter(String msg, VoidCallback onRetry) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );

Widget _emptyCenter(String msg) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );

// ─── TAB 1 : OVERVIEW ─────────────────────────────────────────────────────────

class _OverviewTab extends StatefulWidget {
  final String token;
  const _OverviewTab({required this.token});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/stats'),
        headers: _authHeaders(widget.token),
      ).timeout(const Duration(seconds: 15));
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        setState(() {
          _stats = body['data'] as Map<String, dynamic>;
          _loading = false;
        });
      } else {
        setState(() {
          _error = body['message'];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _loadingCenter();
    if (_error != null) return _errorCenter(_error!, _load);

    final s = _stats!;
    final revenue = double.tryParse(s['total_revenue'].toString()) ?? 0.0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statGrid([
            _StatCard('Total Dresses', '${s['total_dresses'] ?? 0}',
                Icons.checkroom, Colors.purple),
            _StatCard('Total Orders', '${s['total_orders'] ?? 0}',
                Icons.shopping_bag, Colors.blue),
            _StatCard('Total Revenue',
                '₹${revenue.toStringAsFixed(0)}',
                Icons.currency_rupee, Colors.green),
            _StatCard('Total Try-Ons', '${s['total_tryons'] ?? 0}',
                Icons.auto_fix_high, Colors.orange),
          ]),
          const SizedBox(height: 16),
          _statGrid([
            _StatCard('Pending Orders',
                '${s['pending_orders'] ?? 0}',
                Icons.hourglass_empty, Colors.amber),
            _StatCard('Completed', '${s['completed_orders'] ?? 0}',
                Icons.check_circle, Colors.teal),
            _StatCard('Total Reviews', '${s['total_reviews'] ?? 0}',
                Icons.star, Colors.pink),
            _StatCard('Active Stock',
                '${s['total_dresses'] ?? 0} active',
                Icons.inventory, Colors.indigo),
          ]),
        ],
      ),
    );
  }

  Widget _statGrid(List<_StatCard> cards) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: cards,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── TAB 2 : ORDERS ───────────────────────────────────────────────────────────

class _OrdersTab extends StatefulWidget {
  final String token;
  const _OrdersTab({required this.token});

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;
  Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/orders'),
        headers: _authHeaders(widget.token),
      ).timeout(const Duration(seconds: 15));
      final body = jsonDecode(res.body);
      setState(() {
        _orders = body['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _markComplete(String orderId) async {
    try {
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/admin/orders/$orderId/complete'),
        headers: _authHeaders(widget.token),
      );
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _loadingCenter();
    if (_error != null) return _errorCenter(_error!, _load);
    if (_orders.isEmpty) return _emptyCenter('No orders yet');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _orders.length,
        itemBuilder: (ctx, i) {
          final o = _orders[i];
          final orderId = o['order_id'] as String;
          final isExpanded = _expanded.contains(orderId);
          final items = o['items'] as List? ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(orderId,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      _statusBadge(
                          o['payment_status'] ?? 'pending'),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(o['customer_name'] ?? 'N/A',
                          style: const TextStyle(fontSize: 13)),
                      Text(
                        '₹${double.tryParse(o['total_amount'].toString())?.toStringAsFixed(2) ?? "0.00"}  •  ${_fmt(o['created_at'])}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if ((o['payment_status'] ?? '') == 'pending')
                        TextButton(
                          onPressed: () => _markComplete(orderId),
                          child: const Text('Complete',
                              style: TextStyle(fontSize: 12)),
                        ),
                      IconButton(
                        icon: Icon(isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more),
                        onPressed: () => setState(() {
                          if (isExpanded) {
                            _expanded.remove(orderId);
                          } else {
                            _expanded.add(orderId);
                          }
                        }),
                      ),
                    ],
                  ),
                ),
                if (isExpanded && items.isNotEmpty) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Items',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        const SizedBox(height: 8),
                        ...items.map((item) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item['dress_name']} — ${item['size_name']}',
                                      style: const TextStyle(
                                          fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    '×${item['quantity']}  ₹${double.tryParse(item['subtotal'].toString())?.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey),
                                  ),
                                ],
                              ),
                            )),
                        const Divider(),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(
                              '₹${double.tryParse(o['total_amount'].toString())?.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                        if (o['customer_email'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                                'Email: ${o['customer_email']}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey)),
                          ),
                        if (o['customer_phone'] != null)
                          Text(
                              'Phone: ${o['customer_phone']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── TAB 3 : RECEIPTS ─────────────────────────────────────────────────────────

class _ReceiptsTab extends StatefulWidget {
  final String token;
  const _ReceiptsTab({required this.token});

  @override
  State<_ReceiptsTab> createState() => _ReceiptsTabState();
}

class _ReceiptsTabState extends State<_ReceiptsTab> {
  List<dynamic> _receipts = [];
  bool _loading = true;
  String? _error;
  String? _downloading;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/receipts'),
        headers: _authHeaders(widget.token),
      ).timeout(const Duration(seconds: 15));
      final body = jsonDecode(res.body);
      setState(() {
        _receipts = body['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _downloadReceipt(dynamic receipt) async {
    final orderId = receipt['order_id'] as String;
    final receiptUrl = receipt['receipt_url'] as String?;
    if (receiptUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No PDF available for this order')));
      return;
    }

    setState(() => _downloading = orderId);

    try {
      final fullUrl = ApiConfig.getUploadUrl(receiptUrl);
      final response =
          await http.get(Uri.parse(fullUrl)).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/receipt_$orderId.pdf');
        await file.writeAsBytes(response.bodyBytes);

        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'Receipt — $orderId',
        );
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to download receipt')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _downloading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _loadingCenter();
    if (_error != null) return _errorCenter(_error!, _load);
    if (_receipts.isEmpty) return _emptyCenter('No completed orders yet');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _receipts.length,
        itemBuilder: (ctx, i) {
          final r = _receipts[i];
          final orderId = r['order_id'] as String;
          final isDownloading = _downloading == orderId;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf,
                    color: AppTheme.primaryColor, size: 22),
              ),
              title: Text(orderId,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['customer_name'] ?? 'N/A',
                      style: const TextStyle(fontSize: 13)),
                  Row(
                    children: [
                      Text(
                        '₹${double.tryParse(r['total_amount'].toString())?.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600),
                      ),
                      const Text('  •  ',
                          style: TextStyle(color: Colors.grey)),
                      Text(
                        (r['payment_method'] ?? 'N/A').toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  Text(_fmt(r['created_at']),
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ],
              ),
              trailing: isDownloading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                      icon: const Icon(Icons.download),
                      color: AppTheme.primaryColor,
                      onPressed: () => _downloadReceipt(r),
                    ),
            ),
          );
        },
      ),
    );
  }
}

// ─── TAB 4 : DRESSES ──────────────────────────────────────────────────────────

class _DressesTab extends StatefulWidget {
  final String token;
  const _DressesTab({required this.token});

  @override
  State<_DressesTab> createState() => _DressesTabState();
}

class _DressesTabState extends State<_DressesTab> {
  List<dynamic> _dresses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/dresses'),
        headers: _authHeaders(widget.token),
      ).timeout(const Duration(seconds: 15));
      final body = jsonDecode(res.body);
      setState(() {
        _dresses = body['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openForm({Map<String, dynamic>? dress}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _DressFormPage(
          token: widget.token,
          dress: dress,
        ),
      ),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _loadingCenter();
    if (_error != null) return _errorCenter(_error!, _load);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _dresses.isEmpty
            ? _emptyCenter('No dresses found')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: _dresses.length,
                itemBuilder: (ctx, i) {
                  final d = _dresses[i];
                  final sizes = d['sizes'] as List? ?? [];
                  final totalStock = sizes.fold<int>(
                      0, (sum, s) => sum + (s['stock_quantity'] as int? ?? 0));
                  final isActive = d['is_active'] == 1;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: ApiConfig.getUploadUrl(
                                d['image_url'] ?? ''),
                            width: 90,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                width: 90,
                                height: 100,
                                color: Colors.grey[200]),
                            errorWidget: (_, __, ___) => Container(
                                width: 90,
                                height: 100,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image,
                                    color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 4),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        d['name'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.green.withOpacity(0.12)
                                            : Colors.red.withOpacity(0.12),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isActive ? 'Active' : 'Hidden',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isActive
                                              ? Colors.green[700]
                                              : Colors.red[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '₹${double.tryParse(d['price'].toString())?.toStringAsFixed(0)}  •  ${d['category'] ?? 'N/A'}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Stock: $totalStock units',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: totalStock > 0
                                        ? Colors.teal[700]
                                        : Colors.red[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Size chips
                                Wrap(
                                  spacing: 4,
                                  children: sizes.map<Widget>((s) {
                                    final qty =
                                        s['stock_quantity'] as int? ?? 0;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: qty > 0
                                            ? AppTheme.primaryColor
                                                .withOpacity(0.1)
                                            : Colors.grey[200],
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${s['size_name']}: $qty',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: qty > 0
                                              ? AppTheme.primaryColor
                                              : Colors.grey,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: AppTheme.primaryColor),
                          onPressed: () => _openForm(dress: d),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Dress',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ─── Dress add/edit form ──────────────────────────────────────────────────────

class _DressFormPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? dress;

  const _DressFormPage({required this.token, this.dress});

  @override
  State<_DressFormPage> createState() => _DressFormPageState();
}

class _DressFormPageState extends State<_DressFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isEdit = false;
  bool _saving = false;
  String? _error;

  // Controllers
  late TextEditingController _name;
  late TextEditingController _description;
  late TextEditingController _price;
  late TextEditingController _brand;
  late TextEditingController _color;
  late TextEditingController _material;
  String? _category;
  String _imageUrl = '';

  // Size stock controllers
  final Map<String, TextEditingController> _sizeControllers = {};
  final List<String> _allSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  // For holding existing size_id per size (needed for update)
  final Map<String, int?> _sizeIds = {};

  // Image picking
  File? _pickedImage;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.dress != null;

    final d = widget.dress ?? {};
    _name = TextEditingController(text: d['name'] ?? '');
    _description =
        TextEditingController(text: d['description'] ?? '');
    _price = TextEditingController(
        text: d['price']?.toString() ?? '');
    _brand = TextEditingController(text: d['brand'] ?? '');
    _color = TextEditingController(text: d['color'] ?? '');
    _material =
        TextEditingController(text: d['material'] ?? '');
    _category = d['category'];
    _imageUrl = d['image_url'] ?? '';

    // Initialise size controllers
    for (final size in _allSizes) {
      _sizeControllers[size] = TextEditingController(text: '0');
      _sizeIds[size] = null;
    }

    if (_isEdit) {
      final sizes = d['sizes'] as List? ?? [];
      for (final s in sizes) {
        final sizeName = s['size_name'] as String;
        if (_sizeControllers.containsKey(sizeName)) {
          _sizeControllers[sizeName]!.text =
              s['stock_quantity'].toString();
          _sizeIds[sizeName] = s['size_id'] as int?;
        }
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _brand.dispose();
    _color.dispose();
    _material.dispose();
    for (final c in _sizeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      _pickedImage = File(picked.path);
      _uploadingImage = true;
    });

    try {
      final dressId =
          _isEdit ? widget.dress!['dress_id'].toString() : '0';
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}/admin/dresses/$dressId/upload-image');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer ${widget.token}'
        ..files.add(await http.MultipartFile.fromPath(
          'image',
          picked.path,
          contentType: MediaType('image', 'jpeg'),
        ));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
      final body = jsonDecode(res.body);

      if (body['success'] == true) {
        setState(() => _imageUrl = body['data']['url']);
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image upload failed')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload error: $e')));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl.isEmpty && !_isEdit) {
      setState(() => _error = 'Please upload an image first');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    // Build sizes list
    final sizes = _allSizes.map((size) {
      return {
        'size_name': size,
        'stock_quantity':
            int.tryParse(_sizeControllers[size]!.text) ?? 0,
        if (_sizeIds[size] != null) 'size_id': _sizeIds[size],
      };
    }).toList();

    final payload = {
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'price': double.tryParse(_price.text.trim()) ?? 0,
      'category': _category,
      'brand': _brand.text.trim(),
      'color': _color.text.trim(),
      'material': _material.text.trim(),
      'image_url': _imageUrl,
      'sizes': jsonEncode(sizes),
    };

    try {
      http.Response res;
      if (_isEdit) {
        final dressId = widget.dress!['dress_id'].toString();
        res = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/admin/dresses/$dressId'),
          headers: _authHeaders(widget.token),
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 15));
      } else {
        res = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/admin/dresses'),
          headers: _authHeaders(widget.token),
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 15));
      }

      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() {
          _error = body['message'] ?? 'Save failed';
          _saving = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(_isEdit ? 'Edit Dress' : 'Add New Dress'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Image ───────────────────────────────────────────
            GestureDetector(
              onTap: _uploadingImage ? null : _pickAndUploadImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _uploadingImage
                    ? const Center(child: CircularProgressIndicator())
                    : _pickedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_pickedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity),
                          )
                        : _imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl:
                                      ApiConfig.getUploadUrl(_imageUrl),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      size: 48,
                                      color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text('Tap to upload image',
                                      style: TextStyle(
                                          color: Colors.grey[500])),
                                ],
                              ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Basic fields ─────────────────────────────────────
            _buildField(_name, 'Dress Name', required: true),
            _buildField(_description, 'Description', maxLines: 3),
            _buildField(_price, 'Price (₹)',
                required: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
            _buildField(_brand, 'Brand'),
            _buildField(_color, 'Color'),
            _buildField(_material, 'Material'),

            // ── Category dropdown ────────────────────────────────
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: AppConfig.categories.contains(_category)
                      ? _category
                      : null,
                  hint: const Text('Select Category'),
                  isExpanded: true,
                  items: AppConfig.categories
                      .where((c) => c != 'All')
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _category = val),
                ),
              ),
            ),

            // ── Sizes & Stock ─────────────────────────────────────
            const SizedBox(height: 20),
            const Text('Size Stock',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: _allSizes.map((size) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text(size,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _sizeControllers[size],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              suffixText: 'units',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style:
                        const TextStyle(color: AppTheme.errorColor)),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(_isEdit ? 'Save Changes' : 'Add Dress',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
      ),
    );
  }
}

// ─── TAB 5 : TRY-ONS ─────────────────────────────────────────────────────────

class _TryOnsTab extends StatefulWidget {
  final String token;
  const _TryOnsTab({required this.token});

  @override
  State<_TryOnsTab> createState() => _TryOnsTabState();
}

class _TryOnsTabState extends State<_TryOnsTab> {
  List<dynamic> _sessions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/tryon-history'),
        headers: _authHeaders(widget.token),
      ).timeout(const Duration(seconds: 15));
      final body = jsonDecode(res.body);
      setState(() {
        _sessions = body['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _loadingCenter();
    if (_error != null) return _errorCenter(_error!, _load);
    if (_sessions.isEmpty) return _emptyCenter('No try-on sessions yet');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _sessions.length,
        itemBuilder: (ctx, i) {
          final s = _sessions[i];
          final resultPaths =
              (s['result_image_paths'] as String? ?? '')
                  .split(',')
                  .where((p) => p.isNotEmpty)
                  .toList();
          final dressIds = (s['dress_ids'] as String? ?? '')
              .split(',')
              .where((p) => p.isNotEmpty)
              .length;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_fix_high,
                    color: Colors.purple, size: 22),
              ),
              title: Text(s['session_id'] ?? 'N/A',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  if ((s['dress_names'] as String?) != null)
                    Text(s['dress_names']!,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  Row(
                    children: [
                      const Icon(Icons.checkroom,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text('$dressIds dress${dressIds != 1 ? 'es' : ''}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      const SizedBox(width: 12),
                      const Icon(Icons.image,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                          '${resultPaths.length} result${resultPaths.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  Text(_fmt(s['created_at']),
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ],
              ),
              trailing: resultPaths.isNotEmpty
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    )
                  : Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}