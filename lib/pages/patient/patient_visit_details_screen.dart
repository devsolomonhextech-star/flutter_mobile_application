// lib/app/modules/patient_visit_details/views/patient_visit_details_screen.dart
import 'package:doctor_app/data/models/visit_models.dart';
import 'package:doctor_app/data/models/visit_related_models.dart';
import 'package:doctor_app/services/controller/visit_controller.dart';
import 'package:flutter/material.dart';
import 'package:doctor_app/pages/patient/widgets/patient_notes_tab.dart';

// Patient notes widgets
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Shared design tokens — mint/teal palette used across the app, with a
/// consistent accent color per clinical/financial category so a doctor
/// can pattern-match a section by color at a glance.
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

  static const diagnosis = Color(0xFFE0656B); // rose
  static const vitals = Color(0xFF3EBE93); // teal
  static const prescriptions = Color(0xFF5B8DEF); // blue
  static const labTests = Color(0xFF8B7FD1); // violet
  static const procedures = Color(0xFFE0A94A); // amber
  static const appointments = Color(0xFF4FBFBF); // cyan
  static const claims = Color(0xFF6FA8DC); // sky
  static const invoices = Color(0xFF9468AE); // plum
  static const notes = Color(0xFF8B9892); // slate
}

String _formatDate(DateTime? d) =>
    d == null ? 'N/A' : DateFormat('dd MMM yyyy').format(d);
String _formatDateTime(DateTime? d) =>
    d == null ? 'N/A' : DateFormat('dd MMM yyyy, HH:mm').format(d);

Color _statusColor(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'active':
    case 'admitted':
    case 'confirmed':
      return _T.primary;
    case 'completed':
    case 'discharged':
      return const Color(0xFF5B8DEF);
    case 'pending':
      return const Color(0xFFE0A94A);
    case 'cancelled':
      return const Color(0xFFE0656B);
    case 'scheduled':
      return const Color(0xFF8B7FD1);
    default:
      return _T.textSecondary;
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: _T.surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: _T.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 14,
        offset: const Offset(0, 5),
      ),
    ],
  );
}

class PatientVisitDetailsScreen extends StatefulWidget {
  final String visitId;
  const PatientVisitDetailsScreen({super.key, required this.visitId});

  @override
  State<PatientVisitDetailsScreen> createState() =>
      _PatientVisitDetailsScreenState();
}

