import 'package:flutter/material.dart';

class SignupProvider extends ChangeNotifier {
   var _hidePassward = true;

     bool get hidePassward => _hidePassward;
  Map<String, String> images1 = {
    "+81": "https://wallpapercave.com/wp/wp2190362.png",
    "+91": "http://www.pngmart.com/files/10/Nepal-Flag-PNG-HD.png",
    "+71": "https://st2.depositphotos.com/1797936/8157/i/450/depositphotos_81577286-stock-photo-3d-wavy-flag-illustration-of.jpg",
  };

  String selectedKey = "+81"; // default
  late String defaultImage = images1[selectedKey]!;

  void setSelectedCountry(String key) {
    selectedKey = key;
    defaultImage = images1[key]!;
    notifyListeners();
  }

  String selectedRole = "Admin";

void setRole(String role) {
  selectedRole = role;
  notifyListeners();
}

void showPassward() {
    if (_hidePassward == true) {
      _hidePassward = false;
      notifyListeners();
    } else {
      _hidePassward = true;
      notifyListeners();
    }
  }
}
