import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:shimmer/shimmer.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../data/models/notification_models.dart';
import '../../services/api/notifications_api.dart';
import '../../services/session_service.dart';

/// Shared design tokens — same mint/teal palette used across the app.
class _T {
  static const bg = Color(0xFFF6FAF8);
  static const surface = Colors.white;
  static const primary = Color(0xFF3EBE93);
  static const primaryDark = Color(0xFF2FA37D);
  static const primarySoft = Color(0xFFE3F5EE);
  static const textPrimary = Color(0xFF1F2A24);
  static const textSecondary = Color(0xFF8B9892);
  static const textMuted = Color(0xFFB7C0BB);
  static const border = Color(0xFFE7ECE9);

  static const info = Color(0xFF5B8DEF);
  static const success = Color(0xFF3EBE93);
  static const warning = Color(0xFFE0A94A);
  static const error = Color(0xFFE0656B);
}

Color _typeColor(String? type) {
  switch ((type ?? '').toLowerCase()) {
    case 'info':
      return _T.info;
    case 'success':
      return _T.success;
    case 'warning':
      return _T.warning;
    case 'error':
      return _T.error;
    default:
      return _T.textSecondary;
  }
}

/// A single row in the grouped list — either a date-section header
/// ("Today", "Yesterday", "This Week", "Earlier") or a notification.
class _ListRow {
  final String? header;
  final AppNotification? notification;
  const _ListRow.header(this.header) : notification = null;
  const _ListRow.item(this.notification) : header = null;
  bool get isHeader => header != null;
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final SessionService _session = Get.find<SessionService>();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  bool _loading = false;
  int _unreadCount = 0;

  // Local state should not be stored in Rx variables inside a StatefulWidget.
  // Using Rx here forces unnecessary GetX rebuilds and mixes state management.
  final List<AppNotification> _notifications = <AppNotification>[];
  final List<AppNotification> _filteredNotifications = <AppNotification>[];
  String _filterType = 'all';

  String? get _staffId => _session.user?.userId;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final staffId = _staffId;
    if (staffId == null || staffId.isEmpty) return;

    setState(() => _loading = true);
    try {
      final items = await NotificationsApi.getMyNotifications(
        staffId: staffId,
        includeRead: true,
      );

      _notifications
        ..clear()
        ..addAll(
          items
              .whereType<Map<String, dynamic>>()
              .map((e) => AppNotification.fromJson(e))
              .toList(),
        );

      _applyFilter();

      final unread = await NotificationsApi.getMyUnreadNotifications(staffId: staffId);
      setState(() => _unreadCount = unread);
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadInitial();
    _refreshController.refreshCompleted();
  }

  void _applyFilter() {
    if (_filterType == 'all') {
      _filteredNotifications
        ..clear()
        ..addAll(_notifications);
    } else if (_filterType == 'unread') {
      _filteredNotifications
        ..clear()
        ..addAll(
          _notifications.where((n) => n.isRead != true).toList(),
        );
    } else {
      _filteredNotifications
        ..clear()
        ..addAll(
          _notifications.where((n) => n.type == _filterType).toList(),
        );
    }
  }

  Future<void> _markOneAsRead(AppNotification n) async {
    final staffId = _staffId;
    if (staffId == null || staffId.isEmpty) return;
    final id = n.id;
    if (id == null) return;

    try {
      await NotificationsApi.markNotificationsAsRead(
        staffId: staffId,
        notificationIds: [id],
      );

      setState(() {
        _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
      });
    } catch (e) {
      debugPrint('Failed to mark as read: $e');
    } finally {
      await _refresh();
    }
  }

