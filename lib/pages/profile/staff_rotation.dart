// lib/app/modules/staff_rotation/views/staff_rotation_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:intl/intl.dart';

import 'package:doctor_app/services/session_service.dart';
import '../../services/api/staff_rotation_api.dart';

/// Shared design tokens — mint/teal palette
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
  static const shadow = Color(0xFF000000);
  static const danger = Color(0xFFE0656B);
  static const warning = Color(0xFFE0A94A);

  // Shift colors
  static const morning = Color(0xFFF59E0B);
  static const afternoon = Color(0xFF3B82F6);
  static const night = Color(0xFF8B5CF6);
  static const onDuty = Color(0xFF10B981);
}

class StaffShift {
  final String id;
  final String day;
  final String shift;
  final String startTime;
  final String endTime;
  final String? department;
  final String? staffName;
  final String? status;

  StaffShift({
    required this.id,
    required this.day,
    required this.shift,
    required this.startTime,
    required this.endTime,
    this.department,
    this.staffName,
    this.status,
  });

  factory StaffShift.fromJson(Map<String, dynamic> json) {
    return StaffShift(
      id: json['id']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      shift: json['shift']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? json['start_time']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? json['end_time']?.toString() ?? '',
      department: json['department']?.toString() ?? json['department_name']?.toString(),
      staffName: json['staffName']?.toString() ?? json['staff_name']?.toString(),
      status: json['status']?.toString() ?? 'Active',
    );
  }
}

class StaffRotation extends StatefulWidget {
  const StaffRotation({super.key});

  @override
  State<StaffRotation> createState() => _StaffRotationState();
}

class _StaffRotationState extends State<StaffRotation> with TickerProviderStateMixin {
  final SessionService sessionService = Get.find<SessionService>();
  final StaffRotationApi api = StaffRotationApi();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  bool isLoading = false;
  String? errorMessage;
  List<StaffShift> shifts = [];

  // Filter state
  String _filterType = 'all';
  String _searchQuery = '';

  // Current time for progress updates
  Timer? _timer;

  // Get current day
  String get _currentDay {
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[now.weekday - 1];
  }

