import 'json_helpers.dart';

enum ReminderFrequency { daily, weekly }

class ReminderSchedule {
  const ReminderSchedule({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    required this.frequency,
    required this.weekdays,
    this.enabled = true,
  });

  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final ReminderFrequency frequency;
  final List<int> weekdays;
  final bool enabled;

  ReminderSchedule copyWith({
    String? title,
    String? body,
    int? hour,
    int? minute,
    ReminderFrequency? frequency,
    List<int>? weekdays,
    bool? enabled,
  }) {
    return ReminderSchedule(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      frequency: frequency ?? this.frequency,
      weekdays: weekdays ?? this.weekdays,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'hour': hour,
    'minute': minute,
    'frequency': frequency.name,
    'weekdays': weekdays,
    'enabled': enabled,
  };

  factory ReminderSchedule.fromJson(Map<String, dynamic> json) {
    return ReminderSchedule(
      id: readInt(json['id'], fallback: DateTime.now().millisecondsSinceEpoch),
      title: readString(json['title'], fallback: 'Pengingat'),
      body: readString(json['body'], fallback: 'Saatnya melihat catatanmu.'),
      hour: clampInt(readInt(json['hour'], fallback: 8), 0, 23),
      minute: clampInt(readInt(json['minute']), 0, 59),
      frequency: readEnum(
        ReminderFrequency.values,
        json['frequency'],
        ReminderFrequency.daily,
      ),
      weekdays: readIntList(
        json['weekdays'],
      ).where((item) => item >= 1 && item <= 7).toList(growable: false),
      enabled: readBool(json['enabled'], fallback: true),
    );
  }
}
