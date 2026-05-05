// lib/models/user_profile.dart

class UserProfile {
  final String name;
  final double weightKg;
  final double heightCm;
  final int age;
  final String gender;
  final String activityLevel;
  final String goal;
  final double dailyCalories;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;

  UserProfile({
    required this.name,
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.gender,
    required this.activityLevel,
    required this.goal,
    required this.dailyCalories,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'age': age,
        'gender': gender,
        'activityLevel': activityLevel,
        'goal': goal,
        'dailyCalories': dailyCalories,
        'proteinTarget': proteinTarget,
        'carbsTarget': carbsTarget,
        'fatTarget': fatTarget,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name'],
        weightKg: j['weightKg'],
        heightCm: j['heightCm'],
        age: j['age'],
        gender: j['gender'],
        activityLevel: j['activityLevel'],
        goal: j['goal'],
        dailyCalories: j['dailyCalories'],
        proteinTarget: j['proteinTarget'],
        carbsTarget: j['carbsTarget'],
        fatTarget: j['fatTarget'],
      );
}
