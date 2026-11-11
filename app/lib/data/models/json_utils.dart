String asString(dynamic value, [String fallback = '']) =>
    value == null ? fallback : value.toString();

int asInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  return int.tryParse(asString(value)) ?? fallback;
}

double? asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(asString(value));
}

DateTime asUtcDate(dynamic value) =>
    DateTime.tryParse(asString(value))?.toUtc() ?? DateTime.now().toUtc();
