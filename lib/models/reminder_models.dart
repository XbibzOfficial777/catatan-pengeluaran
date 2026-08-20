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
    final rawFrequency =
        json['frequency'] as String? ?? ReminderFrequency.daily.name;
    final rawWeekdays = json['weekdays'];
    return ReminderSchedule(
      id:
          (json['id'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      title: json['title'] as String? ?? 'Pengingat',
      body: json['body'] as String? ?? 'Saatnya melihat catatanmu.',
      hour: ((json['hour'] as num?)?.toInt() ?? 8).clamp(0, 23),
      minute: ((json['minute'] as num?)?.toInt() ?? 0).clamp(0, 59),
      frequency: ReminderFrequency.values.firstWhere(
        (item) => item.name == rawFrequency,
        orElse: () => ReminderFrequency.daily,
      ),
      weekdays: rawWeekdays is List
          ? rawWeekdays
                .whereType<num>()
                .map((item) => item.toInt())
                .where((item) => item >= 1 && item <= 7)
                .toList()
          : const <int>[],
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
