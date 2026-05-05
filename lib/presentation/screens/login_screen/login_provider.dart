import 'package:flutter/material.dart';

class LoginProvider with ChangeNotifier {
  var _hidePassward = true;

  bool get hidePassward => _hidePassward;

  void showPassward() {
    if (_hidePassward == true) {
      _hidePassward = false;
    } else {
      _hidePassward = true;
    }
    notifyListeners();
  }
}
