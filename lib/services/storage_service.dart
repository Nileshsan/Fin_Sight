import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUser = 'user_data';
  static const String _keyTheme = 'theme_mode';
  static const String _keyLanguage = 'language';
  static const String _keyFirstRun = 'first_run';

  late final SharedPreferences _prefs;

  StorageService._();

  static final StorageService _instance = StorageService._();

  factory StorageService() {
    return _instance;
  }

  static StorageService get instance => _instance;

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ============ Token Management ============

  /// Save access token
  Future<bool> setAccessToken(String token) async {
    return await _prefs.setString(_keyAccessToken, token);
  }

  /// Get access token
  String? getAccessToken() {
    return _prefs.getString(_keyAccessToken);
  }

  /// Save refresh token
  Future<bool> setRefreshToken(String token) async {
    return await _prefs.setString(_keyRefreshToken, token);
  }

  /// Get refresh token
  String? getRefreshToken() {
    return _prefs.getString(_keyRefreshToken);
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return getAccessToken() != null && getAccessToken()!.isNotEmpty;
  }

  /// Clear tokens
  Future<bool> clearTokens() async {
    await _prefs.remove(_keyAccessToken);
    return await _prefs.remove(_keyRefreshToken);
  }

  // ============ User Data ============

  /// Save user data
  Future<bool> setUserData(String userData) async {
    return await _prefs.setString(_keyUser, userData);
  }

  /// Get user data
  String? getUserData() {
    return _prefs.getString(_keyUser);
  }

  /// Clear user data
  Future<bool> clearUserData() async {
    return await _prefs.remove(_keyUser);
  }

  // ============ Theme Management ============

  /// Save theme preference
  Future<bool> setThemeMode(String mode) async {
    return await _prefs.setString(_keyTheme, mode);
  }

  /// Get theme mode
  String? getThemeMode() {
    return _prefs.getString(_keyTheme);
  }

  // ============ Language Management ============

  /// Save language preference
  Future<bool> setLanguage(String language) async {
    return await _prefs.setString(_keyLanguage, language);
  }

  /// Get language
  String? getLanguage() {
    return _prefs.getString(_keyLanguage);
  }

  // ============ First Run ============

  /// Set first run flag
  Future<bool> setFirstRun(bool value) async {
    return await _prefs.setBool(_keyFirstRun, value);
  }

  /// Check if first run
  bool isFirstRun() {
    return _prefs.getBool(_keyFirstRun) ?? true;
  }

  // ============ Generic Methods ============

  /// Save string value
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  /// Get string value
  String? getString(String key) {
    return _prefs.getString(key);
  }

  /// Save int value
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  /// Get int value
  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  /// Save bool value
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  /// Get bool value
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  /// Save double value
  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  /// Get double value
  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  /// Save list of strings
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  /// Get list of strings
  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  /// Remove value
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  /// Clear all storage
  Future<bool> clear() async {
    return await _prefs.clear();
  }

  /// Check if key exists
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  /// Get all keys
  Set<String> getAllKeys() {
    return _prefs.getKeys();
  }
}