  String get _currentDate {
    return DateFormat('dd MMM yyyy').format(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    fetchStaffShifts();

    // Update progress every 30 seconds for smooth updates
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchStaffShifts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await api.fetchStaffShifts(sessionService: sessionService);
      setState(() {
        shifts = result.map((shift) => StaffShift(
          id: '${shift.day}-${shift.shift}-${shift.startTime}-${shift.endTime}',
          day: shift.day,
          shift: shift.shift,
          startTime: shift.startTime,
          endTime: shift.endTime,
        )).toList();
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
      _refreshController.refreshCompleted();
    }
  }

  List<StaffShift> get _filteredShifts {
    var filtered = shifts;

    if (_filterType != 'all') {
      filtered = filtered.where((s) => s.shift.toLowerCase() == _filterType.toLowerCase()).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((s) =>
        s.day.toLowerCase().contains(query) ||
        s.shift.toLowerCase().contains(query) ||
        (s.department?.toLowerCase().contains(query) ?? false) ||
        (s.staffName?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    // Sort with current day first
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    filtered.sort((a, b) {
      if (a.day == _currentDay) return -1;
      if (b.day == _currentDay) return 1;
      final indexA = days.indexOf(a.day);
      final indexB = days.indexOf(b.day);
      return indexA.compareTo(indexB);
    });

    return filtered;
  }

  Map<String, List<StaffShift>> get _groupedShifts {
    final grouped = <String, List<StaffShift>>{};
    for (final shift in _filteredShifts) {
      grouped.putIfAbsent(shift.day, () => []).add(shift);
    }
    return grouped;
  }

  Color _getShiftColor(String shift) {
    switch (shift.toLowerCase()) {
      case 'morning':
        return _T.morning;
      case 'afternoon':
        return _T.afternoon;
      case 'night':
        return _T.night;
      default:
        return _T.textSecondary;
    }
  }

  String _getShiftEmoji(String shift) {
    switch (shift.toLowerCase()) {
      case 'morning':
        return '🌅';
      case 'afternoon':
        return '☀️';
      case 'night':
        return '🌙';
      default:
        return '📋';
    }
  }

  ShiftTimeInfo _calculateShiftTimeInfo(StaffShift shift) {
    try {
      final now = DateTime.now();
      final startParts = shift.startTime.split(':');
      final endParts = shift.endTime.split(':');

      final start = DateTime(
        now.year, now.month, now.day,
        int.parse(startParts[0]), int.parse(startParts[1]),
      );
      final end = DateTime(
        now.year, now.month, now.day,
        int.parse(endParts[0]), int.parse(endParts[1]),
      );

      // Handle night shifts (end time before start time)
      final endAdjusted = end.isBefore(start) ? end.add(const Duration(days: 1)) : end;
      final totalDuration = endAdjusted.difference(start).inMinutes;
      
      if (totalDuration <= 0) {
        return ShiftTimeInfo(
          progress: 0,
          isActive: false,
          remainingTime: '',
          status: ShiftStatus.notStarted,
        );
      }

      final elapsed = now.difference(start).inMinutes;
      final progress = (elapsed / totalDuration).clamp(0.0, 1.0);
      final isActive = now.isAfter(start) && now.isBefore(endAdjusted);
      final remaining = endAdjusted.difference(now);

      String remainingTime;
      ShiftStatus status;
      
      if (!isActive && now.isBefore(start)) {
        status = ShiftStatus.notStarted;
        final timeToStart = start.difference(now);
        remainingTime = 'Starts in ${timeToStart.inHours}h ${timeToStart.inMinutes.remainder(60)}m';
      } else if (isActive) {
        if (progress >= 0.85) {
          status = ShiftStatus.endingSoon;
          remainingTime = '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m left';
        } else {
          status = ShiftStatus.active;
          remainingTime = '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m left';
        }
      } else {
        status = ShiftStatus.completed;
        remainingTime = 'Completed';
      }

      return ShiftTimeInfo(
        progress: progress,
        isActive: isActive,
        remainingTime: remainingTime,
        status: status,
        startTime: start,
        endTime: endAdjusted,
        totalMinutes: totalDuration,
        elapsedMinutes: elapsed,
      );
    } catch (e) {
      return ShiftTimeInfo(
        progress: 0,
        isActive: false,
        remainingTime: '',
        status: ShiftStatus.unknown,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_T.primary, _T.primaryDark]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Staff Rotation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _T.textPrimary,
                  ),
                ),
                Text(
                  '${shifts.length} shifts • $_currentDate',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _T.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: _T.textSecondary),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: _T.textSecondary),
            onPressed: fetchStaffShifts,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _T.border),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_filterType != 'all' || _searchQuery.isNotEmpty)
            _buildFilterChips(),
          Expanded(
            child: Builder(
              builder: (context) {
                if (isLoading && shifts.isEmpty) {
                  return _buildShimmerLoading();
                }
                if (errorMessage != null) {
                  return _buildErrorState();
                }
                if (shifts.isEmpty) {
                  return _buildEmptyState();
                }

                final groupedShifts = _groupedShifts;
                if (groupedShifts.isEmpty) {
                  return _buildNoResultsState();
                }

                return SmartRefresher(
                  controller: _refreshController,
                  onRefresh: fetchStaffShifts,
                  enablePullDown: true,
                  header: WaterDropHeader(
                    waterDropColor: _T.primary,
                    complete: Icon(Icons.check_circle_rounded, color: _T.primary),
                    failed: const Icon(Icons.error_rounded, color: _T.danger),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: groupedShifts.keys.length,
                    itemBuilder: (context, index) {
                      final day = groupedShifts.keys.elementAt(index);
                      final dayShifts = groupedShifts[day]!;
                      return _buildDaySection(day, dayShifts);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _T.surface,
        border: Border(bottom: BorderSide(color: _T.border, width: 1)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _T.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _T.border),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search shifts, departments...',
            hintStyle: TextStyle(fontSize: 13.5, color: _T.textMuted),
            prefixIcon: Icon(Icons.search_rounded, color: _T.textMuted, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, color: _T.textMuted, size: 18),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _T.surface,
        border: Border(bottom: BorderSide(color: _T.border, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_filterType != 'all')
              _buildFilterChipBadge(
                label: 'Shift: $_filterType',
                color: _T.primary,
                onClear: () => setState(() => _filterType = 'all'),
              ),
            if (_searchQuery.isNotEmpty) ...[
              if (_filterType != 'all') const SizedBox(width: 8),
              _buildFilterChipBadge(
                label: 'Search: $_searchQuery',
                color: _T.afternoon,
                onClear: () => setState(() => _searchQuery = ''),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChipBadge({
    required String label,
    required Color color,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close_rounded, size: 14, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(String day, List<StaffShift> shifts) {
    final bool isToday = day == _currentDay;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? _T.primary : _T.border,
          width: isToday ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isToday ? _T.primary.withOpacity(0.12) : _T.shadow.withOpacity(0.03),
            blurRadius: isToday ? 16 : 8,
            offset: Offset(0, isToday ? 4 : 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayHeader(day, isToday, shifts.length),
          ...shifts.map((shift) => _buildShiftItem(shift, isToday)),
        ],
      ),
    );
  }

  Widget _buildDayHeader(String day, bool isToday, int shiftCount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isToday ? _T.primarySoft : _T.bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(color: isToday ? _T.primary.withOpacity(0.2) : _T.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isToday ? _T.primary : _T.textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isToday ? Icons.today_rounded : Icons.calendar_today_rounded,
              size: 16,
              color: isToday ? _T.primary : _T.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            day,
            style: TextStyle(
              fontSize: isToday ? 16 : 15,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w700,
              color: isToday ? _T.primary : _T.textPrimary,
            ),
          ),
          if (isToday) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _T.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Today',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _T.surface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _currentDate,
              style: TextStyle(
                fontSize: 11,
                color: _T.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isToday ? _T.primary.withOpacity(0.1) : _T.textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$shiftCount shift${shiftCount > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isToday ? _T.primary : _T.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftItem(StaffShift shift, bool isToday) {
    final shiftColor = _getShiftColor(shift.shift);
    final timeInfo = _calculateShiftTimeInfo(shift);
    final isActive = isToday && timeInfo.isActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _T.border.withOpacity(0.5), width: 1),
        ),
        color: isActive ? _T.primarySoft.withOpacity(0.2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Time
              Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: _T.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _T.border),
                ),
                child: Column(
                  children: [
                    Text(
                      shift.startTime,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _T.textPrimary,
                      ),
                    ),
                    Container(
                      width: 16,
                      height: 1,
                      color: _T.textMuted,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                    Text(
                      shift.endTime,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _T.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Shift Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_getShiftEmoji(shift.shift), style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          shift.shift,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _T.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: shiftColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _T.onDuty.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: _T.onDuty,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'On Duty',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: _T.onDuty,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (shift.department != null && shift.department!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.business_rounded, size: 13, color: _T.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            shift.department!,
                            style: TextStyle(fontSize: 12, color: _T.textSecondary),
                          ),
                        ],
                      ),
                    if (shift.staffName != null && shift.staffName!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.person_rounded, size: 13, color: _T.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            shift.staffName!,
                            style: TextStyle(fontSize: 12, color: _T.textSecondary),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Status Badge
              _buildStatusBadge(shift, timeInfo),
            ],
          ),
          // Time Progress Section - Enhanced
          if (isToday && timeInfo.isActive) ...[
            const SizedBox(height: 10),
            _buildTimeProgress(timeInfo),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(StaffShift shift, ShiftTimeInfo timeInfo) {
    Color badgeColor;
    String label;

    if (timeInfo.status == ShiftStatus.notStarted) {
      badgeColor = _T.warning;
      label = 'Upcoming';
    } else if (timeInfo.status == ShiftStatus.active) {
      badgeColor = _T.onDuty;
      label = 'Active';
    } else if (timeInfo.status == ShiftStatus.endingSoon) {
      badgeColor = _T.danger;
      label = 'Ending Soon';
    } else if (timeInfo.status == ShiftStatus.completed) {
      badgeColor = _T.textMuted;
      label = 'Completed';
    } else {
      badgeColor = _T.textSecondary;
      label = shift.status ?? 'N/A';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeProgress(ShiftTimeInfo timeInfo) {
    final isEndingSoon = timeInfo.status == ShiftStatus.endingSoon;
    final progressColor = isEndingSoon ? _T.danger : _T.primary;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _T.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Bar with Labels
          Row(
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _T.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${(timeInfo.progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: timeInfo.progress,
              backgroundColor: _T.border,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          // Time Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Started',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: _T.textMuted,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(timeInfo.startTime),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _T.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Elapsed',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: _T.textMuted,
                      ),
                    ),
                    Text(
                      _formatDuration(timeInfo.elapsedMinutes),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _T.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isEndingSoon ? 'Time Left' : 'Ends At',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: isEndingSoon ? _T.danger : _T.textMuted,
                      ),
                    ),
                    Text(
                      isEndingSoon ? timeInfo.remainingTime : DateFormat('HH:mm').format(timeInfo.endTime),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isEndingSoon ? _T.danger : _T.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Warning when ending soon
          if (isEndingSoon) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _T.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _T.danger.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.alarm_rounded, size: 14, color: _T.danger),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '⚠️ Shift ends in ${timeInfo.remainingTime}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _T.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: _T.border,
      highlightColor: _T.bg,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 180,
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 120, height: 16, color: Colors.white),
                const SizedBox(height: 12),
                Container(width: 80, height: 14, color: Colors.white),
                const Spacer(),
                Container(height: 8, color: Colors.white),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Container(height: 12, color: Colors.white)),
                    const SizedBox(width: 8),
                    Expanded(child: Container(height: 12, color: Colors.white)),
                    const SizedBox(width: 8),
                    Expanded(child: Container(height: 12, color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _T.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 48, color: _T.danger),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to Load Shifts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _T.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Please try again',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _T.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: fetchStaffShifts,
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _T.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calendar_today_rounded, size: 48, color: _T.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No Shifts Assigned',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _T.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have no shifts assigned for this week',
              style: TextStyle(fontSize: 14, color: _T.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _T.textMuted.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded, size: 48, color: _T.textMuted),
            ),
            const SizedBox(height: 20),
            Text(
              'No shifts match your filters',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _T.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or clear filters',
              style: TextStyle(fontSize: 14, color: _T.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterType = 'all';
                  _searchQuery = '';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Clear Filters',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _T.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.filter_list_rounded, size: 18, color: _T.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  'Filter by Shift',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _T.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('All Shifts', 'all'),
                _buildFilterChip('🌅 Morning', 'morning'),
                _buildFilterChip('☀️ Afternoon', 'afternoon'),
                _buildFilterChip('🌙 Night', 'night'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Apply Filter',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
        setState(() {
          _filterType = value;
        });
        Get.back();
      },
      backgroundColor: _T.bg,
      selectedColor: _T.primarySoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? _T.primary : _T.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      labelStyle: TextStyle(
        color: isSelected ? _T.primary : _T.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

// Helper classes for time information
enum ShiftStatus {
  notStarted,
  active,
  endingSoon,
  completed,
  unknown,
}

class ShiftTimeInfo {
  final double progress;
  final bool isActive;
  final String remainingTime;
  final ShiftStatus status;
  final DateTime startTime;
  final DateTime endTime;
  final int totalMinutes;
  final int elapsedMinutes;

  ShiftTimeInfo({
    required this.progress,
    required this.isActive,
    required this.remainingTime,
    required this.status,
    DateTime? startTime,
    DateTime? endTime,
    this.totalMinutes = 0,
    this.elapsedMinutes = 0,
  }) : startTime = startTime ?? DateTime.now(),
       endTime = endTime ?? DateTime.now();
}