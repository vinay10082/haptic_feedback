import 'package:flutter/foundation.dart';

class ObstacleProvider extends ChangeNotifier {
  bool _obstacleLeft = false;
  bool _obstacleRight = false;

  bool get obstacleLeft => _obstacleLeft;
  bool get obstacleRight => _obstacleRight;

  void updateObstacles(bool left, bool right) {
    _obstacleLeft = left;
    _obstacleRight = right;
    notifyListeners();
  }
}