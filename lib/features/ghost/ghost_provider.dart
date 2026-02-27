import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

enum GhostStyle { robotic, poetic, formal }

class GhostProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _apiKey = "AIzaSyDFA9xK_k5AaOYyCkeOaSoXFr9vIZk4deM"; 

  GhostStyle _currentStyle = GhostStyle.robotic;
  GhostStyle get currentStyle => _currentStyle;
  bool _isGhosting = false;
  bool get isGhosting => _isGhosting;

  void setStyle(GhostStyle style) { _currentStyle = style; notifyListeners(); }

  Future<Map<String, dynamic>?> parseExpense(String input) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      final prompt = "Extract expense. Return JSON: {'description': string, 'amount': double}. Input: '$input'";
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(text!) as Map<String, dynamic>;
    } catch (e) { return null; }
  }

  Future<void> postGhostMessage(String originalText) async {
    if (originalText.isEmpty) return;
    _isGhosting = true;
    notifyListeners();
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      final prompt = "Rewrite to be anonymous and ${_currentStyle.name}: $originalText";
      final response = await model.generateContent([Content.text(prompt)]);
      await _db.collection('ghost_threads').add({
        'content': response.text ?? originalText,
        'style': _currentStyle.name,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } finally { _isGhosting = false; notifyListeners(); }
  }
}