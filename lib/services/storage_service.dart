// lib/services/storage_service.dart
// Local Storage Service using SharedPreferences

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class StorageService {
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  // Initialize
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Get SharedPreferences instance
  Future<SharedPreferences> get _getInstance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==================== STRING ====================

  Future<bool> setString(String key, String value) async {
    final prefs = await _getInstance;
    return await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await _getInstance;
    return prefs.getString(key);
  }

  // ==================== INT ====================

  Future<bool> setInt(String key, int value) async {
    final prefs = await _getInstance;
    return await prefs.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final prefs = await _getInstance;
    return prefs.getInt(key);
  }

  // ==================== DOUBLE ====================

  Future<bool> setDouble(String key, double value) async {
    final prefs = await _getInstance;
    return await prefs.setDouble(key, value);
  }

  Future<double?> getDouble(String key) async {
    final prefs = await _getInstance;
    return prefs.getDouble(key);
  }

  // ==================== BOOL ====================

  Future<bool> setBool(String key, bool value) async {
    final prefs = await _getInstance;
    return await prefs.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    final prefs = await _getInstance;
    return prefs.getBool(key);
  }

  // ==================== LIST ====================

  Future<bool> setStringList(String key, List<String> value) async {
    final prefs = await _getInstance;
    return await prefs.setStringList(key, value);
  }

  Future<List<String>?> getStringList(String key) async {
    final prefs = await _getInstance;
    return prefs.getStringList(key);
  }

  // ==================== JSON ====================

  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    final prefs = await _getInstance;
    final jsonString = jsonEncode(value);
    return await prefs.setString(key, jsonString);
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final prefs = await _getInstance;
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // ==================== REMOVE & CLEAR ====================

  Future<bool> remove(String key) async {
    final prefs = await _getInstance;
    return await prefs.remove(key);
  }

  Future<bool> clear() async {
    final prefs = await _getInstance;
    return await prefs.clear();
  }

  Future<bool> containsKey(String key) async {
    final prefs = await _getInstance;
    return prefs.containsKey(key);
  }

  // ==================== SPECIFIC APP DATA ====================

  // Keys
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUser = 'user';
  static const String _keyCart = 'cart';
  static const String _keyRecentSearches = 'recent_searches';
  static const String _keyFavorites = 'favorites';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyLastSyncTime = 'last_sync_time';

  // Auth Token
  Future<bool> saveAuthToken(String token) async {
    return await setString(_keyAuthToken, token);
  }

  Future<String?> getAuthToken() async {
    return await getString(_keyAuthToken);
  }

  Future<bool> clearAuthToken() async {
    return await remove(_keyAuthToken);
  }

  // User
  Future<bool> saveUser(User user) async {
    return await setJson(_keyUser, user.toJson());
  }

  Future<User?> getUser() async {
    final json = await getJson(_keyUser);
    if (json == null) return null;
    try {
      return User.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Future<bool> clearUser() async {
    return await remove(_keyUser);
  }

  // Cart (already handled by CartProvider, but kept for reference)
  Future<bool> saveCart(List<Map<String, dynamic>> cart) async {
    final jsonString = jsonEncode(cart);
    return await setString(_keyCart, jsonString);
  }

  Future<List<Map<String, dynamic>>?> getCart() async {
    final jsonString = await getString(_keyCart);
    if (jsonString == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  // Recent Searches
  Future<bool> addRecentSearch(String query) async {
    final searches = await getRecentSearches() ?? [];

    // Remove if already exists
    searches.remove(query);

    // Add to beginning
    searches.insert(0, query);

    // Keep only last 10
    if (searches.length > 10) {
      searches.removeRange(10, searches.length);
    }

    return await setStringList(_keyRecentSearches, searches);
  }

  Future<List<String>?> getRecentSearches() async {
    return await getStringList(_keyRecentSearches);
  }

  Future<bool> clearRecentSearches() async {
    return await remove(_keyRecentSearches);
  }

  // Favorites (Dress IDs)
  Future<bool> addFavorite(int dressId) async {
    final favorites = await getFavorites() ?? [];
    if (!favorites.contains(dressId.toString())) {
      favorites.add(dressId.toString());
      return await setStringList(_keyFavorites, favorites);
    }
    return true;
  }

  Future<bool> removeFavorite(int dressId) async {
    final favorites = await getFavorites() ?? [];
    favorites.remove(dressId.toString());
    return await setStringList(_keyFavorites, favorites);
  }

  Future<List<String>?> getFavorites() async {
    return await getStringList(_keyFavorites);
  }

  Future<bool> isFavorite(int dressId) async {
    final favorites = await getFavorites() ?? [];
    return favorites.contains(dressId.toString());
  }

  // Theme Mode
  Future<bool> setThemeMode(String mode) async {
    return await setString(_keyThemeMode, mode);
  }

  Future<String?> getThemeMode() async {
    return await getString(_keyThemeMode);
  }

  // First Launch
  Future<bool> setFirstLaunchDone() async {
    return await setBool(_keyFirstLaunch, true);
  }

  Future<bool> isFirstLaunch() async {
    final value = await getBool(_keyFirstLaunch);
    return value == null || !value;
  }

  // Last Sync Time
  Future<bool> setLastSyncTime(DateTime time) async {
    return await setString(_keyLastSyncTime, time.toIso8601String());
  }

  Future<DateTime?> getLastSyncTime() async {
    final timeString = await getString(_keyLastSyncTime);
    if (timeString == null) return null;
    try {
      return DateTime.parse(timeString);
    } catch (e) {
      return null;
    }
  }

  // Clear All App Data
  Future<bool> clearAllAppData() async {
    await clearAuthToken();
    await clearUser();
    await remove(_keyCart);
    await clearRecentSearches();
    await remove(_keyFavorites);
    return true;
  }

  // Get all keys
  Future<Set<String>> getAllKeys() async {
    final prefs = await _getInstance;
    return prefs.getKeys();
  }
}