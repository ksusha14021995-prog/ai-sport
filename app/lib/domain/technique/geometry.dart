import 'dart:math' as math;

import 'pose_frame.dart';

/// Угол в вершине [vertex] между лучами vertex→a и vertex→c, в градусах 0..180.
/// Для колена: a = бедро, vertex = колено, c = лодыжка.
double jointAngleDegrees(Landmark a, Landmark vertex, Landmark c) {
  final abX = a.x - vertex.x;
  final abY = a.y - vertex.y;
  final cbX = c.x - vertex.x;
  final cbY = c.y - vertex.y;
  final lengths =
      math.sqrt(abX * abX + abY * abY) * math.sqrt(cbX * cbX + cbY * cbY);
  if (lengths == 0) return double.nan;
  final cosine = ((abX * cbX + abY * cbY) / lengths).clamp(-1.0, 1.0);
  return math.acos(cosine) * 180 / math.pi;
}

double distance(Landmark a, Landmark b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}

Landmark midpoint(Landmark a, Landmark b) => Landmark(
  (a.x + b.x) / 2,
  (a.y + b.y) / 2,
  likelihood: math.min(a.likelihood, b.likelihood),
);
