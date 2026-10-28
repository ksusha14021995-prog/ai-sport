import 'package:flutter/material.dart';

// Заглушка: реализацию делает CV-спайк (камера + ML Kit + счётчик повторов).
class CameraWorkoutScreen extends StatelessWidget {
  final String exerciseId;

  const CameraWorkoutScreen({super.key, this.exerciseId = 'squat'});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Камера — скоро')));
  }
}
