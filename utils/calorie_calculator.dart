class CalorieCalculator {
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    if (gender == 'male') {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
  }

  static double calculateTDEE(double bmr, String activityLevel) {
    const multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    };
    return bmr * (multipliers[activityLevel] ?? 1.2);
  }

  static double adjustForGoal(double tdee, String goal) {
    switch (goal) {
      case 'lose_fat':
        return tdee - 500;
      case 'gain_muscle':
        return tdee + 300;
      default:
        return tdee;
    }
  }

  static Map<String, double> calculateMacros(double calories, String goal) {
    double proteinPct, carbsPct, fatPct;
    switch (goal) {
      case 'lose_fat':
        proteinPct = 0.40;
        carbsPct = 0.30;
        fatPct = 0.30;
        break;
      case 'gain_muscle':
        proteinPct = 0.35;
        carbsPct = 0.45;
        fatPct = 0.20;
        break;
      default:
        proteinPct = 0.30;
        carbsPct = 0.40;
        fatPct = 0.30;
    }
    return {
      'protein': (calories * proteinPct) / 4,
      'carbs': (calories * carbsPct) / 4,
      'fat': (calories * fatPct) / 9,
    };
  }
}
