import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseService {
  static Database? _database;
  static const String _databaseName = 'virtual_tryon.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String tableTryOnHistory = 'try_on_history';
  static const String tableWishlist = 'wishlist';
  static const String tableOrders = 'orders';
  static const String tableReceipts = 'receipts';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Try-On History Table
    await db.execute('''
      CREATE TABLE $tableTryOnHistory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dress_id TEXT NOT NULL,
        dress_name TEXT NOT NULL,
        dress_image TEXT NOT NULL,
        try_on_image TEXT,
        created_at TEXT NOT NULL,
        is_favorite INTEGER DEFAULT 0
      )
    ''');

    // Wishlist Table
    await db.execute('''
      CREATE TABLE $tableWishlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dress_id TEXT NOT NULL,
        dress_name TEXT NOT NULL,
        dress_image TEXT NOT NULL,
        dress_price REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Orders Table (Local Storage)
    await db.execute('''
      CREATE TABLE $tableOrders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id TEXT NOT NULL UNIQUE,
        items TEXT NOT NULL,
        total_amount REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        customer_name TEXT,
        customer_phone TEXT,
        customer_email TEXT
      )
    ''');

    // Receipts Table (Local Storage)
    await db.execute('''
      CREATE TABLE $tableReceipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt_id TEXT NOT NULL UNIQUE,
        order_id TEXT NOT NULL,
        items TEXT NOT NULL,
        total_amount REAL NOT NULL,
        payment_method TEXT,
        created_at TEXT NOT NULL,
        customer_name TEXT,
        customer_phone TEXT,
        customer_email TEXT,
        receipt_pdf_path TEXT
      )
    ''');
  }

  // ==================== TRY-ON HISTORY METHODS ====================

  static Future<int> addTryOnHistory({
    required String dressId,
    required String dressName,
    required String dressImage,
    String? tryOnImage,
  }) async {
    final db = await database;
    return await db.insert(tableTryOnHistory, {
      'dress_id': dressId,
      'dress_name': dressName,
      'dress_image': dressImage,
      'try_on_image': tryOnImage,
      'created_at': DateTime.now().toIso8601String(),
      'is_favorite': 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getTryOnHistory() async {
    final db = await database;
    return await db.query(
      tableTryOnHistory,
      orderBy: 'created_at DESC',
    );
  }

  static Future<int> deleteTryOnHistory(int id) async {
    final db = await database;
    return await db.delete(
      tableTryOnHistory,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> toggleTryOnFavorite(int id, bool isFavorite) async {
    final db = await database;
    return await db.update(
      tableTryOnHistory,
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Map<String, dynamic>>> getFavoriteTryOns() async {
    final db = await database;
    return await db.query(
      tableTryOnHistory,
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
  }

  // ==================== WISHLIST METHODS ====================

  static Future<int> addToWishlist({
    required String dressId,
    required String dressName,
    required String dressImage,
    required double dressPrice,
  }) async {
    final db = await database;
    
    // Check if already exists
    final existing = await db.query(
      tableWishlist,
      where: 'dress_id = ?',
      whereArgs: [dressId],
    );
    
    if (existing.isNotEmpty) {
      return -1; // Already exists
    }
    
    return await db.insert(tableWishlist, {
      'dress_id': dressId,
      'dress_name': dressName,
      'dress_image': dressImage,
      'dress_price': dressPrice,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getWishlist() async {
    final db = await database;
    return await db.query(
      tableWishlist,
      orderBy: 'created_at DESC',
    );
  }

  static Future<int> removeFromWishlist(String dressId) async {
    final db = await database;
    return await db.delete(
      tableWishlist,
      where: 'dress_id = ?',
      whereArgs: [dressId],
    );
  }

  static Future<bool> isInWishlist(String dressId) async {
    final db = await database;
    final result = await db.query(
      tableWishlist,
      where: 'dress_id = ?',
      whereArgs: [dressId],
    );
    return result.isNotEmpty;
  }

  // ==================== ORDER METHODS (LOCAL) ====================

  static Future<int> saveOrder({
    required String orderId,
    required String items,
    required double totalAmount,
    required String status,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    final db = await database;
    return await db.insert(tableOrders, {
      'order_id': orderId,
      'items': items,
      'total_amount': totalAmount,
      'status': status,
      'created_at': DateTime.now().toIso8601String(),
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
    });
  }

  static Future<List<Map<String, dynamic>>> getAllOrders() async {
    final db = await database;
    return await db.query(
      tableOrders,
      orderBy: 'created_at DESC',
    );
  }

  static Future<int> updateOrderStatus(String orderId, String status) async {
    final db = await database;
    return await db.update(
      tableOrders,
      {'status': status},
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  // ==================== RECEIPT METHODS (LOCAL) ====================

  static Future<int> saveReceipt({
    required String receiptId,
    required String orderId,
    required String items,
    required double totalAmount,
    String? paymentMethod,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? receiptPdfPath,
  }) async {
    final db = await database;
    return await db.insert(tableReceipts, {
      'receipt_id': receiptId,
      'order_id': orderId,
      'items': items,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'created_at': DateTime.now().toIso8601String(),
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'receipt_pdf_path': receiptPdfPath,
    });
  }

  static Future<List<Map<String, dynamic>>> getAllReceipts() async {
    final db = await database;
    return await db.query(
      tableReceipts,
      orderBy: 'created_at DESC',
    );
  }

  static Future<Map<String, dynamic>?> getReceiptById(String receiptId) async {
    final db = await database;
    final result = await db.query(
      tableReceipts,
      where: 'receipt_id = ?',
      whereArgs: [receiptId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // ==================== STATISTICS ====================

  static Future<Map<String, dynamic>> getAdminStats() async {
    final db = await database;
    
    final tryOnCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableTryOnHistory'),
    ) ?? 0;
    
    final wishlistCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableWishlist'),
    ) ?? 0;
    
    final ordersCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableOrders'),
    ) ?? 0;
    
    final receiptsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableReceipts'),
    ) ?? 0;
    
    double totalRevenue = 0.0;
    try {
      final result = await db.rawQuery(
        'SELECT SUM(total_amount) as total FROM $tableOrders WHERE status = ?',
        ['completed'],
      );
      if (result.isNotEmpty && result.first['total'] != null) {
        totalRevenue = (result.first['total'] as num).toDouble();
      }
    } catch (e) {
      totalRevenue = 0.0;
    }
    
    return {
      'try_on_count': tryOnCount,
      'wishlist_count': wishlistCount,
      'orders_count': ordersCount,
      'receipts_count': receiptsCount,
      'total_revenue': totalRevenue,
    };
  }
}
