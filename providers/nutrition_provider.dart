// lib/providers/nutrition_provider.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_entry.dart';

class NutritionProvider extends ChangeNotifier {
  late Box<FoodEntry> _box;

  List<FoodEntry> get todayEntries {
    final today = DateTime.now();
    return _box.values
        .where((e) =>
            e.timestamp.year == today.year &&
            e.timestamp.month == today.month &&
            e.timestamp.day == today.day)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // ── ADD THIS ──────────────────────────────────────────────
  List<FoodEntry> get allEntries {
    return _box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  // ─────────────────────────────────────────────────────────

  double get totalCalories => todayEntries.fold(0, (s, e) => s + e.calories);
  double get totalProtein => todayEntries.fold(0, (s, e) => s + e.protein);
  double get totalCarbs => todayEntries.fold(0, (s, e) => s + e.carbs);
  double get totalFat => todayEntries.fold(0, (s, e) => s + e.fat);

  Future<void> init() async {
    _box = await Hive.openBox<FoodEntry>('food_entries');
    notifyListeners();
  }

  Future<void> addEntry(FoodEntry entry) async {
    await _box.add(entry);
    notifyListeners();
  }

  Future<void> removeEntry(FoodEntry entry) async {
    await entry.delete();
    notifyListeners();
  }
}
