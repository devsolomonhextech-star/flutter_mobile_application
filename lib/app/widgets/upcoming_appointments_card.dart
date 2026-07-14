// widgets/upcoming_appointments_card.dart
import 'package:doctor_app/data/models/doctor_appointment_model.dart';
import 'package:doctor_app/pages/appointments/appointments_controller.dart';
import 'package:doctor_app/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// ── Design tokens ─────────────────────────────────────────────
class _C {
  static const primary     = Color(0xFF1D4ED8); // deep blue
  static const primaryMid  = Color(0xFF3B82F6); // medium blue
  static const primaryLight= Color(0xFF60A5FA); // light blue
  static const primaryPale = Color(0xFFDBEAFE); // pale blue fill
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF0F6FF);
  static const textDark    = Color(0xFF0F172A);
  static const textMid     = Color(0xFF475569);
  static const textLight   = Color(0xFF94A3B8);
  static const divider     = Color(0xFFE2E8F0);
  static const greenBadge  = Color(0xFF16A34A);
  static const amberStar   = Color(0xFFF59E0B);
}

class UpcomingAppointmentsCard extends StatelessWidget {
  const UpcomingAppointmentsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();

    final controller = Get.put(
      AppointmentsController(
        session: session,
        doctorId: session.user!.userId.toString(),
        institutionId: session.user!.institutionId.toString(),
      ),
      tag: 'appointments_controller_${session.user!.userId}',
    );

    if (controller.upcomingAppointments.isEmpty && !controller.isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchUpcoming(limit: 10);
      });
    }

    return Obx(() {
      if (controller.isLoading.value && controller.upcomingAppointments.isEmpty) {
        return _buildShimmerLoading();
      }

      final appointments = controller.upcomingAppointments;
      if (appointments.isEmpty) {
        return _buildEmptyState();
      }

      return _buildContent(appointments);
    });
  }

  // ── Main content ────────────────────────────────────────────
  Widget _buildContent(List<DoctorAppointment> appointments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upcoming Schedule',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _C.textDark,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${appointments.length} appointment${appointments.length == 1 ? '' : 's'} pending',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _C.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              _ViewAllButton(),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ── Date selector ──
        _DateSelector(),

        const SizedBox(height: 20),

        // ── Appointment cards ──
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: appointments.length > 5 ? 5 : appointments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final apt = appointments[index];
              return _AppointmentCard(
                appointment: apt,
                index: index,
                onTap: () => Get.toNamed('/appointments/details/${apt.id}'),
                onVideoCall: () => _startVideoCall(apt),
              );
            },
          ),
        ),
      ],
    );
  }

  void _startVideoCall(DoctorAppointment appointment) {
    Get.snackbar(
      '📹 Video Call',
      'Connecting to ${appointment.patient}...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _C.primary,
      colorText: Colors.white,
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.video_call_outlined, color: Colors.white),
    );
  }

  // ── Empty state ──────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Schedule',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _C.textDark,
                  letterSpacing: -0.4,
                ),
              ),
              _ViewAllButton(),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _DateSelector(),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _C.primaryPale,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.primaryLight, width: 1.2),
                  ),
                  child: const Icon(
                    Icons.calendar_month_outlined,
                    color: _C.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Appointments',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _C.textDark,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Your schedule is clear for today',
                        style: TextStyle(
                          fontSize: 12,
                          color: _C.textMid,
                        ),
                      ),
                    ],
                  ),
                ),
                _ScheduleButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Shimmer loading ──────────────────────────────────────────
  Widget _buildShimmerLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Shimmer(width: 170, height: 20, radius: 6),
              _Shimmer(width: 60, height: 16, radius: 6),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 82,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 7,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _Shimmer(width: 58, height: 82, radius: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 14),
              child: _Shimmer(width: 230, height: 210, radius: 20),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// VIEW ALL BUTTON
