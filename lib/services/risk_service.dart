import '../models/disease_model.dart';

class RiskService {
  /// Compute percentage-based risk per disease.
  /// Conditions used:
  /// temperature, humidity, and rain only when rainRequired is true.
  ///
  /// Severity:
  /// 100% match = high
  /// 60% or above = medium
  /// below 60% = low
  static List<Disease> compute(
    List<Disease> diseases,
    double? temp,
    int? humidity,
    bool hasRain, {
    String? selectedCrop,
  }) {
    final List<Disease> out = [];

    final List<Disease> listToProcess =
        (selectedCrop != null && selectedCrop.trim().isNotEmpty)
            ? diseases.where((d) {
                final crop = d.crop.toString().toLowerCase().trim();
                final selected = selectedCrop.toLowerCase().trim();

                return crop == selected ||
                    (selected == 'paddy' && crop == 'rice') ||
                    (selected == 'rice' && crop == 'paddy');
              }).toList()
            : diseases;

    for (final d in listToProcess) {
      final Map<String, dynamic> rc = d.riskConditions;

      final double? minT = _toDouble(rc['minTemp']);
      final double? maxT = _toDouble(rc['maxTemp']);
      final int? minH = _toInt(rc['minHumidity']);
      final bool rainReq = rc['rainRequired'] == true;

      int totalConditions = 0;
      int matched = 0;

      if (minT != null && maxT != null && temp != null) {
        totalConditions += 1;

        if (temp >= minT && temp <= maxT) {
          matched += 1;
        }
      }

      if (minH != null && humidity != null) {
        totalConditions += 1;

        if (humidity >= minH) {
          matched += 1;
        }
      }

      if (rainReq) {
        totalConditions += 1;

        if (hasRain) {
          matched += 1;
        }
      }

      final double percent =
          totalConditions > 0 ? matched / totalConditions : 0.0;

      final copy = Disease(
        id: d.id,
        name: d.name,
        crop: d.crop,
        riskConditions: d.riskConditions,
        image: d.image,
      );

      copy.score = matched;

      // Stored as ratio:
      // 1.0 = 100%
      // 0.67 = 67%
      copy.percent = percent;

      if (percent >= 1.0) {
        copy.severity = 'high';
      } else if (percent >= 0.6) {
        copy.severity = 'medium';
      } else {
        copy.severity = 'low';
      }

      out.add(copy);
    }

    out.sort(_riskSorter);

    return out;
  }

  /// Select top N diseases, one per crop.
  ///
  /// Used by home weather risk alert.
  /// Example:
  /// Coconut -> top coconut risk
  /// Tea -> top tea risk
  /// Rice -> top rice risk
  static List<Disease> selectTopPerCrop(
    List<Disease> diseases,
    double? temp,
    int? humidity,
    bool hasRain, {
    List<String>? cropOrder,
    int limit = 3,
  }) {
    final scored = compute(
      diseases,
      temp,
      humidity,
      hasRain,
    );

    final Map<String, List<Disease>> byCrop = {};

    for (final d in scored) {
      final cropKey = _normalizeCrop(d.crop);

      byCrop.putIfAbsent(cropKey, () => []);
      byCrop[cropKey]!.add(d);
    }

    for (final entry in byCrop.entries) {
      entry.value.sort(_riskSorter);
    }

    final List<Disease> result = [];
    final Set<String> takenCrops = {};

    void tryAddForCrop(String cropKey) {
      final key = _normalizeCrop(cropKey);

      if (takenCrops.contains(key)) return;

      final list = byCrop[key];

      if (list != null && list.isNotEmpty) {
        result.add(list.first);
        takenCrops.add(key);
      }
    }

    if (cropOrder != null && cropOrder.isNotEmpty) {
      for (final crop in cropOrder) {
        if (result.length >= limit) break;
        tryAddForCrop(crop);
      }
    }

    if (result.length < limit) {
      final List<Disease> remainingTop = [];

      for (final entry in byCrop.entries) {
        final cropKey = entry.key;

        if (takenCrops.contains(cropKey)) continue;

        if (entry.value.isNotEmpty) {
          remainingTop.add(entry.value.first);
        }
      }

      remainingTop.sort(_riskSorter);

      for (final disease in remainingTop) {
        if (result.length >= limit) break;

        result.add(disease);
        takenCrops.add(_normalizeCrop(disease.crop));
      }
    }

    if (result.length > limit) {
      return result.sublist(0, limit);
    }

    return result;
  }