  Future<void> _markAllAsRead() async {
    final staffId = _staffId;
    if (staffId == null || staffId.isEmpty) return;

    try {
      await NotificationsApi.markAllAsRead(staffId: staffId);
      setState(() => _unreadCount = 0);
    } catch (e) {
      debugPrint('Failed to mark all as read: $e');
    } finally {
      await _refresh();
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return 'Just now';
        }
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  /// Buckets a date into one of the four section labels shown in the list.
  String _groupLabel(DateTime? dt) {
    if (dt == null) return 'Earlier';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'This Week';
    return 'Earlier';
  }

  /// Groups the current filtered list into Today / Yesterday / This Week /
  /// Earlier sections, newest first, and flattens it into header + item
  /// rows ready for a single ListView.builder.
  List<_ListRow> _buildGroupedRows() {
    final sorted = [..._filteredNotifications]..sort((a, b) {
        final da = a.createdAt;
        final db = b.createdAt;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

    const groupOrder = ['Today', 'Yesterday', 'This Week', 'Earlier'];
    final buckets = <String, List<AppNotification>>{
      for (final g in groupOrder) g: <AppNotification>[],
    };
    for (final n in sorted) {
      buckets[_groupLabel(n.createdAt)]!.add(n);
    }

    final rows = <_ListRow>[];
    for (final group in groupOrder) {
      final items = buckets[group]!;
      if (items.isEmpty) continue;
      rows.add(_ListRow.header(group));
      for (final n in items) {
        rows.add(_ListRow.item(n));
      }
    }
    return rows;
  }

  Widget _buildShimmerItem() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE7ECE9),
      highlightColor: const Color(0xFFF6FAF8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 12,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _T.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _T.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _T.primaryDark),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: _T.border)),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification n) {
    final isUnread = n.isRead != true;
    final accent = _typeColor(n.type);
    final icon = isUnread ? Icons.notifications_active_rounded : Icons.notifications_none_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isUnread ? _T.primarySoft.withOpacity(0.5) : _T.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isUnread ? _T.primary.withOpacity(0.25) : _T.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _markOneAsRead(n),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title ?? 'Notification',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                                color: _T.textPrimary,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(left: 6, top: 3),
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: _T.primary),
                            ),
                        ],
                      ),
                      if ((n.description ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          n.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, color: _T.textSecondary, height: 1.35),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (n.type != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                n.type!,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _formatTime(n.createdAt),
                            style: const TextStyle(fontSize: 11, color: _T.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _buildGroupedRows();

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: _T.primarySoft, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.notifications_outlined, color: _T.primaryDark, size: 19),
            ),
            // const SizedBox(width: 10),
            // const Text(
            //   'Notifications',
            //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _T.textPrimary),
            // ),
            const SizedBox(width: 8),
            if (_unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: _T.primary, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 17),
              label: const Text('Mark all read', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(foregroundColor: _T.primaryDark),
            ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _T.border),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: _T.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Unread', 'unread'),
                const SizedBox(width: 8),
                _buildFilterChip('Info', 'info'),
                const SizedBox(width: 8),
                _buildFilterChip('Success', 'success'),
              ],
            ),
          ),
          Container(height: 1, color: _T.border),
          Expanded(
            child: _loading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 6,
                    itemBuilder: (context, index) => _buildShimmerItem(),
                  )
                : rows.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(color: _T.primarySoft, shape: BoxShape.circle),
                              child: const Icon(Icons.notifications_off_rounded, size: 40, color: _T.primaryDark),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'No notifications',
                              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: _T.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "You're all caught up!",
                              style: TextStyle(fontSize: 13.5, color: _T.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : SmartRefresher(
                        controller: _refreshController,
                        onRefresh: _refresh,
                        enablePullDown: true,
                        header: const WaterDropHeader(
                          waterDropColor: _T.primary,
                          complete: Icon(Icons.check_circle_rounded, color: _T.primary),
                          failed: Icon(Icons.error_rounded, color: _T.error),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            final child = row.isHeader
                                ? _buildSectionHeader(
                                    row.header!,
                                    rows.skip(index + 1).takeWhile((r) => !r.isHeader).length,
                                  )
                                : _buildNotificationItem(row.notification!);

                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: Duration(milliseconds: 260 + (index * 25).clamp(0, 300)),
                              curve: Curves.easeOut,
                              builder: (context, value, c) => Opacity(
                                opacity: value,
                                child: Transform.translate(offset: Offset(0, (1 - value) * 10), child: c),
                              ),
                              child: child,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? _T.primaryDark : _T.textSecondary,
        ),
      ),
      onSelected: (_) {
        setState(() => _filterType = value);
        _applyFilter();
      },
      backgroundColor: _T.bg,
      selectedColor: _T.primarySoft,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? _T.primary : _T.border, width: isSelected ? 1.4 : 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
}