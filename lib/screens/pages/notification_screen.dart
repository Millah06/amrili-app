import 'package:everywhere/constraints/app_theme.dart';
import 'package:everywhere/models/notification_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatelessWidget {
  final RemoteMessage? message;

  const NotificationScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.primaryDark,
        actions: [
          ValueListenableBuilder(
            valueListenable:
                Hive.box<AppNotification>('notifications').listenable(),
            builder: (_, Box<AppNotification> box, __) {
              if (box.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Clear all',
                icon: const Icon(Icons.delete_sweep_outlined,
                    color: AppTheme.textPrimary),
                onPressed: () => _confirmClearAll(context, box),
              );
            },
          ),
        ],
      ),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: ValueListenableBuilder(
        valueListenable:
            Hive.box<AppNotification>('notifications').listenable(),
        builder: (context, Box<AppNotification> box, _) {
          if (box.isEmpty) {
            return _EmptyState();
          }

          // Newest first, with original key index for dismissal.
          final indexed = box.values
              .toList()
              .asMap()
              .entries
              .map((e) => (key: e.key, notif: e.value))
              .toList()
              .reversed
              .toList();

          final grouped = _groupByDate(indexed);

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            itemCount: _flatCount(grouped),
            itemBuilder: (context, i) {
              final item = _itemAt(grouped, i);
              if (item is String) {
                return _SectionHeader(label: item);
              }
              final entry = item as ({int key, AppNotification notif});
              return _NotifTile(
                notif: entry.notif,
                boxKey: entry.key,
                box: box,
              );
            },
          );
        },
      ),
      ),
    ),
    );
  }

  // Groups flat list into Today / Yesterday / Earlier sections.
  List<(String, List<({int key, AppNotification notif})>)> _groupByDate(
      List<({int key, AppNotification notif})> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <({int key, AppNotification notif})>[];
    final yesterdayItems = <({int key, AppNotification notif})>[];
    final earlierItems = <({int key, AppNotification notif})>[];

    for (final item in items) {
      final d = item.notif.receivedAt;
      final day = DateTime(d.year, d.month, d.day);
      if (!day.isBefore(today)) {
        todayItems.add(item);
      } else if (day == yesterday) {
        yesterdayItems.add(item);
      } else {
        earlierItems.add(item);
      }
    }

    return [
      if (todayItems.isNotEmpty) ('Today', todayItems),
      if (yesterdayItems.isNotEmpty) ('Yesterday', yesterdayItems),
      if (earlierItems.isNotEmpty) ('Earlier', earlierItems),
    ];
  }

  // Total item count including section header rows.
  int _flatCount(
      List<(String, List<({int key, AppNotification notif})>)> groups) {
    int count = 0;
    for (final g in groups) {
      count += 1 + g.$2.length; // header + items
    }
    return count;
  }

  // Returns either a String (header label) or a notif entry.
  dynamic _itemAt(
      List<(String, List<({int key, AppNotification notif})>)> groups, int i) {
    int cursor = 0;
    for (final g in groups) {
      if (i == cursor) return g.$1; // section header
      cursor++;
      final offset = i - cursor;
      if (offset < g.$2.length) return g.$2[offset];
      cursor += g.$2.length;
    }
    return null;
  }

  Future<void> _confirmClearAll(
      BuildContext context, Box<AppNotification> box) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Clear all notifications?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok == true) await box.clear();
  }
}

// ── Section header row ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Individual notification tile ──────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  final AppNotification notif;
  final int boxKey;
  final Box<AppNotification> box;

  const _NotifTile({
    required this.notif,
    required this.boxKey,
    required this.box,
  });

  @override
  Widget build(BuildContext context) {
    final isRecent = DateTime.now().difference(notif.receivedAt).inMinutes < 30;

    return Dismissible(
      key: Key('notif-$boxKey-${notif.receivedAt.millisecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: AppTheme.error,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        box.deleteAt(boxKey);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification removed')),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isRecent
              ? AppTheme.primary.withValues(alpha: 0.07)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: isRecent
              ? Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.18), width: 1)
              : null,
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isRecent
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : AppTheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_outlined,
              color:
                  isRecent ? AppTheme.primary : AppTheme.textSecondary,
              size: 20,
            ),
          ),
          title: Text(
            notif.title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: isRecent ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                notif.body,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeago.format(notif.receivedAt),
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          onTap: notif.data.isNotEmpty
              ? () => _showDetails(context, notif)
              : null,
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, AppNotification notif) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notif.title,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(notif.body,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14, height: 1.5)),
            const SizedBox(height: 16),
            ...notif.data.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text('${e.key}: ',
                          style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Expanded(
                        child: Text(
                          '${e.value}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              size: 40,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "We'll let you know when something happens",
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Helper: Format time — kept for any external callers that still use it.
extension TimeFormat on DateTime {
  String formatTime() {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final today = DateTime(now.year, now.month, now.day);

    if (isAfter(today)) {
      return 'Today ${hour > 12 ? hour - 12 : hour}:${minute.toString().padLeft(2, '0')} '
          '${hour >= 12 ? 'PM' : 'AM'}';
    } else if (isAfter(yesterday)) {
      return 'Yesterday ${hour > 12 ? hour - 12 : hour}:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';
    } else {
      return '$day/$month ${hour > 12 ? hour - 12 : hour}:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';
    }
  }
}