  /// Return only high and medium risks for notification page.
  static List<Disease> activeAlertsOnly(List<Disease> diseases) {
    final alerts = diseases.where((d) => isMediumOrHigh(d.severity)).toList();

    alerts.sort(_riskSorter);

    return alerts;
  }

  /// For notification: choose the strongest high/medium disease.
  /// Returns null when all risks are low.
  static Disease? topRiskForNotification(List<Disease> diseases) {
    final risky = diseases.where((d) => isMediumOrHigh(d.severity)).toList();

    if (risky.isEmpty) return null;

    risky.sort(_riskSorter);

    return risky.first;
  }

  /// For notification: choose strongest high/medium disease per crop.
  /// This supports sending separate notifications for tea/rice/coconut.
  static List<Disease> topRisksForNotificationPerCrop(
    List<Disease> diseases,
  ) {
    final risky = diseases.where((d) => isMediumOrHigh(d.severity)).toList();

    if (risky.isEmpty) return [];

    final Map<String, List<Disease>> byCrop = {};

    for (final d in risky) {
      final cropKey = _normalizeCrop(d.crop);

      byCrop.putIfAbsent(cropKey, () => []);
      byCrop[cropKey]!.add(d);
    }

    final List<Disease> result = [];

    for (final entry in byCrop.entries) {
      entry.value.sort(_riskSorter);
      result.add(entry.value.first);
    }

    result.sort(_riskSorter);

    return result;
  }

  /// Check whether disease severity should trigger notification.
  static bool isMediumOrHigh(String? severity) {
    final s = (severity ?? '').toLowerCase();

    return s.contains('high') ||
        s.contains('severe') ||
        s.contains('medium') ||
        s.contains('moderate');
  }

  /// Severity ranking helper.
  /// high/severe = 3
  /// medium/moderate = 2
  /// low = 1
  /// unknown = 0
  static int severityRank(String? severity) {
    final s = (severity ?? '').toLowerCase();

    if (s.contains('high') || s.contains('severe')) return 3;
    if (s.contains('medium') || s.contains('moderate')) return 2;
    if (s.contains('low')) return 1;

    return 0;
  }

  /// Human-readable risk title for notification/UI.
  static String displayRiskLevel(String? severity) {
    final s = (severity ?? '').toLowerCase();

    if (s.contains('high') || s.contains('severe')) {
      return 'High disease risk';
    }

    if (s.contains('medium') || s.contains('moderate')) {
      return 'Medium disease risk';
    }

    return 'Low Risk';
  }

  /// Human-readable severity badge.
  static String displaySeverity(String? severity) {
    final s = (severity ?? '').toLowerCase();

    if (s.contains('high') || s.contains('severe')) return 'High';
    if (s.contains('medium') || s.contains('moderate')) return 'Medium';

    return 'Low';
  }

  /// Display risk percent correctly.
  /// Disease.percent is stored as 0.0 - 1.0.
  /// Example:
  /// 1.0 -> 100%
  /// 0.67 -> 67%
  static String displayPercent(Disease disease) {
    final value = disease.percent;

    if (value <= 0) return '0%';

    final percentage = value * 100;

    return '${percentage.toStringAsFixed(0)}%';
  }

  /// Risk sorting.
  /// 1. Severity
  /// 2. Percent
  /// 3. Score
  /// 4. Name
  static int _riskSorter(Disease a, Disease b) {
    final severityCmp = severityRank(b.severity).compareTo(
      severityRank(a.severity),
    );

    if (severityCmp != 0) return severityCmp;

    final percentCmp = b.percent.compareTo(a.percent);
    if (percentCmp != 0) return percentCmp;

    final scoreCmp = b.score.compareTo(a.score);
    if (scoreCmp != 0) return scoreCmp;

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  static String _normalizeCrop(String? crop) {
    final c = (crop ?? 'unknown').toLowerCase().trim();

    if (c == 'paddy') return 'rice';
    if (c == 'rice') return 'rice';
    if (c == 'tea') return 'tea';
    if (c == 'coconut') return 'coconut';

    return c.isEmpty ? 'unknown' : c;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }
}