/// Formatters Library
/// Shared formatting functions

/// Format bytes to human readable size
String formatBytes(int bytes, {int decimals = 2}) {
  if (bytes <= 0) return '0 B';

  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  var i = (Math.log(bytes) / Math.log(1024)).floor();

  return '${(bytes / Math.pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}

/// Format duration
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  } else if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  } else {
    return '${seconds}s';
  }
}

/// Convert duration to readable string
String durationToString(Duration duration) {
  return duration.toString().split('.').first.padLeft(8, '0');
}

/// Parse string to double safely
double? parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (e) {
      return null;
    }
  }
  return null;
}

/// Parse string to int safely
int? parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    try {
      return int.parse(value);
    } catch (e) {
      return null;
    }
  }
  return null;
}

/// Parse string to bool safely
bool? parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  if (value is int) return value != 0;
  return null;
}

/// Safe list casting
List<T>? safeListCast<T>(dynamic value) {
  try {
    if (value is List) {
      return value.cast<T>();
    }
  } catch (e) {
    return null;
  }
  return null;
}

/// Safe map casting
Map<String, T>? safeMapCast<T>(dynamic value) {
  try {
    if (value is Map) {
      return value.cast<String, T>();
    }
  } catch (e) {
    return null;
  }
  return null;
}

class Math {
  static double log(num x) => _log(x);

  static double pow(num x, num y) => x.toDouble().pow(y.toDouble());

  static double _log(num x) {
    return _logWithBase(x, 2.718281828459045); // e
  }

  static double _logWithBase(num x, num base) {
    return (x.toDouble().log() / base.toDouble().log());
  }
}

extension NumExtension on num {
  double log() => _log(toDouble());

  static double _log(double x) {
    if (x <= 0) throw ArgumentError('x must be positive');
    return x / 2.302585092994046; // ln(x) approximation or use dart:math
  }
}
