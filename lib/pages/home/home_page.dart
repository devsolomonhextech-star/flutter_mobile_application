import 'package:doctor_app/services/api/qrcode_api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../data/models/user_models.dart';
import '../../data/models/notification_models.dart';
import '../../services/api/notifications_api.dart';
import '../../services/session_service.dart';
import '../qrcode/qrcode_screen.dart';

import 'home_user_details_controller.dart';
import 'user_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SessionService _session = Get.find<SessionService>();
  final RxInt _unreadCount = 0.obs;
  final RxBool _isLoadingQR = false.obs;
  final RxString _qrCodeData = ''.obs;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _loadQRCodeData();
  }

  void _openMyQrCode() {
    final staffId = _session.user?.userId?.toString() ?? '';
    if (staffId.isEmpty) return;

    Get.to(() => QrcodeScreen(staffId: staffId));
  }

  Future<void> _loadQRCodeData() async {
    final staffId = _session.user?.userId?.toString();
    if (staffId == null || staffId.isEmpty) return;

    try {
      _isLoadingQR.value = true;
      final response = await QRCodeApi.getStaffQRCode(staffId: staffId);

      if (response['data'] != null && response['data']['qr_code'] != null) {
        _qrCodeData.value = response['data']['qr_code'];
      }
    } catch (e) {
      debugPrint('Failed to load QR code: $e');
    } finally {
      _isLoadingQR.value = false;
    }
  }

  void _showQRCodeDialog() {
    if (_qrCodeData.value.isEmpty) {
      // If QR code data is empty, try to load it again
      _loadQRCodeData().then((_) {
        if (_qrCodeData.value.isNotEmpty) {
          _showQRCodeDialogContent();
        } else {
          _showErrorDialog('Unable to load QR code. Please try again.');
        }
      });
      return;
    }
    _showQRCodeDialogContent();
  }

  void _showQRCodeDialogContent() {
    final user = _session.user;
    final staffId = user?.staffID ?? user?.userId ?? 'Staff';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/images/code.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'My QR Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade500),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // QR Code
              Obx(() {
                if (_isLoadingQR.value) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                if (_qrCodeData.value.isEmpty) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No QR Code Available',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: QrImageView(
                    data: _qrCodeData.value,
                    version: QrVersions.auto,
                    size: 200,
                    foregroundColor: Colors.blue.shade900,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    padding: const EdgeInsets.all(8),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Staff Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Show this QR code to mark attendance',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        Get.to(
                          () => QrcodeScreen(
                            staffId: _session.user?.userId?.toString() ?? '',
                          ),
                        );
                      },
                      icon: const Icon(Icons.fullscreen, size: 18),
                      label: const Text('View Full'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _loadUnreadCount() async {
    final staffId = _session.user?.userId;
    if (staffId == null || staffId.isEmpty) return;

    try {
      final unread = await NotificationsApi.getMyUnreadNotifications(staffId: staffId);
      _unreadCount.value = unread;
    } catch (_) {
      _unreadCount.value = 0;
    }
  }

  String _getGreetingName(UserModel? user) {
    final first = user?.firstName?.trim();
    final last = user?.lastName?.trim();
    if (first != null && first.isNotEmpty) {
      return first;
    }
    if (last != null && last.isNotEmpty) {
      return last;
    }
    return 'solo';
  }

  String _getUserInitials(UserModel? user) {
    final first = (user?.firstName ?? '').trim();
    final last = (user?.lastName ?? '').trim();
    final f = first.isNotEmpty ? first[0] : '';
    final l = last.isNotEmpty ? last[0] : '';
    final initials = '$f$l'.toUpperCase();
    return initials.isNotEmpty ? initials : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();
    final userController = Get.put(
      HomeUserDetailsController(sessionService: session),
      tag: 'home_user_details_controller',
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: SizedBox(
          width: double.infinity,
          child: Obx(() {
            return UserHeader(
              user: userController.user.value ?? session.currentUser.value,
              isLoading: userController.isLoading.value,
            );
          }),
        ),
        actions: [
          IconButton(
            onPressed: () => Get.toNamed('/notifications'),
            icon: Obx(() {
              final unread = _unreadCount.value;
              if (unread <= 0) {
                return const Icon(
                  Icons.notifications_outlined,
                  color: Colors.grey,
                  size: 26,
                );
              }

              return Badge(
                isLabelVisible: true,
                label: Text(
                  unread > 99 ? '99+' : unread.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.grey,
                  size: 26,
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Code Card
            _buildQRCodeCard(context),
            const SizedBox(height: 20),
            // Quick Stats
            _buildQuickStats(),
            const SizedBox(height: 20),
            // Features Grid
            _buildFeaturesGrid(context),
            const SizedBox(height: 20),
            // Upcoming Shifts / Duty Roster
            _buildUpcomingShifts(),
            const SizedBox(height: 20),
            // Recent Announcements
            _buildRecentAnnouncements(),
            const SizedBox(height: 20),
            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Widget _buildQRCodeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade700, Colors.blue.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📷 My QR Code',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to view your QR code for attendance',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _showQRCodeDialog,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Show QR Code',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Today',
            '🕒',
            '08:30 AM',
            'Checked In',
            Colors.green.shade50,
            Colors.green.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Hours',
            '⏱️',
            '06:45',
            'Worked Today',
            Colors.blue.shade50,
            Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Leave',
            '📅',
            '12',
            'Remaining',
            Colors.orange.shade50,
            Colors.orange.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String icon,
    String value,
    String subtitle,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final features = [
      {
        'icon': Image.asset('assets/images/code.png', width: 40, height: 40),
        'title': 'My QR Code',
        'color': Colors.blue,
        'onTap': _showQRCodeDialog,
      },
      {
        'icon': Image.asset('assets/images/calendar.png', width: 40, height: 40),
        'title': 'Attendance',
        'color': Colors.green,
        'onTap': () => Get.toNamed('/attendance'),
      },
      {
        'icon': Image.asset('assets/images/calendar.png', width: 40, height: 40),
        'title': 'Duty Roster',
        'color': Colors.purple,
        'onTap': () => Get.toNamed('/duty-roster'),
      },
      {
        'icon': Image.asset('assets/images/calendar.png', width: 40, height: 40),
        'title': 'Leave Requests',
        'color': Colors.orange,
        'onTap': () => Get.toNamed('/leave-requests'), 
      },
      {
        'icon': Image.asset('assets/images/heart.png', width: 40, height: 40),
        'title': 'Announcements',
        'color': Colors.red,
        'onTap': () => Get.toNamed('/notifications'),
      },
      {
        'icon': Image.asset('assets/images/heart.png', width: 40, height: 40),
        'title': 'Chat',
        'color': Colors.teal,
        'onTap': () => Get.toNamed('/chat'),
      },
      {
        'icon': Image.asset('assets/images/settings.png', width: 40, height: 40),
        'title': 'Reports',
        'color': Colors.indigo,
        'onTap': () => Get.toNamed('/reports'),
      },
      {
        'icon': Image.asset('assets/images/settings.png', width: 40, height: 40),
        'title': 'Settings',
        'color': Colors.grey,
        'onTap': () => Get.toNamed('/settings'),
      },  
      {
        'icon': Image.asset('assets/images/person.png', width: 40, height: 40),
        'title': 'Profile',
        'color': Colors.teal,
        'onTap': () => Get.toNamed('/profile'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            TextButton(
              onPressed: () => Get.toNamed('/more'),
              child: const Text('View All'),
            ),
          ],
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return InkWell(
              onTap: feature['onTap'] as VoidCallback?,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (feature['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: feature['icon'] as Widget,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feature['title'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUpcomingShifts() {
    final shifts = [
      {
        'date': 'Today',
        'time': '06:00 - 14:00',
        'department': 'Cardiology',
        'status': 'Morning',
      },
      {
        'date': 'Tomorrow',
        'time': '14:00 - 22:00',
        'department': 'Emergency',
        'status': 'Afternoon',
      },
      {
        'date': 'Wed, 15 Jan',
        'time': '22:00 - 06:00',
        'department': 'Ward',
        'status': 'Night',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📅 Upcoming Shifts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                TextButton(
                  onPressed: () => Get.toNamed('/duty-roster'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shifts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final shift = shifts[index];
              final statusColors = {
                'Morning': Colors.blue.shade50,
                'Afternoon': Colors.orange.shade50,
                'Night': Colors.purple.shade50,
              };
              final statusTextColors = {
                'Morning': Colors.blue.shade700,
                'Afternoon': Colors.orange.shade700,
                'Night': Colors.purple.shade700,
              };

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            (statusTextColors[shift['status']] as Color?) ??
                            Colors.grey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shift['date'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            '${shift['time']} • ${shift['department']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (statusColors[shift['status']] as Color?) ??
                            Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        shift['status'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color:
                              (statusTextColors[shift['status']] as Color?) ??
                              Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAnnouncements() {
    return FutureBuilder<List<dynamic>>(
      future: _loadRecentNotifications(limit: 3),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const [];
        final hasAny = data.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '📢 Recent Announcements',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.toNamed('/notifications'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !hasAny)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
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
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 120,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (data.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                  child: Center(
                    child: Text(
                      'No announcements',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final n = data[index] as AppNotification;
                    final createdAt = n.createdAt;


                    return InkWell(
                      onTap: () => Get.toNamed('/notifications'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getNotificationTypeColor(
                                  n.type,
                                ).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  _getNotificationTypeIcon(n.type),
                                  color: _getNotificationTypeColor(n.type),
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title ?? 'Notification',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  Text(
                                    _formatTime(createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<List<AppNotification>> _loadRecentNotifications({required int limit}) async {
    final staffId = _session.user?.userId;
    if (staffId == null || staffId.isEmpty) return <AppNotification>[];

    final items = await NotificationsApi.getMyNotifications(
      staffId: staffId,
      includeRead: true,
    );

    final parsed = items
        .whereType<Map<String, dynamic>>()
        .map((e) => AppNotification.fromJson(e))
        .toList();

    parsed.sort((a, b) {
      final ad = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bd = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bd.compareTo(ad);
    });

    return parsed.take(limit).toList();
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

  Color _getNotificationTypeColor(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'info':
        return Colors.blue.shade700;
      case 'success':
        return Colors.green.shade700;
      case 'warning':
        return Colors.orange.shade700;
      case 'error':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getNotificationTypeIcon(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'info':
        return Icons.info_outline;
      case 'success':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            '💬',
            'Chat',
            () => Get.toNamed('/chat'),
            Colors.green.shade50,
            Colors.green.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            '📊',
            'Reports',
            () => Get.toNamed('/report_bug'),
            Colors.purple.shade50,
            Colors.purple.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            '⚙️',
            'Settings',
            () => Get.toNamed('/settings'),
            Colors.grey.shade50,
            Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String icon,
    String label,
    VoidCallback onTap,
    Color bgColor,
    Color textColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade500,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'QR Code'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              _showQRCodeDialog();
              break;
            case 2:
              Get.toNamed('/duty-roster');
              break;
            case 3:
              Get.toNamed('/chat');
              break;
            case 4:
              Get.toNamed('/profile');
              break;
          }
        },
      ),
    );
  }
}
