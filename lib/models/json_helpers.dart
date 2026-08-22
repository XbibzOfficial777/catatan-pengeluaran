DateTime readDate(dynamic value, {DateTime? fallback}) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed ?? fallback ?? DateTime.now();
}

DateTime? readNullableDate(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

String readString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final raw = value.toString();
  return raw.isEmpty ? fallback : raw;
}

String? readNullableString(dynamic value) {
  if (value == null) return null;
  final raw = value.toString();
  return raw.trim().isEmpty ? null : raw;
}

double readDouble(dynamic value, {double fallback = 0}) {
  if (value is num && value.isFinite) return value.toDouble();
  final parsed = double.tryParse(value?.toString().trim() ?? '');
  return parsed != null && parsed.isFinite ? parsed : fallback;
}

int readInt(dynamic value, {int fallback = 0}) {
  if (value is num && value.isFinite) return value.toInt();
  final parsed = int.tryParse(value?.toString().trim() ?? '');
  return parsed ?? fallback;
}

bool readBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  switch (value?.toString().trim().toLowerCase()) {
    case 'true':
    case '1':
    case 'yes':
    case 'y':
      return true;
    case 'false':
    case '0':
    case 'no':
    case 'n':
      return false;
    default:
      return fallback;
  }
}

T readEnum<T extends Enum>(Iterable<T> values, dynamic value, T fallback) {
  final raw = value?.toString().trim().toLowerCase();
  if (raw == null || raw.isEmpty) return fallback;
  for (final item in values) {
    if (item.name.toLowerCase() == raw) return item;
  }
  return fallback;
}

List<String> readStringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<T> readList<T>(dynamic value, T Function(Map<String, dynamic>) parser) {
  if (value is! List) return <T>[];
  final results = <T>[];
  for (final item in value) {
    if (item is! Map) continue;
    try {
      results.add(parser(Map<String, dynamic>.from(item)));
    } catch (_) {
      // Ignore only the malformed child; preserve all valid siblings.
    }
  }
  return results;
}

List<int> readIntList(dynamic value) {
  if (value is! List) return const <int>[];
  return value
      .map<int?>((item) {
        if (item is num && item.isFinite) return item.toInt();
        return int.tryParse(item?.toString().trim() ?? '');
      })
      .whereType<int>()
      .toList(growable: false);
}

int clampInt(int value, int min, int max) => value.clamp(min, max).toInt();

double clampProgress(double value) {
  if (!value.isFinite) return 0;
  return value.clamp(0.0, 1.0).toDouble();
}

double roundMoney(double value, {int fractionDigits = 2}) {
  if (!value.isFinite) return 0;
  final factor = _pow10(fractionDigits);
  return (value * factor).roundToDouble() / factor;
}

int _pow10(int digits) {
  var result = 1;
  for (var index = 0; index < digits; index++) {
    result *= 10;
  }
  return result;
}