class _PatientVisitDetailsScreenState extends State<PatientVisitDetailsScreen>
    with TickerProviderStateMixin {
  final VisitController visitController = Get.find<VisitController>();
  late final TabController _tabController;
  late final AnimationController _fabController;
  bool _fabOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _load();
  }

  Future<void> _load() async {
    await Future<void>.delayed(Duration.zero);
    await visitController.getVisitDetails(widget.visitId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _fabOpen = !_fabOpen;
      _fabOpen ? _fabController.forward() : _fabController.reverse();
    });
  }

  void _closeFab() {
    if (_fabOpen) {
      setState(() {
        _fabOpen = false;
        _fabController.reverse();
      });
    }
  }

  Future<void> _openAddVitals() async {
    _closeFab();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddVitalsSheet(onSubmit: _submitVitals),
    );
  }

  Future<void> _openAddAppointment() async {
    _closeFab();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAppointmentSheet(onSubmit: _submitAppointment),
    );
  }

  void _submitVitals(Map<String, dynamic> values) {
    // TODO: wire to the real VisitController method, e.g.
    //   visitController.addVitalSigns(widget.visitId, values);
    //   then visitController.getVisitDetails(widget.visitId);
    Get.snackbar(
      'Vitals recorded',
      'New vitals were captured for this visit.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _T.textPrimary,
      colorText: Colors.white,
    );
  }

  void _submitAppointment(Map<String, dynamic> values) {
    // TODO: wire to the real VisitController method, e.g.
    //   visitController.addAppointment(widget.visitId, values);
    //   then visitController.getVisitDetails(widget.visitId);
    Get.snackbar(
      'Appointment scheduled',
      'The appointment was added to this visit.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _T.textPrimary,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        title: const Text(
          'Patient Visit Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: _T.textPrimary,
          ),
        ),
        backgroundColor: _T.surface,
        foregroundColor: _T.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          IconButton(
            onPressed: () => visitController.getVisitDetails(widget.visitId),
            icon: const Icon(Icons.refresh_rounded, color: _T.textSecondary),
            splashRadius: 22,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: _T.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TabBar(
              controller: _tabController,
              indicatorColor: _T.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: _T.textPrimary,
              unselectedLabelColor: _T.textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Clinical'),
                Tab(text: 'Financial'),
                Tab(text: 'Timeline'),
                Tab(text: 'Patient Notes'),
              ],
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: _closeFab,
        child: Obx(() {
          final isLoading = visitController.isLoading.value;

          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_T.primary),
              ),
            );
          }

          final Visit? visit = visitController.visits.firstWhereOrNull(
            (v) => v.id == widget.visitId,
          );

          if (visit == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                    color: _T.textMuted,
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      visitController.errorMessage.value.isNotEmpty
                          ? visitController.errorMessage.value
                          : 'Visit not found',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _T.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(visit: visit),
              _ClinicalTab(visit: visit),
              _FinancialTab(visit: visit),
              _TimelineTab(visit: visit),
              // Patient Notes + Comments (tap action)
              // Note: this is separate from timeline and appears as its own tab.
              PatientNotesTab(visitId: widget.visitId),
            ],
          );
        }),
      ),
      floatingActionButton: _buildExpandableFab(),
    );
  }

  Widget _buildExpandableFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _MiniFabAction(
          controller: _fabController,
          index: 1,
          label: 'Add Appointment',
          icon: Icons.event_available_rounded,
          color: _T.appointments,
          onTap: _openAddAppointment,
        ),
        const SizedBox(height: 10),
        _MiniFabAction(
          controller: _fabController,
          index: 0,
          label: 'Add Vitals',
          icon: Icons.monitor_heart_rounded,
          color: _T.vitals,
          onTap: _openAddVitals,
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _toggleFab,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_T.primary, _T.primaryDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: _T.primary.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: RotationTransition(
              turns: Tween(begin: 0.0, end: 0.125).animate(_fabController),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// -------------------- Shared: staggered entrance list --------------------

class _StaggeredList extends StatelessWidget {
  final List<Widget> children;
  const _StaggeredList({required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + (index * 40).clamp(0, 400)),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 16),
              child: child,
            ),
          ),
          child: children[index],
        );
      },
    );
  }
}

Widget _sectionSpacer() => const SizedBox(height: 14);

/// -------------------- Mini FAB action --------------------

