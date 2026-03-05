import 'package:hive/hive.dart';

/// Manual TypeAdapter for UserProfile — avoids build_runner code generation.
/// Field indices:
///   0 = age
///   1 = isDarkMode
///   2 = periodLength             (absent in old records → default 5)
///   3 = cycleLength              (absent in old records → default 28)
///   4 = hasCompletedOnboarding   (absent in old records → false)
///   5 = name                     (absent in old records → null)
///   6 = weightKg                 (absent in old records → null)
///   7 = heightCm                 (absent in old records → null)
///   8 = avatarIndex              (absent in old records → 0)
///   9 = notificationsEnabled     (absent in old records → true)
///  10 = photoPath                (absent in old records → null)
class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 1;

  @override
  UserProfile read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return UserProfile(
      age: fields[0] as int?,
      isDarkMode: fields[1] as bool? ?? false,
      periodLength: fields[2] as int? ?? 5,
      cycleLength: fields[3] as int? ?? 28,
      hasCompletedOnboarding: fields[4] as bool? ?? false,
      name: fields[5] as String?,
      weightKg: fields[6] as double?,
      heightCm: fields[7] as double?,
      avatarIndex: fields[8] as int? ?? 0,
      notificationsEnabled: fields[9] as bool? ?? true,
      photoPath: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeByte(11);
    writer.writeByte(0);
    writer.write(obj.age);
    writer.writeByte(1);
    writer.write(obj.isDarkMode);
    writer.writeByte(2);
    writer.write(obj.periodLength);
    writer.writeByte(3);
    writer.write(obj.cycleLength);
    writer.writeByte(4);
    writer.write(obj.hasCompletedOnboarding);
    writer.writeByte(5);
    writer.write(obj.name);
    writer.writeByte(6);
    writer.write(obj.weightKg);
    writer.writeByte(7);
    writer.write(obj.heightCm);
    writer.writeByte(8);
    writer.write(obj.avatarIndex);
    writer.writeByte(9);
    writer.write(obj.notificationsEnabled);
    writer.writeByte(10);
    writer.write(obj.photoPath);
  }
}

class UserProfile {
  final int? age;
  final bool isDarkMode;
  final int periodLength;
  final int cycleLength;
  final bool hasCompletedOnboarding;
  final String? name;
  final double? weightKg;
  final double? heightCm;
  final int avatarIndex;
  final bool notificationsEnabled;
  final String? photoPath;

  const UserProfile({
    this.age,
    this.isDarkMode = false,
    this.periodLength = 5,
    this.cycleLength = 28,
    this.hasCompletedOnboarding = false,
    this.name,
    this.weightKg,
    this.heightCm,
    this.avatarIndex = 0,
    this.notificationsEnabled = true,
    this.photoPath,
  });

  /// Firestore serialisation
  Map<String, dynamic> toMap() => {
        'age': age,
        'isDarkMode': isDarkMode,
        'periodLength': periodLength,
        'cycleLength': cycleLength,
        'hasCompletedOnboarding': hasCompletedOnboarding,
        'name': name,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'avatarIndex': avatarIndex,
        'notificationsEnabled': notificationsEnabled,
        'photoPath': photoPath,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        age: map['age'] as int?,
        isDarkMode: map['isDarkMode'] as bool? ?? false,
        periodLength: map['periodLength'] as int? ?? 5,
        cycleLength: map['cycleLength'] as int? ?? 28,
        hasCompletedOnboarding:
            map['hasCompletedOnboarding'] as bool? ?? false,
        name: map['name'] as String?,
        weightKg: (map['weightKg'] as num?)?.toDouble(),
        heightCm: (map['heightCm'] as num?)?.toDouble(),
        avatarIndex: map['avatarIndex'] as int? ?? 0,
        notificationsEnabled:
            map['notificationsEnabled'] as bool? ?? true,
        photoPath: map['photoPath'] as String?,
      );

  /// BMI = weight(kg) / height(m)²
  double? get bmi {
    if (weightKg == null || heightCm == null || heightCm! <= 0) return null;
    final heightM = heightCm! / 100.0;
    return weightKg! / (heightM * heightM);
  }

  UserProfile copyWith({
    int? age,
    bool? isDarkMode,
    int? periodLength,
    int? cycleLength,
    bool? hasCompletedOnboarding,
    String? name,
    double? weightKg,
    double? heightCm,
    int? avatarIndex,
    bool? notificationsEnabled,
    String? photoPath,
    bool clearAge = false,
    bool clearName = false,
    bool clearWeight = false,
    bool clearHeight = false,
    bool clearPhoto = false,
  }) {
    return UserProfile(
      age: clearAge ? null : (age ?? this.age),
      isDarkMode: isDarkMode ?? this.isDarkMode,
      periodLength: periodLength ?? this.periodLength,
      cycleLength: cycleLength ?? this.cycleLength,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      name: clearName ? null : (name ?? this.name),
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      heightCm: clearHeight ? null : (heightCm ?? this.heightCm),
      avatarIndex: avatarIndex ?? this.avatarIndex,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    );
  }
}
