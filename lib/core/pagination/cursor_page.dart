// lib/core/pagination/cursor_page.dart
//
// PHASE 8 — Cursor pagination
//
// A tiny, generic wrapper around the backend's paginated envelope:
//
//     { "data": [ ... ], "meta": { "nextCursor": "…"|null, "hasMore": bool } }
//
// Every paginated provider (vendor list, order lists, manager menu) decodes its
// page through this one type so the parsing lives in exactly one place. The
// `nextCursor` is an opaque base64url token produced by the server — the client
// never inspects it, it just echoes it back as `?cursor=` to fetch the next page.
//
// Rollout-safe: if the server ever returns a bare List (the pre-Phase-8 shape),
// `fromJson` still works — it treats it as a single, final page (hasMore=false).
// That means the app won't hard-crash mid-deploy if a stale endpoint slips
// through; it just won't paginate until the new backend is live.

class CursorPage<T> {
  /// The items decoded for this page.
  final List<T> items;

  /// Opaque token for the *next* page, or null when there are no more pages.
  final String? nextCursor;

  /// Whether another page exists after this one.
  final bool hasMore;

  const CursorPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  /// Decode a `{ data, meta }` envelope (or, defensively, a bare list).
  ///
  /// [parse] turns one raw JSON map into a `T` (e.g. `VendorModel.fromJson`).
  factory CursorPage.fromJson(
      dynamic json,
      T Function(Map<String, dynamic>) parse,
      ) {
    // Defensive path: a legacy endpoint returning a plain array.
    if (json is List) {
      return CursorPage<T>(
        items: json
            .whereType<Map<String, dynamic>>()
            .map(parse)
            .toList(growable: false),
        nextCursor: null,
        hasMore: false,
      );
    }

    final map = (json as Map).cast<String, dynamic>();
    final rawData = (map['data'] as List?) ?? const [];
    final meta = (map['meta'] as Map?)?.cast<String, dynamic>() ?? const {};

    return CursorPage<T>(
      items: rawData
          .whereType<Map<String, dynamic>>()
          .map(parse)
          .toList(growable: false),
      nextCursor: meta['nextCursor'] as String?,
      hasMore: (meta['hasMore'] as bool?) ?? false,
    );
  }

  /// Empty first page — handy as an initial value before the first fetch.
  static CursorPage<T> empty<T>() =>
      CursorPage<T>(items: const [], nextCursor: null, hasMore: true);
}