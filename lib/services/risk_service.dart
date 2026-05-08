import '../models/disease_model.dart';

class RiskService {
  /// Weather risk calculate කරන main function එක.
  ///
  /// rainRequired = true නම්:
  ///   temperature + humidity + rain = 3 conditions
  ///
  /// rainRequired = false නම්:
  ///   temperature + humidity = 2 conditions
  ///
  /// Severity:
  ///   100% match       -> high
  ///   60% and above    -> medium
  ///   below 60%        -> low
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
                final crop = _normalizeCrop(d.crop);
                final selected = _normalizeCrop(selectedCrop);
                return crop == selected;
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

      // Temperature condition
      if (minT != null && maxT != null && temp != null) {
        totalConditions++;

        if (temp >= minT && temp <= maxT) {
          matched++;
        }
      }

      // Humidity condition
      if (minH != null && humidity != null) {
        totalConditions++;

        if (humidity >= minH) {
          matched++;
        }
      }

      // Rain condition only when required
      if (rainReq) {
        totalConditions++;

        if (hasRain) {
          matched++;
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

  /// Crop 3කට top risk 3ක් විතරක් return කරන function එක.
  ///
  /// Example:
  ///   Rice    -> best matching rice disease
  ///   Tea     -> best matching tea disease
  ///   Coconut -> best matching coconut disease
  ///
  /// හැම crop එකකටම high/medium නැතත්, best low එකක් හරි return වෙනවා.
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

    // User/home page crop order එක අනුව add කරනවා.
    if (cropOrder != null && cropOrder.isNotEmpty) {
      for (final crop in cropOrder) {
        if (result.length >= limit) break;
        tryAddForCrop(crop);
      }
    }

    // cropOrder එකේ නැති crop තියෙනවා නම් ඒවගෙන් top risks add කරනවා.
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

    result.sort((a, b) {
      final cropCmp = _cropRank(a.crop).compareTo(_cropRank(b.crop));
      if (cropCmp != 0) return cropCmp;
      return _riskSorter(a, b);
    });

    if (result.length > limit) {
      return result.sublist(0, limit);
    }

    return result;
  }

  /// Notification page එකට high සහ medium alerts විතරක් අවශ්‍ය නම් මේක use කරන්න.
  /// නමුත් ඔයාගේ current requirement එකේ low එකත් page එකේ පෙන්වන්න ඕන නම්,
  /// HomePage එකෙන් activeAlertsOnly call කරන්න එපා.
  static List<Disease> activeAlertsOnly(List<Disease> diseases) {
    final alerts = diseases.where((d) => isMediumOrHigh(d.severity)).toList();

    alerts.sort(_riskSorter);

    return alerts;
  }

  /// High/Medium අතරින් strongest එක.
  /// Low විතරක් තියෙනවා නම් null return වෙනවා.
  static Disease? topRiskForNotification(List<Disease> diseases) {
    final risky = diseases.where((d) => isMediumOrHigh(d.severity)).toList();

    if (risky.isEmpty) return null;

    risky.sort(_riskSorter);

    return risky.first;
  }

  /// Phone notification වලට crop එකකට එක high/medium disease එකක් ගන්න.
  /// Low risks notification යවන්නේ නෑ.
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

  static bool isMediumOrHigh(String? severity) {
    final s = (severity ?? '').toLowerCase();

    return s.contains('high') ||
        s.contains('severe') ||
        s.contains('medium') ||
        s.contains('moderate');
  }

  static int severityRank(String? severity) {
    final s = (severity ?? '').toLowerCase();

    if (s.contains('high') || s.contains('severe')) return 3;
    if (s.contains('medium') || s.contains('moderate')) return 2;
    if (s.contains('low')) return 1;

    return 0;
  }

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

  static String displaySeverity(String? severity) {
    final s = (severity ?? '').toLowerCase();

    if (s.contains('high') || s.contains('severe')) return 'High';
    if (s.contains('medium') || s.contains('moderate')) return 'Medium';

    return 'Low';
  }

  /// Disease.percent save වෙන්නේ 0.0 - 1.0 ratio එකක් විදිහට.
  /// 1.0  -> 100%
  /// 0.67 -> 67%
  /// 0.5  -> 50%
  static String displayPercent(Disease disease) {
    final value = disease.percent;

    if (value <= 0) return '0%';

    final percentage = value * 100;

    return '${percentage.toStringAsFixed(0)}%';
  }

  /// Risk order:
  ///   1. High / Medium / Low
  ///   2. Higher percent
  ///   3. Higher matched score
  ///   4. Crop order: Rice, Tea, Coconut
  ///   5. Name
  static int _riskSorter(Disease a, Disease b) {
    final severityCmp = severityRank(b.severity).compareTo(
      severityRank(a.severity),
    );

    if (severityCmp != 0) return severityCmp;

    final percentCmp = b.percent.compareTo(a.percent);
    if (percentCmp != 0) return percentCmp;

    final scoreCmp = b.score.compareTo(a.score);
    if (scoreCmp != 0) return scoreCmp;

    final cropCmp = _cropRank(a.crop).compareTo(_cropRank(b.crop));
    if (cropCmp != 0) return cropCmp;

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  static int _cropRank(String? crop) {
    final c = _normalizeCrop(crop);

    if (c == 'rice') return 1;
    if (c == 'tea') return 2;
    if (c == 'coconut') return 3;

    return 99;
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