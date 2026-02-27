import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

enum IdentityMode { private, ghost, public }

class IdentityProvider extends ChangeNotifier {
  IdentityMode _currentMode = IdentityMode.private;
  bool _isAuthenticated = false; 
  String _username = "PIONEER_01";

  double _tripBudget = 5000.0;
  double _totalSpent = 0.0;
  List<Map<String, dynamic>> _expenses = [];
  List<Contact> _phoneContacts = [];
  List<Map<String, dynamic>> _groups = [];

  IdentityMode get currentMode => _currentMode;
  bool get isAuthenticated => _isAuthenticated;
  String get username => _username;
  double get totalSpent => _totalSpent;
  double get remainingBudget => _tripBudget - _totalSpent;
  List<Map<String, dynamic>> get expenses => _expenses;
  List<Contact> get phoneContacts => _phoneContacts;
  List<Map<String, dynamic>> get groups => _groups;

  IdentityProvider() { _loadSavedName(); }

  Color get themeColor {
    switch (_currentMode) {
      case IdentityMode.private: return const Color(0xFF001F3F);
      case IdentityMode.ghost: return const Color(0xFF0A0A0A);
      case IdentityMode.public: return const Color(0xFFD4AF37);
    }
  }

  Future<void> syncContacts() async {
    PermissionStatus status = await Permission.contacts.status;
    if (status.isDenied) status = await Permission.contacts.request();
    if (status.isGranted) {
      Iterable<Contact> contacts = await ContactsService.getContacts(withThumbnails: false);
      _phoneContacts = contacts.where((c) => c.displayName != null).toList();
      notifyListeners();
    }
  }

  void createGroup(String name, List<String> memberNames) {
    _groups.insert(0, {
      'id': DateTime.now().toString(),
      'name': name.toUpperCase(),
      'members': memberNames.length,
      'lastMsg': 'Started with ${memberNames.length} friends',
    });
    notifyListeners();
  }

  void addExpense(String desc, double amount) {
    _expenses.insert(0, {'desc': desc, 'amount': amount, 'time': DateTime.now()});
    _totalSpent += amount;
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  void setMode(IdentityMode mode) {
    _currentMode = mode;
    if (mode == IdentityMode.private) _isAuthenticated = false;
    notifyListeners();
  }

  void simulateAuthentication() { _isAuthenticated = true; notifyListeners(); }

  Future<void> _loadSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('orb_username') ?? "PIONEER_01";
    notifyListeners();
  }

  Future<void> updateUsername(String newName) async {
    if (newName.isNotEmpty) {
      _username = newName.toUpperCase();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('orb_username', _username);
      notifyListeners();
    }
  }
}