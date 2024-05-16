// To parse this JSON data, do
//
//     final objectParam = objectParamFromJson(jsonString);

import 'dart:convert';
import 'package:flutter/material.dart';

ObjectParam objectParamFromJson(String str) =>
    ObjectParam.fromJson(json.decode(str));

String objectParamToJson(ObjectParam data) => json.encode(data.toJson());

class ObjectParam {
  double maxObstacleProbHeight;
  double maxObstacleProb;
  double maxObstacleProbWidth;
  double maxObstacleProbTop;
  double maxObstacleProbLeft;
  double distance;
  String obstacle;
  Color colorPick;

  ObjectParam({
    this.maxObstacleProb = 0.0,
    this.maxObstacleProbHeight = 0.0,
    this.maxObstacleProbWidth = 0.0,
    this.maxObstacleProbTop = 0.0,
    this.maxObstacleProbLeft = 0.0,
    this.distance = 0.0,
    this.obstacle = 'obstacle',
    this.colorPick = Colors.green,
  });

  factory ObjectParam.fromJson(Map<String, dynamic> json) => ObjectParam(
        maxObstacleProb: json["maxObstacleProb"],
        maxObstacleProbHeight: json["maxObstacleProbHeight"],
        maxObstacleProbWidth: json["maxObstacleProbWidth"],
        maxObstacleProbTop: json["maxObstacleProbTop"],
        maxObstacleProbLeft: json["maxObstacleProbLeft"],
        distance: json['distance'],
        obstacle: json["obstacle"],
        colorPick: json["colorPick"]
      );

  Map<String, dynamic> toJson() => {
        "maxObstacleProb": maxObstacleProb,
        "maxObstacleProbHeight": maxObstacleProbHeight,
        "maxObstacleProbWidth": maxObstacleProbWidth,
        "maxObstacleProbTop": maxObstacleProbTop,
        "maxObstacleProbLeft": maxObstacleProbLeft,
        "distance": distance,
        "obstacle": obstacle,
        "colorPick": colorPick,
      };
}