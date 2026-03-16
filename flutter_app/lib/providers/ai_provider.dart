import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class AIProvider extends ChangeNotifier {
  String? _conversationId;
  List<AIMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedTradition;

  String? get conversationId => _conversationId;
  List<AIMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedTradition => _selectedTradition;

  void setTradition(String? t) { _selectedTradition = t; notifyListeners(); }

  Future<void> startConversation({String? kundaliId, String? title}) async {
    try {
      final res = await ApiService.createConversation(
        kundaliId: kundaliId, title: title, tradition: _selectedTradition,
      );
      _conversationId = res['conversation']['id'];
      _messages = [];
      notifyListeners();
    } catch (e) {
      _error = e.toString(); notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (_conversationId == null) await startConversation();
    if (_conversationId == null) return;

    _messages.add(AIMessage(id: DateTime.now().toString(), role: 'user', content: text));
    _isLoading = true; _error = null; notifyListeners();

    try {
      final res = await ApiService.sendMessage(_conversationId!, text, tradition: _selectedTradition);
      _messages.add(AIMessage(
        id: res['message_id'] ?? '',
        role: 'assistant',
        content: res['message'] ?? '',
        sources: res['sources'] ?? [],
        traditionUsed: res['tradition_used'],
      ));
      _isLoading = false; notifyListeners();
    } catch (e) {
      _messages.add(AIMessage(id: '', role: 'assistant', content: 'Sorry, an error occurred. Please try again.'));
      _error = e.toString(); _isLoading = false; notifyListeners();
    }
  }

  void clearConversation() {
    _conversationId = null; _messages = []; _error = null; notifyListeners();
  }
}
