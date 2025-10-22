import 'dart:math';

enum Sex { male, female }

class LMS {
  final double L;
  final double M;
  final double S;
  const LMS(this.L, this.M, this.S);
}

class WhoGrowthService {

  // Height-for-Age (HAZ) LMS by age in months
  static final Map<Sex, Map<int, LMS>> _hfa = {
    Sex.male: {
      0: LMS(1.267004226, 49.8842, 0.053112191),
      12: LMS(0.231547902, 75.7, 0.04090909),
      24: LMS(0.130, 87.1, 0.0400),
      36: LMS(0.090, 95.2, 0.0395),
      48: LMS(0.070, 102.7, 0.0390),
      60: LMS(0.050, 109.2, 0.0385),
    },
    Sex.female: {
      0: LMS(1.236, 49.1477, 0.053),
      12: LMS(0.230, 74.0, 0.0415),
      24: LMS(0.120, 85.7, 0.0405),
      36: LMS(0.090, 94.0, 0.0400),
      48: LMS(0.070, 100.9, 0.0395),
      60: LMS(0.050, 108.4, 0.0390),
    }
  };

  // Weight-for-Age (WAZ) LMS by age in months
  static final Map<Sex, Map<int, LMS>> _wfa = {
    Sex.male: {
      0: LMS(0.3487, 3.3464, 0.14602),
      12: LMS(0.090, 9.6, 0.110),
      24: LMS(0.090, 12.2, 0.100),
      36: LMS(0.080, 14.3, 0.095),
      48: LMS(0.070, 16.3, 0.092),
      60: LMS(0.060, 18.3, 0.090),
    },
    Sex.female: {
      0: LMS(0.3809, 3.2322, 0.14171),
      12: LMS(0.100, 8.9, 0.110),
      24: LMS(0.095, 11.5, 0.102),
      36: LMS(0.085, 13.9, 0.097),
      48: LMS(0.075, 15.9, 0.094),
      60: LMS(0.065, 17.9, 0.092),
    }
  };

  // Weight-for-Height (WHZ) LMS by height in cm
  static final Map<Sex, Map<double, LMS>> _wfh = {
    Sex.male: {
      65.0: LMS(-0.3521, 7.4327, 0.08217),
      80.0: LMS(-0.3521, 10.9, 0.0900),
      95.0: LMS(-0.3521, 14.5, 0.0950),
      110.0: LMS(-0.3521, 18.3, 0.1000),
    },
    Sex.female: {
      65.0: LMS(-0.3833, 7.187, 0.08217),
      80.0: LMS(-0.3833, 10.3, 0.0890),
      95.0: LMS(-0.3833, 13.9, 0.0940),
      110.0: LMS(-0.3833, 17.5, 0.0990),
    }
  };

  static double? _computeZ(LMS lms, double x) {
    final L = lms.L;
    final M = lms.M;
    final S = lms.S;
    if (x <= 0 || M <= 0 || S <= 0) return null;
    if (L == 0) {
      return log(x / M) / S;
    }
    return (pow(x / M, L) - 1) / (L * S);
  }

  static LMS _interpolateLMSDouble(Map<double, LMS> table, double key) {
    if (table.containsKey(key)) return table[key]!;
    final keys = table.keys.toList()..sort((a, b) => a.compareTo(b));
    if (key <= keys.first) return table[keys.first]!;
    if (key >= keys.last) return table[keys.last]!;
    double lower = keys.first;
    double upper = keys.last;
    for (int i = 0; i < keys.length - 1; i++) {
      if (key >= keys[i] && key <= keys[i + 1]) {
        lower = keys[i];
        upper = keys[i + 1];
        break;
      }
    }
    final LMS l = table[lower]!;
    final LMS u = table[upper]!;
    final t = (key - lower) / (upper - lower);
    return LMS(
      l.L + (u.L - l.L) * t,
      l.M + (u.M - l.M) * t,
      l.S + (u.S - l.S) * t,
    );
  }

  static double? hazZ({required int ageMonths, required Sex sex, required double heightCm}) {
    if (ageMonths < 0 || ageMonths > 60) return null;
    final table = _hfa[sex]!
        .map((k, v) => MapEntry(k.toDouble(), v));
    final lms = _interpolateLMSDouble(table, ageMonths.toDouble());
    return _computeZ(lms, heightCm);
  }

  static double? wazZ({required int ageMonths, required Sex sex, required double weightKg}) {
    if (ageMonths < 0 || ageMonths > 60) return null;
    final table = _wfa[sex]!
        .map((k, v) => MapEntry(k.toDouble(), v));
    final lms = _interpolateLMSDouble(table, ageMonths.toDouble());
    return _computeZ(lms, weightKg);
  }

  static double? whzZ({required double heightCm, required Sex sex, required double weightKg}) {
    if (heightCm < 45 || heightCm > 120) return null;
    final table = _wfh[sex]!;
    final lms = _interpolateLMSDouble(table, heightCm);
    return _computeZ(lms, weightKg);
  }
}
