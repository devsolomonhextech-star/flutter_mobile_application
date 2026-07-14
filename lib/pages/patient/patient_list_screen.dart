// lib/app/modules/patient_list/views/patient_list_screen.dart
import 'package:doctor_app/services/controller/visit_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../data/models/visit_models.dart';

/// Shared design tokens — same mint/teal palette used across the app
/// (login, onboarding, etc.) so every screen feels like one product.
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
  static const searchFill = Color(0xFFF0F5F3);
}

/// Curated, teal-forward palette for patient avatars — variety without
/// clashing with the brand color.
const List<List<Color>> _avatarPalette = [
  [Color(0xFF3EBE93), Color(0xFF2FA37D)], // teal
  [Color(0xFF5B8DEF), Color(0xFF3E6FD9)], // blue
  [Color(0xFF8B7FD1), Color(0xFF6C5CE7)], // violet
  [Color(0xFFE0A94A), Color(0xFFCB8F2E)], // amber
  [Color(0xFFE0656B), Color(0xFFC94850)], // rose
  [Color(0xFF4FBFBF), Color(0xFF359999)], // cyan
  [Color(0xFF6FA8DC), Color(0xFF4A85BE)], // sky
  [Color(0xFFB08BC9), Color(0xFF9468AE)], // plum
];

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final VisitController visitController = Get.put(VisitController());
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  bool _searchHasFocus = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _searchHasFocus = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Visit> get filteredVisits {
    if (_searchQuery.isEmpty) {
      return visitController.visits;
    }
    final query = _searchQuery.toLowerCase();
    return visitController.visits.where((visit) {
      final patient = visit.patient;
      final name = patient?.fullName.toLowerCase() ?? '';
      final id = visit.id?.toLowerCase() ?? '';
      final patientId = patient?.id?.toLowerCase() ?? '';
      final status = visit.status?.toLowerCase() ?? '';

      return name.contains(query) ||
          id.contains(query) ||
          patientId.contains(query) ||
          status.contains(query);
    }).toList();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Patient Visits',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _T.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list_rounded, color: _T.textSecondary),
            splashRadius: 22,
          ),
          IconButton(
            onPressed: visitController.refreshVisits,
            icon: const Icon(Icons.refresh_rounded, color: _T.textSecondary),
            splashRadius: 22,
          ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 46,
              decoration: BoxDecoration(
                color: _searchHasFocus ? _T.surface : _T.searchFill,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: _searchHasFocus ? _T.primary : Colors.transparent,
                  width: 1.4,
                ),
                boxShadow: _searchHasFocus
                    ? [
                        BoxShadow(
                          color: _T.primary.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: const TextStyle(fontSize: 14, color: _T.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by patient name, ID, or status...',
                  hintStyle: TextStyle(
                    color: _T.textMuted,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _searchHasFocus ? _T.primary : _T.textMuted,
                    size: 21,
                  ),
                  suffixIcon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: _searchQuery.isNotEmpty
                        ? IconButton(
                            key: const ValueKey('clear'),
                            onPressed: _clearSearch,
                            icon: const Icon(
                              Icons.close_rounded,
                              color: _T.textMuted,
                              size: 19,
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (visitController.isLoading.value && visitController.visits.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_T.primary),
            ),
          );
        }

        if (visitController.errorMessage.isNotEmpty && visitController.visits.isEmpty) {
          return _buildErrorState();
        }

        if (filteredVisits.isEmpty) {
          return _buildEmptyState();
        }

        return AnimationLimiter(
          child: RefreshIndicator(
            color: _T.primary,
            onRefresh: visitController.refreshVisits,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredVisits.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 450),
                  child: SlideAnimation(
                    verticalOffset: 40.0,
                    curve: Curves.easeOutCubic,
                    child: FadeInAnimation(
                      child: _buildVisitCard(filteredVisits[index], index),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: _T.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: _T.primary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Error loading patients',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: _T.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              visitController.errorMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _T.textSecondary),
            ),
          ),
          const SizedBox(height: 20),
          _buildPillButton(
            label: 'Try Again',
            icon: Icons.refresh_rounded,
            onTap: visitController.refreshVisits,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: _T.searchFill,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 44,
              color: _T.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No patients found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: _T.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your search terms',
            style: TextStyle(fontSize: 13, color: _T.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_T.primary, _T.primaryDark],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: _T.primary.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisitCard(Visit visit, int index) {
    final patient = visit.patient;
    final statusColor = _getStatusColor(visit.status ?? '');
    final avatarColors = _avatarPalette[index % _avatarPalette.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _PressableCard(
        onTap: () {
          Get.snackbar(
            'Visit Details',
            'Loading visit ${visit.id}...',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: _T.textPrimary,
            colorText: Colors.white,
          );
          // Navigate to visit details
          Get.toNamed(
            '/patient-visit-details',
            arguments: {'visitId': visit.id},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: avatarColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        patient?.initials ?? 'P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient?.fullName ?? 'Unknown Patient',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _T.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              'ID: ${visit.attendanceType ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _T.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: _T.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${patient?.age ?? '?'} yrs • ${patient?.gender ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _T.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(visit.status ?? ''),
                          color: statusColor,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          visit.status ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Details Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (patient?.bloodType != null)
                    _buildDetailChip(
                      Icons.bloodtype_rounded,
                      'Blood: ${patient?.bloodType}',
                      const Color(0xFFE0656B),
                    ),
                  _buildDetailChip(
                    Icons.medical_services_rounded,
                    visit.visitType ?? 'General Visit',
                    _T.primary,
                  ),
                  _buildDetailChip(
                    Icons.calendar_today_rounded,
                    _formatDate(visit.createdAt),
                    const Color(0xFF5B8DEF),
                  ),
                  if (visit.department?.name != null)
                    _buildDetailChip(
                      Icons.business_rounded,
                      visit.department?.name ?? '',
                      const Color(0xFF8B7FD1),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return _T.primary;
      case 'completed':
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle_rounded;
      case 'completed':
        return Icons.check_circle_outline_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'scheduled':
        return Icons.calendar_today_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// A card wrapper that scales down slightly on press, in addition to the
/// standard ink splash — gives list items a tactile, polished feel.
class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableCard({required this.child, required this.onTap});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _T.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              splashColor: _T.primary.withOpacity(0.08),
              highlightColor: _T.primary.withOpacity(0.04),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}