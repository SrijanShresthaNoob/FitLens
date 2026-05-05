// lib/models/food_entry.dart
import 'package:hive/hive.dart';

part 'food_entry.g.dart';

@HiveType(typeId: 0)
class FoodEntry extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  double calories;
  @HiveField(2)
  double protein;
  @HiveField(3)
  double carbs;
  @HiveField(4)
  double fat;
  @HiveField(5)
  DateTime timestamp;
  @HiveField(6)
  String? imagePath;
  @HiveField(7)
  String? emoji;

  FoodEntry({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.timestamp,
    this.imagePath,
    this.emoji,
  });
}

// After creating this, run:
// flutter pub run build_runner build
