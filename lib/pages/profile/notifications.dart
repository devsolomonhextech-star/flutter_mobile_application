import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:shimmer/shimmer.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../data/models/notification_models.dart';
import '../../services/api/notifications_api.dart';
import '../../services/session_service.dart';

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

  Widget _buildShimmerItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification n) {
    final isUnread = n.isRead != true;
    final icon = isUnread 
        ? Icons.notifications_active 
        : Icons.notifications_none;
    final iconColor = isUnread ? Colors.blue.shade700 : Colors.grey.shade400;

    return Material(
      color: isUnread ? Colors.blue.shade50 : Colors.white,
      child: InkWell(
        onTap: () => _markOneAsRead(n),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUnread ? Colors.blue.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
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
                              color: isUnread ? Colors.grey.shade900 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.shade700,
                            ),
                          ),
                      ],
                    ),
                    if ((n.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        n.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (n.type != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(n.type!).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              n.type!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getTypeColor(n.type!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _formatTime(n.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
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
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'info':
        return Colors.blue;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(
              Icons.notifications_outlined,
              color: Colors.blue.shade700,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(width: 8),
            if (_unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_outlined, size: 18),
              label: const Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
              ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),
          // Notifications List with Pull to Refresh
          Expanded(
            child: _loading
                ? ListView.separated(
                    padding: const EdgeInsets.all(0),
                    itemCount: 8,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) => _buildShimmerItem(),
                  )
                : _filteredNotifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "You're all caught up!",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SmartRefresher(
                        controller: _refreshController,
                        onRefresh: _refresh,
                        enablePullDown: true,
                        header: const WaterDropHeader(
                          waterDropColor: Colors.blue,
                          complete: Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          failed: Icon(
                            Icons.error,
                            color: Colors.red,
                          ),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(0),
                          itemCount: _filteredNotifications.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            final n = _filteredNotifications[index];
                            return _buildNotificationItem(n);
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
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
        ),
      ),
      onSelected: (_) {
        setState(() {
          _filterType = value;
        });
        _applyFilter();
      },
      backgroundColor: Colors.grey.shade50,
      selectedColor: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
}
