// lib/features/marketPlace/models/merchant_trust_model.dart
//
// PHASE 4 — Merchant Trust System (Flutter model)
// Mirrors the JSON returned by GET /vendor/trust/status (serializeProfile in
// trust.controller.ts). Kept as a SEPARATE model — VendorModel is untouched — so
// adding trust does not risk the existing vendor deserialization.
// ─────────────────────────────────────────────────────────────────────────────

class TrustStats {
  final int totalCompletedOrders;
  final int totalOrders;
  final int appealedOrders;
  final double disputeRatePercent;
  final int accountAgeDays;

  const TrustStats({
    required this.totalCompletedOrders,
    required this.totalOrders,
    required this.appealedOrders,
    required this.disputeRatePercent,
    required this.accountAgeDays,
  });

  factory TrustStats.fromJson(Map<String, dynamic> j) => TrustStats(
    totalCompletedOrders: (j['totalCompletedOrders'] ?? 0) as int,
    totalOrders: (j['totalOrders'] ?? 0) as int,
    appealedOrders: (j['appealedOrders'] ?? 0) as int,
    disputeRatePercent: ((j['disputeRatePercent'] ?? 0) as num).toDouble(),
    accountAgeDays: (j['accountAgeDays'] ?? 0) as int,
  );
}

/// One row in the "what's needed for the next level" checklist.
class TrustRequirement {
  final String key;
  final String label;
  final bool met;
  final num? current;
  final num? target;

  const TrustRequirement({
    required this.key,
    required this.label,
    required this.met,
    this.current,
    this.target,
  });

  factory TrustRequirement.fromJson(Map<String, dynamic> j) => TrustRequirement(
    key: j['key'] as String,
    label: j['label'] as String,
    met: (j['met'] ?? false) as bool,
    current: j['current'] as num?,
    target: j['target'] as num?,
  );
}

class TrustNextLevel {
  final int level;
  final bool pendingAdminReview;
  final List<TrustRequirement> requirements;

  const TrustNextLevel({
    required this.level,
    required this.pendingAdminReview,
    required this.requirements,
  });

  factory TrustNextLevel.fromJson(Map<String, dynamic> j) => TrustNextLevel(
    level: (j['level'] ?? 0) as int,
    pendingAdminReview: (j['pendingAdminReview'] ?? false) as bool,
    requirements: ((j['requirements'] as List?) ?? [])
        .map((r) => TrustRequirement.fromJson(Map<String, dynamic>.from(r)))
        .toList(),
  );

  /// Fraction (0..1) of requirements met — drives the progress ring.
  double get progress {
    if (requirements.isEmpty) return 0;
    final met = requirements.where((r) => r.met).length;
    return met / requirements.length;
  }
}

/// One level in the full 0→3 catalog (from `levels` in /vendor/trust/status).
/// Drives the level-comparison UI. All copy/numbers come from the backend —
/// the app hardcodes nothing about levels, so admin edits flow straight through.
class TrustLevelInfo {
  final int level;
  final String label;
  final String tagline;
  final String settlementLabel;
  final String dailyLimitLabel;
  final bool canSell;
  final List<TrustRequirement> requirements;
  final List<String> benefits;

  const TrustLevelInfo({
    required this.level,
    required this.label,
    required this.tagline,
    required this.settlementLabel,
    required this.dailyLimitLabel,
    required this.canSell,
    required this.requirements,
    required this.benefits,
  });

  factory TrustLevelInfo.fromJson(Map<String, dynamic> j) => TrustLevelInfo(
    level: (j['level'] ?? 0) as int,
    label: (j['label'] ?? '') as String,
    tagline: (j['tagline'] ?? '') as String,
    settlementLabel: (j['settlementLabel'] ?? '—') as String,
    dailyLimitLabel: (j['dailyLimitLabel'] ?? '—') as String,
    canSell: (j['canSell'] ?? false) as bool,
    requirements: ((j['requirements'] as List?) ?? [])
        .map((r) => TrustRequirement.fromJson(Map<String, dynamic>.from(r)))
        .toList(),
    benefits: ((j['benefits'] as List?) ?? [])
        .map((b) => b.toString())
        .toList(),
  );
}

