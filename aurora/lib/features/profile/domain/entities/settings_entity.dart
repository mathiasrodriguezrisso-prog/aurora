/// 📁 lib/features/profile/domain/entities/settings_entity.dart
/// Entidad para representar las preferencias del usuario.
library;

class SettingsEntity {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool darkMode;
  final String measurementUnit;

  const SettingsEntity({
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.darkMode = true,
    this.measurementUnit = 'metric',
  });

  SettingsEntity copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? darkMode,
    String? measurementUnit,
  }) {
    return SettingsEntity(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      darkMode: darkMode ?? this.darkMode,
      measurementUnit: measurementUnit ?? this.measurementUnit,
    );
  }

  factory SettingsEntity.fromJson(Map<String, dynamic> json) {
    return SettingsEntity(
      pushNotifications: json['push_notifications'] ?? true,
      emailNotifications: json['email_notifications'] ?? false,
      darkMode: json['dark_mode'] ?? true,
      measurementUnit: json['measurement_unit'] ?? 'metric',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push_notifications': pushNotifications,
      'email_notifications': emailNotifications,
      'dark_mode': darkMode,
      'measurement_unit': measurementUnit,
    };
  }
}
