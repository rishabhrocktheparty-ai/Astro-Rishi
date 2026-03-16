import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class KundaliProvider extends ChangeNotifier {
  Kundali? _currentKundali;
  List<Map<String, dynamic>> _kundaliList = [];
  bool _isLoading = false;
  String? _error;

  Kundali? get currentKundali => _currentKundali;
  List<Map<String, dynamic>> get kundaliList => _kundaliList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<Kundali?> generateKundali(BirthData data) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.generateKundali(data.toJson());
      _currentKundali = Kundali.fromApiResponse(res);
      _isLoading = false; notifyListeners();
      return _currentKundali;
    } catch (e) {
      _error = e.toString(); _isLoading = false; notifyListeners();
      return null;
    }
  }

  Future<void> loadKundaliList() async {
    _isLoading = true; notifyListeners();
    try {
      final res = await ApiService.listKundalis();
      _kundaliList = List<Map<String, dynamic>>.from(res['kundalis'] ?? []);
      _isLoading = false; notifyListeners();
    } catch (e) {
      _error = e.toString(); _isLoading = false; notifyListeners();
    }
  }

  Future<Kundali?> loadKundali(String id) async {
    _isLoading = true; notifyListeners();
    try {
      final res = await ApiService.getKundali(id);
      _currentKundali = Kundali.fromApiResponse(res['kundali']);
      _isLoading = false; notifyListeners();
      return _currentKundali;
    } catch (e) {
      _error = e.toString(); _isLoading = false; notifyListeners();
      return null;
    }
  }

  void setCurrentKundali(Kundali k) {
    _currentKundali = k;
    notifyListeners();
  }
}
