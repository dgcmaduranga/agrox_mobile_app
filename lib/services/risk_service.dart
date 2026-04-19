import '../models/disease_model.dart';

class RiskService {
  /// Compute percentage-based risk per disease.
  /// For each disease, count applicable conditions (temp/humidity/rain if required),
  /// compute matched conditions and percentage = matched/total.
  /// Severity: 100% -> high, >=0.6 -> medium, else low.
  static List<Disease> compute(List<Disease> diseases, double? temp, int? humidity, bool hasRain, {String? selectedCrop}) {
    final List<Disease> out = [];

    final List<Disease> listToProcess = (selectedCrop != null && selectedCrop.isNotEmpty)
        ? diseases.where((d) => (d.crop ?? '').toLowerCase() == selectedCrop.toLowerCase()).toList()
        : diseases;

    for (var d in listToProcess) {
      final rc = d.riskConditions;
      final minT = (rc['minTemp'] is num) ? (rc['minTemp'] as num).toDouble() : (double.tryParse(rc['minTemp']?.toString() ?? '') ?? double.nan);
      final maxT = (rc['maxTemp'] is num) ? (rc['maxTemp'] as num).toDouble() : (double.tryParse(rc['maxTemp']?.toString() ?? '') ?? double.nan);
      final minH = (rc['minHumidity'] is num) ? (rc['minHumidity'] as num).toInt() : (int.tryParse(rc['minHumidity']?.toString() ?? '') ?? -1);
      final rainReq = rc['rainRequired'] == true;

      int totalConditions = 0;
      int matched = 0;

      if (!minT.isNaN && !maxT.isNaN && temp != null) {
        totalConditions += 1;
        if (temp >= minT && temp <= maxT) matched += 1;
      }

      if (minH >= 0 && humidity != null) {
        totalConditions += 1;
        if (humidity >= minH) matched += 1;
      }

      if (rainReq) {
        totalConditions += 1;
        if (hasRain) matched += 1;
      }

      final copy = Disease(id: d.id, name: d.name, crop: d.crop, riskConditions: d.riskConditions, image: d.image);
      copy.score = matched;
      copy.percent = (totalConditions > 0) ? (matched / totalConditions) : 0.0;
      copy.severity = (copy.percent == 1.0) ? 'high' : ((copy.percent >= 0.6) ? 'medium' : 'low');
      out.add(copy);
    }

    out.sort((a, b) {
      final cmp = b.percent.compareTo(a.percent);
      if (cmp != 0) return cmp;
      return b.score.compareTo(a.score);
    });

    return out;
  }

  /// Select top N diseases, one per crop.
  ///
  /// - `cropOrder` (optional): preferred crop keys (case-insensitive). If provided,
  ///   attempt to pick one disease for each crop in that order.
  /// - If fewer than `limit` crops are available, the remaining slots are filled
  ///   by the highest-ranked diseases from other crops.
  static List<Disease> selectTopPerCrop(List<Disease> diseases, double? temp, int? humidity, bool hasRain, {List<String>? cropOrder, int limit = 3}) {
    // First compute scored list for all diseases
    final scored = compute(diseases, temp, humidity, hasRain);

    // Group by crop (lowercased)
    final Map<String, List<Disease>> byCrop = {};
    for (var d in scored) {
      final cropKey = (d.crop ?? 'unknown').toString().toLowerCase();
      byCrop.putIfAbsent(cropKey, () => []).add(d);
    }

    // Sort each crop group by percent desc, then score desc
    for (var entry in byCrop.entries) {
      entry.value.sort((a, b) {
        final cmp = b.percent.compareTo(a.percent);
        if (cmp != 0) return cmp;
        return b.score.compareTo(a.score);
      });
    }

    final List<Disease> result = [];
    final takenCrops = <String>{};

    // Helper to try add top for a given crop key
    void tryAddForCrop(String cropKey) {
      final k = cropKey.toLowerCase();
      if (takenCrops.contains(k)) return;
      final list = byCrop[k];
      if (list != null && list.isNotEmpty) {
        result.add(list.first);
        takenCrops.add(k);
      }
    }

    // 1) If cropOrder provided, respect it first (case-insensitive)
    if (cropOrder != null && cropOrder.isNotEmpty) {
      for (var c in cropOrder) {
        if (result.length >= limit) break;
        tryAddForCrop(c);
      }
    }

    // 2) Fill remaining slots by selecting the top disease from remaining crops,
    // ordered by their group's top disease percent (desc)
    if (result.length < limit) {
      // Build list of remaining crop top-diseases
      final remainingTop = <Disease>[];
      for (var entry in byCrop.entries) {
        final cropKey = entry.key;
        if (takenCrops.contains(cropKey)) continue;
        final top = entry.value.isNotEmpty ? entry.value.first : null;
        if (top != null) remainingTop.add(top);
      }
      remainingTop.sort((a, b) {
        final cmp = b.percent.compareTo(a.percent);
        if (cmp != 0) return cmp;
        return b.score.compareTo(a.score);
      });

      for (var d in remainingTop) {
        if (result.length >= limit) break;
        result.add(d);
        takenCrops.add((d.crop ?? 'unknown').toLowerCase());
      }
    }

    // Ensure exactly `limit` items (trim if more)
    if (result.length > limit) return result.sublist(0, limit);
    return result;
  }
}