class MerchantTrustModel {
  final int level;
  final String levelLabel;
  final bool canSell;
  final int settlementDelayHours;
  final double dailyWithdrawalLimit;
  final bool dailyWithdrawalUnlimited;

  final bool identityVerified;
  final bool faceVerified;
  final bool phoneVerified;
  final bool cacVerified;
  final bool hasCacDocument;
  final bool verificationFeePaid;
  final bool adminApproved;
  final String? adminReviewNote;
  final String? identityDocumentUrl;
  final int verificationFee;

  final TrustStats stats;
  final TrustNextLevel? nextLevel;

  /// Full 0→3 catalog for the comparison UI (backend-driven, never hardcoded).
  final List<TrustLevelInfo> levels;

  const MerchantTrustModel({
    required this.level,
    required this.levelLabel,
    required this.canSell,
    required this.settlementDelayHours,
    required this.dailyWithdrawalLimit,
    required this.dailyWithdrawalUnlimited,
    required this.identityVerified,
    required this.faceVerified,
    required this.phoneVerified,
    required this.cacVerified,
    required this.hasCacDocument,
    required this.verificationFeePaid,
    required this.adminApproved,
    required this.adminReviewNote,
    required this.identityDocumentUrl,
    required this.verificationFee,
    required this.stats,
    required this.nextLevel,
    required this.levels,
  });

  factory MerchantTrustModel.fromJson(Map<String, dynamic> j) =>
      MerchantTrustModel(
        level: (j['level'] ?? 0) as int,
        levelLabel: (j['levelLabel'] ?? 'Unverified') as String,
        canSell: (j['canSell'] ?? false) as bool,
        settlementDelayHours: (j['settlementDelayHours'] ?? 48) as int,
        dailyWithdrawalLimit:
        ((j['dailyWithdrawalLimit'] ?? 0) as num).toDouble(),
        dailyWithdrawalUnlimited:
        (j['dailyWithdrawalUnlimited'] ?? false) as bool,
        identityVerified: (j['identityVerified'] ?? false) as bool,
        faceVerified: (j['faceVerified'] ?? false) as bool,
        phoneVerified: (j['phoneVerified'] ?? false) as bool,
        cacVerified: (j['cacVerified'] ?? false) as bool,
        hasCacDocument: (j['hasCacDocument'] ?? false) as bool,
        verificationFeePaid: (j['verificationFeePaid'] ?? false) as bool,
        adminApproved: (j['adminApproved'] ?? false) as bool,
        adminReviewNote: j['adminReviewNote'] as String?,
        identityDocumentUrl: j['identityDocumentUrl'] as String?,
        verificationFee: (j['verificationFee'] ?? 2500) as int,
        stats: TrustStats.fromJson(
            Map<String, dynamic>.from(j['stats'] ?? const {})),
        nextLevel: j['nextLevel'] != null
            ? TrustNextLevel.fromJson(Map<String, dynamic>.from(j['nextLevel']))
            : null,
        levels: ((j['levels'] as List?) ?? [])
            .map((l) => TrustLevelInfo.fromJson(Map<String, dynamic>.from(l)))
            .toList(),
      );

  bool get isPendingReview => nextLevel?.pendingAdminReview ?? false;

  /// Human-readable settlement description for the status card.
  String get settlementLabel =>
      settlementDelayHours <= 0 ? 'Instant' : '${settlementDelayHours}h';

  /// Human-readable daily withdrawal limit.
  String get dailyLimitLabel => dailyWithdrawalUnlimited
      ? 'Unlimited'
      : '₦${_thousands(dailyWithdrawalLimit)}';

  static String _thousands(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}