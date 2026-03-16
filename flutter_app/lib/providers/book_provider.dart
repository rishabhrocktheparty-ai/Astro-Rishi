import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class BookProvider extends ChangeNotifier {
  List<Book> _books = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;

  List<Book> get books => _books;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;

  Future<void> loadBooks({String? tradition}) async {
    _isLoading = true; notifyListeners();
    try {
      final res = await ApiService.listBooks(tradition: tradition);
      _books = (res['books'] as List? ?? []).map((b) => Book.fromJson(b)).toList();
    } catch (_) {}
    _isLoading = false; notifyListeners();
  }

  Future<void> loadStats() async {
    try { _stats = await ApiService.getKnowledgeStats(); notifyListeners(); } catch (_) {}
  }
}
