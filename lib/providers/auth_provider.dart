import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';

class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage =
    const FlutterSecureStorage();

  String? _token;
  String? _userEmail;
  String? _userName;
  bool _isLoading = false;

  String? get token => _token;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    _token = await _storage.read(
      key: AppConstants.tokenKey);
    _userEmail = await _storage.read(
      key: AppConstants.userEmailKey);
    _userName = await _storage.read(
      key: AppConstants.userNameKey);
    notifyListeners();
  }

  Future<void> saveAuth(String token,
      String email, String name) async {
    _token = token;
    _userEmail = email;
    _userName = name;
    await _storage.write(
      key: AppConstants.tokenKey, value: token);
    await _storage.write(
      key: AppConstants.userEmailKey, value: email);
    await _storage.write(
      key: AppConstants.userNameKey, value: name);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _userEmail = null;
    _userName = null;
    await _storage.deleteAll();
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}