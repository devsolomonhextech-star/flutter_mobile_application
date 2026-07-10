import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'package:doctor_app/services/session_service.dart';
import '../../services/api/staff_rotation_api.dart';

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

class _StaffRotationState extends State<StaffRotation> {
  final SessionService sessionService = Get.find<SessionService>();
  final StaffRotationApi api = StaffRotationApi();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  bool isLoading = false;
  String? errorMessage;

  List<StaffShift> shifts = [];

  // Filter state
  String _filterType = 'all'; // 'all', 'morning', 'afternoon', 'night'
  String _searchQuery = '';

  // Get current day
  String get _currentDay {
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[now.weekday - 1];
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

  @override
  void initState() {
    super.initState();
    fetchStaffShifts();
  }

  List<StaffShift> get _filteredShifts {
    var filtered = shifts;

    // Filter by shift type
    if (_filterType != 'all') {
      filtered = filtered.where((s) => 
        s.shift.toLowerCase() == _filterType.toLowerCase()
      ).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((s) =>
        s.day.toLowerCase().contains(query) ||
        s.shift.toLowerCase().contains(query) ||
        (s.department?.toLowerCase().contains(query) ?? false) ||
        (s.staffName?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    // Sort by day (current day first)
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    filtered.sort((a, b) {
      // Put current day first
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

  String _getShiftColor(String shift) {
    switch (shift.toLowerCase()) {
      case 'morning':
        return '#F59E0B';
      case 'afternoon':
        return '#3B82F6';
      case 'night':
        return '#8B5CF6';
      default:
        return '#6B7280';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                color: Colors.blue.shade700,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staff Rotation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
                Text(
                  '${shifts.length} shifts assigned',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_outlined, color: Colors.grey.shade600),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey.shade600),
            onPressed: fetchStaffShifts,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Filter Chips
          if (_filterType != 'all' || _searchQuery.isNotEmpty)
            _buildFilterChips(),
          
          // Content
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
                  header: const WaterDropHeader(
                    waterDropColor: Colors.blue,
                    complete: Icon(Icons.check_circle, color: Colors.green),
                    failed: Icon(Icons.error, color: Colors.red),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
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
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search shifts...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey.shade500,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 18),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (_filterType != 'all')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Filter: $_filterType',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _filterType = 'all';
                      });
                    },
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          if (_searchQuery.isNotEmpty) ...[
            if (_filterType != 'all') const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Search: $_searchQuery',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.green.shade700,
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

  Widget _buildDaySection(String day, List<StaffShift> shifts) {
    final bool isToday = day == _currentDay;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? Colors.blue.shade300 : Colors.grey.shade200,
          width: isToday ? 2 : 1,
        ),
        boxShadow: [
          if (isToday)
            BoxShadow(
              color: Colors.blue.shade100,
              blurRadius: 12,
              spreadRadius: 2,
            )
          else
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
          // Day Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isToday ? Colors.blue.shade50 : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: isToday
                  ? Border(
                      bottom: BorderSide(color: Colors.blue.shade200, width: 1),
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isToday ? Icons.today : Icons.calendar_today,
                      color: isToday ? Colors.blue.shade700 : Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      day,
                      style: TextStyle(
                        fontSize: isToday ? 16 : 15,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w700,
                        color: isToday ? Colors.blue.shade700 : Colors.grey.shade800,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isToday ? Colors.blue.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${shifts.length} shift${shifts.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isToday ? Colors.blue.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Shifts
          ...shifts.map((shift) => _buildShiftItem(shift)),
        ],
      ),
    );
  }

  Widget _buildShiftItem(StaffShift shift) {
    final shiftColor = _getShiftColor(shift.shift);
    final shiftEmoji = _getShiftEmoji(shift.shift);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Time
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Text(
                  shift.startTime,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  'to',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey.shade400,
                  ),
                ),
                Text(
                  shift.endTime,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Shift Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      shiftEmoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      shift.shift,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(int.parse('0xFF${shiftColor.substring(1)}')),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                if (shift.department != null && shift.department!.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        shift.department!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                if (shift.staffName != null && shift.staffName!.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        shift.staffName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Status
          if (shift.status != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: shift.status?.toLowerCase() == 'active'
                    ? Colors.green.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: shift.status?.toLowerCase() == 'active'
                      ? Colors.green.shade200
                      : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: shift.status?.toLowerCase() == 'active'
                          ? Colors.green
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    shift.status!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: shift.status?.toLowerCase() == 'active'
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 14,
                  color: Colors.white,
                ),
                const Spacer(),
                Container(
                  width: 60,
                  height: 12,
                  color: Colors.white,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to Load Shifts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage ?? 'Please try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchStaffShifts,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Retry'),
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
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No Shifts Assigned',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no shifts assigned yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No shifts match your filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _filterType = 'all';
                _searchQuery = '';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Shift',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Morning', 'morning'),
                _buildFilterChip('Afternoon', 'afternoon'),
                _buildFilterChip('Night', 'night'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Apply'),
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
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}