import 'package:flutter/foundation.dart';


class ObjectDistanceModel extends ChangeNotifier {
  List<dynamic>? recognitions;
  double? distance;

  void setRecognitions(List<dynamic>? recog) {
    recognitions = recog;
    if (recog != null && recog.isNotEmpty) {
      distance = recog[0]['distance'];
    } else {
      distance = null;
    }
    notifyListeners();
  }
}