import 'package:flutter/material.dart';

class LoginProvider with ChangeNotifier {
  var _hidePassward = true;

  var _authority = 'Manager';

  bool get hidePassward => _hidePassward;

  String get authority => _authority;

  void showPassward() {
    if (_hidePassward == true) {
      _hidePassward = false;
      notifyListeners();
    } else {
      _hidePassward = true;
      notifyListeners();
    }
  }

  void changeManager() {
    _authority = 'Admin';
    notifyListeners();
  }

  void changeAdmin() {
    _authority = 'Manager';
    notifyListeners();
  }
}
