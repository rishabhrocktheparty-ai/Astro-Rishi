import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  UserProfile? _user;
  bool _isLoading = false;
  String? _error;

  UserProfile? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  String? get error => _error;

  Future<bool> checkAuth() async {
    final token = await ApiService.token;
    if (token == null) return false;
    try {
      final res = await ApiService.getProfile();
      _user = UserProfile.fromJson(res['profile']);
      notifyListeners();
      return true;
    } catch (e) {
      await ApiService.setToken(null);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.login(email, password);
      _user = UserProfile.fromJson(res['profile']);
      _isLoading = false; notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString(); _isLoading = false; notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String email, String password, String name) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.signup(email, password, name);
      _user = UserProfile.fromJson(res['profile']);
      _isLoading = false; notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString(); _isLoading = false; notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _user = null; notifyListeners();
  }
}