// ─────────────────────────────────────────────────────────────
class _ViewAllButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed('/appointments'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _C.primaryPale,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.primaryLight.withOpacity(0.5), width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View All',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _C.primary,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded, size: 10, color: _C.primary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SCHEDULE BUTTON
// ─────────────────────────────────────────────────────────────
class _ScheduleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed('/appointments/schedule'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_C.primary, _C.primaryMid],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 16),
            SizedBox(width: 5),
            Text(
              'Schedule',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DATE SELECTOR
// ─────────────────────────────────────────────────────────────
class _DateSelector extends StatefulWidget {
  @override
  State<_DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<_DateSelector> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = index == _selectedIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 58,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [_C.primary, _C.primaryMid],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                color: isSelected ? null : _C.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _C.primary : _C.divider,
                  width: isSelected ? 0 : 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _C.primary.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).substring(0, 3),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white.withOpacity(0.85) : _C.textLight,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : _C.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Active dot indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: isSelected ? 5 : 0,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// APPOINTMENT CARD
// ─────────────────────────────────────────────────────────────
class _AppointmentCard extends StatefulWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.index,
    required this.onTap,
    required this.onVideoCall,
  });

  final DoctorAppointment appointment;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onVideoCall;

  @override
  State<_AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<_AppointmentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  static const _avatarBase =
      'https://ui-avatars.com/api/?background=1D4ED8&color=ffffff&size=128&name=';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0.25, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 60 + widget.index * 40), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apt = widget.appointment;
    final isFirst = widget.index == 0;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 230,
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: isFirst ? _C.primary : _C.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: isFirst
                      ? _C.primary.withOpacity(0.28)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top section ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isFirst
                              ? Colors.white.withOpacity(0.2)
                              : _C.primaryPale,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            '$_avatarBase${Uri.encodeComponent(apt.patient)}',
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 46,
                              height: 46,
                              color: isFirst
                                  ? Colors.white.withOpacity(0.2)
                                  : _C.primaryPale,
                              child: Center(
                                child: Text(
                                  _initials(apt.patient),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: isFirst ? Colors.white : _C.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              apt.patient,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isFirst ? Colors.white : _C.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              apt.type ?? 'General',
                              style: TextStyle(
                                fontSize: 11,
                                color: isFirst
                                    ? Colors.white.withOpacity(0.7)
                                    : _C.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      _StatusBadge(isFirst: isFirst),
                    ],
                  ),
                ),

                // ── Divider ──
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isFirst
                      ? Colors.white.withOpacity(0.12)
                      : _C.divider,
                ),

                // ── Time & rating row ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: isFirst
                            ? Colors.white.withOpacity(0.7)
                            : _C.textLight,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatTime(apt.time),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isFirst
                              ? Colors.white
                              : _C.textMid,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded, color: _C.amberStar, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        '4.8',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isFirst ? Colors.white : _C.textDark,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Action buttons ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Row(
                    children: [
                      // Video call button
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onVideoCall,
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: isFirst
                                  ? Colors.white.withOpacity(0.15)
                                  : _C.primaryPale,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: isFirst
                                    ? Colors.white.withOpacity(0.25)
                                    : _C.primaryLight.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam_rounded,
                                  size: 15,
                                  color: isFirst ? Colors.white : _C.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Video',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isFirst ? Colors.white : _C.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // View detail button
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onTap,
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: isFirst
                                  ? const LinearGradient(
                                      colors: [Colors.white, Color(0xFFEFF6FF)],
                                    )
                                  : const LinearGradient(
                                      colors: [_C.primary, _C.primaryMid],
                                    ),
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: [
                                BoxShadow(
                                  color: (isFirst
                                      ? Colors.white
                                      : _C.primary
                                  ).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Details',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isFirst ? _C.primary : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
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

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'P';
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';
    try {
      return DateFormat('h:mm a').format(DateFormat('HH:mm').parse(time));
    } catch (_) {
      return time;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isFirst});
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFirst
            ? Colors.white.withOpacity(0.18)
            : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFirst
              ? Colors.white.withOpacity(0.3)
              : const Color(0xFF86EFAC),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isFirst ? Colors.white : _C.greenBadge,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Waiting',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isFirst ? Colors.white : _C.greenBadge,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHIMMER PLACEHOLDER
// ─────────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.width, required this.height, required this.radius});
  final double width;
  final double height;
  final double radius;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            colors: [
              Color.lerp(const Color(0xFFE2E8F0), const Color(0xFFF8FAFC), _anim.value)!,
              Color.lerp(const Color(0xFFF1F5F9), const Color(0xFFDBEAFE), _anim.value)!,
            ],
          ),
        ),
      ),
    );
  }
}