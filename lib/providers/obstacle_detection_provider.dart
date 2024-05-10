import 'package:flutter/foundation.dart';

class ObstacleDetectionProvider extends ChangeNotifier {
  double maxObstacleProb = 0.0;
  double maxObstacleProbHeight = 0.0;
  double maxObstacleProbWidth = 0.0;
  double maxObstacleProbTop = 0.0;
  double maxObstacleProbLeft = 0.0;
  late String obstacle = "obstacle";

  void updateDetection(
    double maxProb,
    double maxHeight,
    double maxWidth,
    double maxTop,
    double maxLeft,
    String obstacleClass,
  ) {
    maxObstacleProb = maxProb;
    maxObstacleProbHeight = maxHeight;
    maxObstacleProbWidth = maxWidth;
    maxObstacleProbTop = maxTop;
    maxObstacleProbLeft = maxLeft;
    obstacle = obstacleClass;
    notifyListeners(); // Notify listeners when data changes
  }
}