class _MiniFabAction extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MiniFabAction({
    required this.controller,
    required this.index,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(index * 0.1, 1.0, curve: Curves.easeOutBack),
    );
    return ScaleTransition(
      scale: animation,
      alignment: Alignment.bottomRight,
      child: FadeTransition(
        opacity: controller,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _T.textPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ OVERVIEW TAB ============
class _OverviewTab extends StatelessWidget {
  final Visit visit;
  const _OverviewTab({required this.visit});

  @override
  Widget build(BuildContext context) {
    return _StaggeredList(
      children: [
        _PatientHeaderCard(patient: visit.patient, visit: visit),
        _sectionSpacer(),
        _QuickStats(visit: visit),
        _sectionSpacer(),
        _VitalSignsSection(visit: visit),
        _sectionSpacer(),
        _RecentActivities(visit: visit),
      ],
    );
  }
}

class _PatientHeaderCard extends StatelessWidget {
  final dynamic patient;
  final Visit visit;
  const _PatientHeaderCard({required this.patient, required this.visit});

  @override
  Widget build(BuildContext context) {
    final initials = patient?.initials ?? 'P';
    final name = patient?.fullName ?? 'Unknown Patient';
    final statusColor = _statusColor(visit.status);

    double totalAmount = 0;
    if (visit.invoices != null) {
      for (final invoice in visit.invoices!) {
        totalAmount += invoice.amount ?? 0;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6BD9B4), _T.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _T.primary.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.25),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (patient?.age != null) ...[
                          Text(
                            '${patient.age} yrs',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (patient?.gender != null)
                          Text(
                            patient.gender,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                visit.status ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _HeaderStat(
                  label: 'Total Billed',
                  value: 'GHS ${totalAmount.toStringAsFixed(2)}',
                  icon: Icons.attach_money_rounded,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withOpacity(0.2),
                ),
                _HeaderStat(
                  label: 'Department',
                  value: visit.department?.name ?? 'N/A',
                  icon: Icons.business_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.85), size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final Visit visit;
  const _QuickStats({required this.visit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Statistics',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: _T.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatItem(
                label: 'Diagnoses',
                value: '${visit.diagnosis?.length ?? 0}',
                icon: Icons.medical_information_rounded,
                color: _T.diagnosis,
              ),
              _StatItem(
                label: 'Prescriptions',
                value: '${visit.prescriptions?.length ?? 0}',
                icon: Icons.medication_rounded,
                color: _T.prescriptions,
              ),
              _StatItem(
                label: 'Lab Tests',
                value: '${visit.labTests?.length ?? 0}',
                icon: Icons.science_rounded,
                color: _T.labTests,
              ),
              _StatItem(
                label: 'Procedures',
                value: '${visit.procedures?.length ?? 0}',
                icon: Icons.healing_rounded,
                color: _T.procedures,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 9.5, color: _T.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivities extends StatelessWidget {
  final Visit visit;
  const _RecentActivities({required this.visit});

  @override
  Widget build(BuildContext context) {
    final activities = <Map<String, dynamic>>[];

    for (final note in visit.patientNotes ?? <PatientNote>[]) {
      activities.add({
        'title': 'Note Added',
        'subtitle': note.note ?? 'New note',
        'date': note.createdAt,
        'icon': Icons.notes_rounded,
        'color': _T.notes,
      });
    }
    // Patient notes will be fetched inside the Patient Notes widget as well.

    for (final d in visit.diagnosis ?? <Diagnosis>[]) {
      activities.add({
        'title': 'Diagnosis',
        'subtitle': d.diagnosis ?? 'New diagnosis',
        'date': d.createdAt,
        'icon': Icons.medical_information_rounded,
        'color': _T.diagnosis,
      });
    }
    for (final p in visit.prescriptions ?? <Prescription>[]) {
      activities.add({
        'title': 'Prescription',
        'subtitle': '${p.medication ?? 'N/A'} • ${p.dosage ?? 'N/A'}',
        'date': p.createdAt,
        'icon': Icons.medication_rounded,
        'color': _T.prescriptions,
      });
    }

    activities.sort((a, b) {
      final dateA = a['date'] as DateTime?;
      final dateB = b['date'] as DateTime?;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    final shown = activities.length > 5 ? activities.sublist(0, 5) : activities;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: _T.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No recent activity',
                  style: TextStyle(color: _T.textMuted, fontSize: 13.5),
                ),
              ),
            )
          else
            ...shown.map(
              (a) => _ActivityItem(
                title: a['title'] as String,
                subtitle: a['subtitle'] as String,
                date: a['date'] as DateTime?,
                icon: a['icon'] as IconData,
                color: a['color'] as Color,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime? date;
  final IconData icon;
  final Color color;
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _T.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: _T.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (date != null)
            Text(
              DateFormat('dd/MM/yy').format(date!),
              style: const TextStyle(fontSize: 11, color: _T.textMuted),
            ),
        ],
      ),
    );
  }
}

// ============ CLINICAL TAB ============
class _ClinicalTab extends StatelessWidget {
  final Visit visit;
  const _ClinicalTab({required this.visit});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _ClinicalSection(
        title: 'Vital Signs',
        icon: Icons.monitor_heart_rounded,
        color: _T.vitals,
        children: [_VitalSignsSection(visit: visit)],
      ),
    ];

    if (visit.diagnosis?.isNotEmpty == true) {
      children.add(
        _ClinicalSection(
          title: 'Diagnoses',
          icon: Icons.medical_information_rounded,
          color: _T.diagnosis,
          count: visit.diagnosis!.length,
          children: visit.diagnosis!
              .map(
                (d) => _ClinicalItem(
                  title: d.diagnosis ?? 'N/A',
                  subtitle: 'Added ${_formatDate(d.createdAt)}',
                  accent: _T.diagnosis,
                ),
              )
              .toList(),
        ),
      );
    }
    if (visit.prescriptions?.isNotEmpty == true) {
      children.add(
        _ClinicalSection(
          title: 'Prescriptions',
          icon: Icons.medication_rounded,
          color: _T.prescriptions,
          count: visit.prescriptions!.length,
          children: visit.prescriptions!
              .map(
                (p) => _ClinicalItem(
                  title: p.medication ?? 'N/A',
                  subtitle: '${p.dosage ?? 'N/A'} • ${p.frequency ?? 'N/A'}',
                  trailing: _formatDate(p.createdAt),
                  accent: _T.prescriptions,
                ),
              )
              .toList(),
        ),
      );
    }
    if (visit.labTests?.isNotEmpty == true) {
      children.add(
        _ClinicalSection(
          title: 'Lab Tests',
          icon: Icons.science_rounded,
          color: _T.labTests,
          count: visit.labTests!.length,
          children: visit.labTests!
              .map(
                (l) => _ClinicalItem(
                  title: l.testName ?? 'N/A',
                  subtitle: l.result ?? 'Pending',
                  trailing: _formatDate(l.createdAt),
                  accent: _T.labTests,
                ),
              )
              .toList(),
        ),
      );
    }
    if (visit.procedures?.isNotEmpty == true) {
      children.add(
        _ClinicalSection(
          title: 'Procedures',
          icon: Icons.healing_rounded,
          color: _T.procedures,
          count: visit.procedures!.length,
          children: visit.procedures!
              .map(
                (p) => _ClinicalItem(
                  title: p.procedureName ?? 'N/A',
                  subtitle: 'Performed ${_formatDate(p.performedAt)}',
                  accent: _T.procedures,
                ),
              )
              .toList(),
        ),
      );
    }
    if (visit.patientNotes?.isNotEmpty == true) {
      children.add(
        _ClinicalSection(
          title: 'Patient Notes',
          icon: Icons.notes_rounded,
          color: _T.notes,
          count: visit.patientNotes!.length,
          children: visit.patientNotes!
              .map(
                (n) => _ClinicalItem(
                  title: n.note ?? 'No content',
                  subtitle: 'Added ${_formatDate(n.createdAt)}',
                  isNote: true,
                  accent: _T.notes,
                ),
              )
              .toList(),
        ),
      );
    }

    return _StaggeredList(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) _sectionSpacer(),
        ],
      ],
    );
  }
}

class _ClinicalSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int? count;
  final List<Widget> children;

  const _ClinicalSection({
    required this.title,
    required this.icon,
    required this.color,
    this.count,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _T.textPrimary,
                ),
              ),
              if (count != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ClinicalItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailing;
  final bool isNote;
  final Color accent;

  const _ClinicalItem({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.isNote = false,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _T.textPrimary,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: _T.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ============ FINANCIAL TAB ============
class _FinancialTab extends StatelessWidget {
  final Visit visit;
  const _FinancialTab({required this.visit});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[_FinancialSummary(visit: visit)];

    if (visit.invoices?.isNotEmpty == true) {
      children.add(_InvoicesSection(invoices: visit.invoices!));
    }
    if (visit.claims?.isNotEmpty == true) {
      children.add(_ClaimsSection(claims: visit.claims!));
    }
    if (visit.appointments?.isNotEmpty == true) {
      children.add(_AppointmentsSection(appointments: visit.appointments!));
    }

    return _StaggeredList(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) _sectionSpacer(),
        ],
      ],
    );
  }
}

class _FinancialSummary extends StatelessWidget {
  final Visit visit;
  const _FinancialSummary({required this.visit});

  @override
  Widget build(BuildContext context) {
    double totalAmount = 0;
    // NOTE: the Invoice model has no "paid" field yet, so paid/outstanding
    // can't be split accurately. Showing total billed + claims filed as the
    // two figures we can support from the current data model.
    if (visit.invoices != null) {
      for (final invoice in visit.invoices!) {
        totalAmount += invoice.amount ?? 0;
      }
    }
    double totalClaims = 0;
    if (visit.claims != null) {
      for (final claim in visit.claims!) {
        totalClaims += claim.amount ?? 0;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_T.primary, _T.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _T.primary.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Financial Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _FinancialStat(
                label: 'Total Billed',
                value: 'GHS ${totalAmount.toStringAsFixed(2)}',
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withOpacity(0.25),
              ),
              _FinancialStat(
                label: 'Claims Filed',
                value: 'GHS ${totalClaims.toStringAsFixed(2)}',
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withOpacity(0.25),
              ),
              _FinancialStat(
                label: 'Invoices',
                value: '${visit.invoices?.length ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinancialStat extends StatelessWidget {
  final String label;
  final String value;
  const _FinancialStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicesSection extends StatelessWidget {
  final List<Invoice> invoices;
  const _InvoicesSection({required this.invoices});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _financialSectionHeader(
            'Invoices',
            Icons.request_quote_rounded,
            _T.invoices,
            invoices.length,
          ),
          const SizedBox(height: 12),
          ...invoices.map(
            (invoice) => _FinancialItem(
              title:
                  'Invoice #${(invoice.id ?? '').length >= 8 ? invoice.id!.substring(0, 8) : (invoice.id ?? 'N/A')}',
              amount: invoice.amount ?? 0,
              date: invoice.issuedAt,
              status: 'Issued',
              statusColor: _T.invoices,
              icon: Icons.request_quote_rounded,
              accent: _T.invoices,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimsSection extends StatelessWidget {
  final List<Claim> claims;
  const _ClaimsSection({required this.claims});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Clean diagram breakdown: the section is collapsed in the UI; tapping
              // shows a clear breakdown of what makes up a claim.
              showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _T.claims.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                size: 18,
                                color: _T.claims,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Claims breakdown',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _T.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _T.claims.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${claims.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _T.claims,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _BreakChip(
                              title: 'Claim Type',
                              subtitle: 'e.g. OPD/IPD/Pharmacy',
                              icon: Icons.label_rounded,
                              color: _T.claims,
                            ),
                            _BreakChip(
                              title: 'Amount',
                              subtitle: 'Total requested value',
                              icon: Icons.attach_money_rounded,
                              color: _T.claims,
                            ),
                            _BreakChip(
                              title: 'Status',
                              subtitle: 'Workflow state of claim',
                              icon: Icons.pending_actions_rounded,
                              color: const Color(0xFFE0A94A),
                            ),
                            _BreakChip(
                              title: 'Created Date',
                              subtitle: 'When the claim was filed',
                              icon: Icons.calendar_today_rounded,
                              color: _T.textSecondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Tap each claim in the list below to review the record details (implemented as a dialog in this screen).',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: _T.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            child: _financialSectionHeader(
              'Claims',
              Icons.receipt_long_rounded,
              _T.claims,
              claims.length,
            ),
          ),
          const SizedBox(height: 12),
          ...claims.map(
            (claim) => InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _T.claims.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  size: 18,
                                  color: _T.claims,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  claim.claimType ?? 'Claim',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _T.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _BreakRow(
                            label: 'Amount',
                            value:
                                'GHS ${(claim.amount ?? 0).toStringAsFixed(2)}',
                            valueColor: _T.textPrimary,
                          ),
                          _BreakRow(
                            label: 'Created',
                            value: claim.createdAt != null
                                ? _formatDate(claim.createdAt)
                                : 'N/A',
                            valueColor: _T.textSecondary,
                          ),
                          const SizedBox(height: 6),
                          _BreakRow(
                            label: 'Status',
                            value: 'Pending',
                            valueColor: const Color(0xFFE0A94A),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Done'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: _FinancialItem(
                title: claim.claimType ?? 'Claim',
                amount: claim.amount ?? 0,
                date: claim.createdAt,
                status: 'Pending',
                statusColor: const Color(0xFFE0A94A),
                icon: Icons.receipt_long_rounded,
                accent: _T.claims,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentsSection extends StatelessWidget {
  final List<Appointment> appointments;
  const _AppointmentsSection({required this.appointments});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _financialSectionHeader(
            'Appointments',
            Icons.event_available_rounded,
            _T.appointments,
            appointments.length,
          ),
          const SizedBox(height: 12),
          ...appointments.map((a) => _AppointmentItem(appointment: a)),
        ],
      ),
    );
  }
}

Widget _financialSectionHeader(
  String title,
  IconData icon,
  Color color,
  int count,
) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _T.textPrimary,
        ),
      ),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    ],
  );
}

class _AppointmentItem extends StatelessWidget {
  final Appointment appointment;
  const _AppointmentItem({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(appointment.status);
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _T.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _T.appointments.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.event_rounded,
              size: 18,
              color: _T.appointments,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appointment',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _T.textPrimary,
                  ),
                ),
                Text(
                  _formatDateTime(appointment.appointmentDate),
                  style: const TextStyle(fontSize: 12, color: _T.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              appointment.status ?? 'N/A',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialItem extends StatelessWidget {
  final String title;
  final double amount;
  final DateTime? date;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color accent;

  const _FinancialItem({
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _T.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _T.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (date != null)
                  Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: _T.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'GHS ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _T.textPrimary,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============ TIMELINE TAB ============
class _TimelineTab extends StatelessWidget {
  final Visit visit;
  const _TimelineTab({required this.visit});

  @override
  Widget build(BuildContext context) {
    final events = <Map<String, dynamic>>[];

    if (visit.createdAt != null) {
      events.add({
        'title': 'Visit Created',
        'subtitle': 'Visit was created',
        'date': visit.createdAt,
        'icon': Icons.add_circle_rounded,
        'color': _T.vitals,
      });
    }
    for (final note in visit.patientNotes ?? <PatientNote>[]) {
      events.add({
        'title': 'Note Added',
        'subtitle': note.note ?? 'New note',
        'date': note.createdAt,
        'icon': Icons.notes_rounded,
        'color': _T.notes,
      });
    }
    for (final d in visit.diagnosis ?? <Diagnosis>[]) {
      events.add({
        'title': 'Diagnosis Added',
        'subtitle': d.diagnosis ?? 'New diagnosis',
        'date': d.createdAt,
        'icon': Icons.medical_information_rounded,
        'color': _T.diagnosis,
      });
    }
    for (final p in visit.prescriptions ?? <Prescription>[]) {
      events.add({
        'title': 'Prescription Added',
        'subtitle': '${p.medication ?? 'N/A'} • ${p.dosage ?? 'N/A'}',
        'date': p.createdAt,
        'icon': Icons.medication_rounded,
        'color': _T.prescriptions,
      });
    }
    for (final l in visit.labTests ?? <LabTestResult>[]) {
      events.add({
        'title': 'Lab Test Added',
        'subtitle': '${l.testName ?? 'N/A'} • ${l.result ?? 'Pending'}',
        'date': l.createdAt,
        'icon': Icons.science_rounded,
        'color': _T.labTests,
      });
    }
    for (final p in visit.procedures ?? <Procedure>[]) {
      events.add({
        'title': 'Procedure Performed',
        'subtitle': p.procedureName ?? 'Procedure',
        'date': p.performedAt ?? p.createdAt,
        'icon': Icons.healing_rounded,
        'color': _T.procedures,
      });
    }
    for (final i in visit.invoices ?? <Invoice>[]) {
      events.add({
        'title': 'Invoice Issued',
        'subtitle': 'GHS ${i.amount?.toStringAsFixed(2) ?? '0.00'}',
        'date': i.issuedAt ?? i.createdAt,
        'icon': Icons.request_quote_rounded,
        'color': _T.invoices,
      });
    }
    for (final a in visit.appointments ?? <Appointment>[]) {
      events.add({
        'title': 'Appointment ${a.status ?? ''}',
        'subtitle': _formatDateTime(a.appointmentDate),
        'date': a.createdAt,
        'icon': Icons.event_available_rounded,
        'color': _T.appointments,
      });
    }

    events.sort((a, b) {
      final dateA = a['date'] as DateTime?;
      final dateB = b['date'] as DateTime?;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return _StaggeredList(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _T.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (events.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      'No events recorded',
                      style: TextStyle(color: _T.textMuted, fontSize: 13.5),
                    ),
                  ),
                )
              else
                ...events.asMap().entries.map((entry) {
                  final index = entry.key;
                  return _TimelineItem(
                    event: entry.value,
                    isLast: index == events.length - 1,
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isLast;
  const _TimelineItem({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = event['color'] as Color;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(event['icon'] as IconData, size: 16, color: color),
            ),
            if (!isLast) Container(width: 2, height: 40, color: _T.border),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'] as String,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _T.textPrimary,
                  ),
                ),
                Text(
                  event['subtitle'] as String,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _T.textSecondary,
                  ),
                ),
                if (event['date'] != null)
                  Text(
                    _formatDateTime(event['date'] as DateTime),
                    style: const TextStyle(fontSize: 11, color: _T.textMuted),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============ VITAL SIGNS SECTION (shared by Overview + Clinical) ============
class _VitalSignsSection extends StatelessWidget {
  final Visit visit;
  const _VitalSignsSection({required this.visit});

  @override
  Widget build(BuildContext context) {
    final records = visit.vitalSignsRecords;
    if (records == null || records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No vitals recorded yet.',
          style: TextStyle(color: _T.textMuted, fontSize: 12.5),
        ),
      );
    }

    final latest = records.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _VitalSignItem(
              label: 'Temperature',
              value: '${latest.temperature ?? '-'}°C',
              icon: Icons.thermostat_rounded,
            ),
            _VitalSignItem(
              label: 'Heart Rate',
              value: '${latest.heartRate ?? '-'} bpm',
              icon: Icons.favorite_rounded,
            ),
            _VitalSignItem(
              label: 'Oxygen',
              value: '${latest.oxygenSaturation ?? '-'}%',
              icon: Icons.water_drop_rounded,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _VitalSignItem(
              label: 'Blood Pressure',
              value:
                  '${latest.bloodPressureSystolic ?? '-'}/${latest.bloodPressureDiastolic ?? '-'}',
              icon: Icons.speed_rounded,
              flex: 2,
            ),
            _VitalSignItem(
              label: 'Resp. Rate',
              value: '${latest.respiratoryRate ?? '-'}/min',
              icon: Icons.air_rounded,
            ),
          ],
        ),
        if (latest.recordedAt != null) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: _T.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                'Recorded ${_formatDateTime(latest.recordedAt)}',
                style: const TextStyle(fontSize: 11.5, color: _T.textMuted),
              ),
            ],
          ),
        ],
        if (records.length > 1) ...[
          const SizedBox(height: 6),
          Text(
            '+ ${records.length - 1} earlier reading${records.length - 1 == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 11.5, color: _T.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _VitalSignItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final int flex;
  const _VitalSignItem({
    required this.label,
    required this.value,
    required this.icon,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _T.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: _T.primaryDark),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: _T.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: _T.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// -------------------- Add Vitals bottom sheet --------------------

class _AddVitalsSheet extends StatefulWidget {
  final void Function(Map<String, dynamic> values) onSubmit;
  const _AddVitalsSheet({required this.onSubmit});

  @override
  State<_AddVitalsSheet> createState() => _AddVitalsSheetState();
}

class _AddVitalsSheetState extends State<_AddVitalsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _temp = TextEditingController();
  final _bpSys = TextEditingController();
  final _bpDia = TextEditingController();
  final _hr = TextEditingController();
  final _rr = TextEditingController();
  final _spo2 = TextEditingController();

  @override
  void dispose() {
    _temp.dispose();
    _bpSys.dispose();
    _bpDia.dispose();
    _hr.dispose();
    _rr.dispose();
    _spo2.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit({
      'temperature': int.tryParse(_temp.text),
      'bloodPressureSystolic': int.tryParse(_bpSys.text),
      'bloodPressureDiastolic': int.tryParse(_bpDia.text),
      'heartRate': int.tryParse(_hr.text),
      'respiratoryRate': int.tryParse(_rr.text),
      'oxygenSaturation': int.tryParse(_spo2.text),
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _FormSheetShell(
      title: 'Add Vitals',
      icon: Icons.monitor_heart_rounded,
      color: _T.vitals,
      formKey: _formKey,
      onSubmit: _submit,
      submitLabel: 'Save Vitals',
      children: [
        Row(
          children: [
            Expanded(
              child: _numberField(_temp, 'Temp (°C)', Icons.thermostat_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _numberField(
                _hr,
                'Heart Rate (bpm)',
                Icons.favorite_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _numberField(_bpSys, 'BP Systolic', Icons.speed_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _numberField(_bpDia, 'BP Diastolic', Icons.speed_rounded),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _numberField(_rr, 'Resp. Rate', Icons.air_rounded)),
            const SizedBox(width: 12),
            Expanded(
              child: _numberField(_spo2, 'SpO2 (%)', Icons.water_drop_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14, color: _T.textPrimary),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12.5, color: _T.textSecondary),
        prefixIcon: Icon(icon, size: 18, color: _T.vitals),
        filled: true,
        fillColor: _T.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _T.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _T.vitals, width: 1.5),
        ),
      ),
    );
  }
}

/// -------------------- Add Appointment bottom sheet --------------------

class _AddAppointmentSheet extends StatefulWidget {
  final void Function(Map<String, dynamic> values) onSubmit;
  const _AddAppointmentSheet({required this.onSubmit});

  @override
  State<_AddAppointmentSheet> createState() => _AddAppointmentSheetState();
}

class _AddAppointmentSheetState extends State<_AddAppointmentSheet> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String _status = 'Scheduled';
  final _statusOptions = const ['Scheduled', 'Completed', 'Cancelled'];

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: _T.appointments),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    if (_selectedDate == null) {
      Get.snackbar(
        'Pick a date',
        'Please select an appointment date first.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    widget.onSubmit({
      'appointmentDate': _selectedDate!.toIso8601String(),
      'status': _status,
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _FormSheetShell(
      title: 'Add Appointment',
      icon: Icons.event_available_rounded,
      color: _T.appointments,
      formKey: _formKey,
      onSubmit: _submit,
      submitLabel: 'Save Appointment',
      children: [
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: _T.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _T.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: _T.appointments,
                ),
                const SizedBox(width: 10),
                Text(
                  _selectedDate == null
                      ? 'Select appointment date'
                      : _formatDate(_selectedDate),
                  style: TextStyle(
                    fontSize: 13.5,
                    color: _selectedDate == null
                        ? _T.textMuted
                        : _T.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          children: [
            for (final option in _statusOptions)
              ChoiceChip(
                label: Text(option),
                selected: _status == option,
                onSelected: (_) => setState(() => _status = option),
                selectedColor: _T.appointments.withOpacity(0.15),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _status == option ? _T.appointments : _T.textSecondary,
                ),
                backgroundColor: _T.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _status == option ? _T.appointments : _T.border,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Shared bottom-sheet shell so both "Add" forms look and behave consistently.
class _BreakRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _BreakRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _T.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

class _BreakChip extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _BreakChip({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _T.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: _T.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormSheetShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final VoidCallback onSubmit;
  final String submitLabel;

  const _FormSheetShell({
    required this.title,
    required this.icon,
    required this.color,
    required this.formKey,
    required this.children,
    required this.onSubmit,
    required this.submitLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _T.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _T.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...children,
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onSubmit,
                    borderRadius: BorderRadius.circular(26),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            submitLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
