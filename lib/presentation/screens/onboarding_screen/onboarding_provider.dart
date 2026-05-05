import 'package:flutter/material.dart';

class OnboardingProvider with ChangeNotifier {
  var _Index = 0;
  final List<Map<String, String>> pages = [
    {
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuATfTyRWucWev049SrseIVo05sz2KFbL4LfuvuM55jmd6vK9RIeMiIjWlzvQJ4uRBXGrxDV9aCHmRm5uTbIXT_0MAk_qi_7hXJoIG3JzzQpt2EwsF-wayceXDjWRD7ODZ0MJrYw9kGMB20MmIrfXe6-QuQpnlobtN1VZ9YZDwmpILC-WcAZ1XgEOR6ASzs4gvKZJUSGOVa_fXf8ikeCJa_nWjXNUkcOvI3UCtyg4cJj4Qu6Q-T8YtHRKReBj7IWWTvmwxmcAEwxYfOE',

      'title': 'Tap. Verify. Done.',

      'subtitle':
          'Instantly log your visits using NFC tags or QR codes at the location. Honest data, entered effortlessly.',
    },

    {
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBj7rVd6KX8EtsJ0Y_II0I0hqdumaDdRqz_FlQogGp3zz0gX546Dnur_O3EYuxi18_RIsl7j0AQtFMX7wwVQ2WMKF0WhHr-j6iedwPS-SIsj5yDbzi0N87iThF7Pb7CD_fxdNrv4pgr9g9bOHWI0YYXM15vDQQaBDzDxNU1Xh6MS7WvbV9Tv6jcYULxi7D3NMjAF_tRd2WFPl4p91t3rVcuqxd3gjQVPM2iLd-63l0XgulJTFwfsoWXsYYj2Y7CYoW6EYSbCUJiUUyD',

      'title': 'Know Every Visit, Every Time.',

      'subtitle':
          'Automatic background tracking ensures your territory visits are accurately logged without manual entry.',
    },
  ];

  int get currentIndex => _Index;

  void updateIndex(int index) {
    _Index = index;
    notifyListeners();
  }
}
