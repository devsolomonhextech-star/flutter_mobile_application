import 'package:doctor_app/data/models/leave_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeline_tile/timeline_tile.dart';

class LeaveListSection extends StatelessWidget {
  final bool loadingLeaves;
  final List<LeaveRequestModel> filteredLeaves;
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final Function(LeaveRequestModel) onCancelLeave;

  const LeaveListSection({
    super.key,
    required this.loadingLeaves,
    required this.filteredLeaves,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onCancelLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        _buildFilterChips(),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: loadingLeaves
                ? _buildShimmerLoading()
                : filteredLeaves.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: filteredLeaves.length,
                    itemBuilder: (context, index) {
                      final item = filteredLeaves[index];
                      return _buildTimelineItem(item, index);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.history_outlined,
                color: Colors.blue.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'My Leave History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
          ],
        ),
        Text(
          '${filteredLeaves.length} requests',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', 'All'),
          const SizedBox(width: 8),
          _buildFilterChip('Pending', 'Pending'),
          const SizedBox(width: 8),
          _buildFilterChip('Approved', 'Approved'),
          const SizedBox(width: 8),
          _buildFilterChip('Rejected', 'Rejected'),
          const SizedBox(width: 8),
          _buildFilterChip('Cancelled', 'Cancelled'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => onFilterChanged(value),
      backgroundColor: Colors.white,
      selectedColor: Colors.blue.shade50,
      checkmarkColor: Colors.blue.shade700,
      side: BorderSide(
        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
        width: isSelected ? 2 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      shape: const StadiumBorder(),
    );
  }

  Widget _buildTimelineItem(LeaveRequestModel item, int index) {
    final isLast = index == filteredLeaves.length - 1;
    final isFirst = index == 0;
    final status = item.status?.toLowerCase() ?? 'pending';

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        statusLabel = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        statusLabel = 'Rejected';
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.cancel_outlined;
        statusLabel = 'Cancelled';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_outlined;
        statusLabel = 'Pending';
    }

    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      alignment: TimelineAlign.start,
      indicatorStyle: IndicatorStyle(
        width: 14,
        height: 14,
        indicator: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            border: Border.all(color: statusColor.withOpacity(0.3), width: 3),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
      endChild: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
        child: _buildLeaveCard(item, statusColor, statusIcon, statusLabel),
      ),
    );
  }

  Widget _buildLeaveCard(
    LeaveRequestModel item,
    Color statusColor,
    IconData statusIcon,
    String statusLabel,
  ) {
    final startDateTime = item.startDate != null
        ? DateTime.tryParse(item.startDate!)
        : null;
    final endDateTime = item.endDate != null
        ? DateTime.tryParse(item.endDate!)
        : null;
    final startDate = startDateTime != null
        ? DateFormat('MMM d').format(startDateTime)
        : 'N/A';
    final endDate = endDateTime != null
        ? DateFormat('MMM d, yyyy').format(endDateTime)
        : 'N/A';
    final days = item.durationDays ?? 1;
    final leaveType = item.leaveType ?? 'Leave';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Leave Type Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getLeaveTypeIcon(leaveType),
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leaveType,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$startDate - $endDate',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
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
          Row(
            children: [
              // Duration Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$days day${days > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Reason
              if (item.reason != null && item.reason!.isNotEmpty)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.reason!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),

              // Cancel Button
              if (_canCancel(item))
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => onCancelLeave(item),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.close_outlined,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getLeaveTypeIcon(String leaveType) {
    switch (leaveType.toLowerCase()) {
      case 'annual leave':
        return Icons.beach_access_outlined;
      case 'sick leave':
        return Icons.medical_services_outlined;
      case 'emergency leave':
        return Icons.warning_amber_outlined;
      case 'maternity leave':
        return Icons.family_restroom_outlined;
      case 'paternity leave':
        return Icons.man_outlined;
      case 'study leave':
        return Icons.school_outlined;
      case 'unpaid leave':
        return Icons.money_off_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  bool _canCancel(LeaveRequestModel item) {
    final status = item.status?.toLowerCase() ?? '';
    return status == 'pending' || status == 'submitted';
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            selectedFilter == 'All'
                ? 'No leave requests yet'
                : 'No ${selectedFilter.toLowerCase()} requests',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap the + button to request leave',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(
          4,
          (index) => Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
