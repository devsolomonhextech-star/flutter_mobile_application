import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../services/api/leave_api.dart';
import '../../data/models/leave_models.dart';
import '../../services/session_service.dart';

class LeaveRequest extends StatefulWidget {
  const LeaveRequest({super.key});

  @override
  State<LeaveRequest> createState() => _LeaveRequestState();
}

class _LeaveRequestState extends State<LeaveRequest> {
  final SessionService _session = Get.find<SessionService>();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _leaveTypeController = TextEditingController();
  final _reasonController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _documentUrlController = TextEditingController();

  // Date selection
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));

  // State variables
  bool _submitting = false;
  bool _loadingLeaves = false;
  List<LeaveRequestModel> _myLeaves = [];
  
  // Filter
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadMyLeaves();
  }

  @override
  void dispose() {
    _leaveTypeController.dispose();
    _reasonController.dispose();
    _emergencyController.dispose();
    _documentUrlController.dispose();
    super.dispose();
  }

  String _dateToApi(DateTime d) => d.toIso8601String();

  Future<void> _loadMyLeaves() async {
    setState(() => _loadingLeaves = true);
    try {
      final items = await LeaveApi.getMyLeaves();
      _myLeaves = (items)
          .whereType<Map<String, dynamic>>()
          .map((e) => LeaveRequestModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Failed to load my leaves: $e');
      _myLeaves = [];
    } finally {
      if (mounted) setState(() => _loadingLeaves = false);
    }
  }

  List<LeaveRequestModel> get _filteredLeaves {
    if (_selectedFilter == 'All') return _myLeaves;
    return _myLeaves.where((item) {
      final status = item.status?.toLowerCase() ?? '';
      return status == _selectedFilter.toLowerCase();
    }).toList();
  }

  int get _pendingCount => 
      _myLeaves.where((item) => item.status?.toLowerCase() == 'pending').length;

  int get _approvedCount => 
      _myLeaves.where((item) => item.status?.toLowerCase() == 'approved').length;

  int get _rejectedCount => 
      _myLeaves.where((item) => item.status?.toLowerCase() == 'rejected').length;

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate.add(const Duration(days: 1));
      }
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _endDate = picked);
  }

  Future<void> _submitRequest() async {
    final userId = _session.userId;
    if (userId == null || userId.isEmpty) {
      _showSnackbar('Session error', 'Staff not found. Please login again.', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      await LeaveApi.requestLeave(
        leaveType: _leaveTypeController.text.trim(),
        startDate: _dateToApi(_startDate),
        endDate: _dateToApi(_endDate),
        reason: _reasonController.text.trim(),
        emergencyContact: _emergencyController.text.trim(),
        documentUrl: _documentUrlController.text.trim().isEmpty
            ? null
            : _documentUrlController.text.trim(),
      );

      _showSnackbar('Success! 🎉', 'Your leave request has been submitted');
      _clearForm();
      await _loadMyLeaves();
      Get.back(); // Close the dialog
    } catch (e) {
      _showSnackbar('Request failed', e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _clearForm() {
    _leaveTypeController.clear();
    _reasonController.clear();
    _emergencyController.clear();
    _documentUrlController.clear();
    setState(() {
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 1));
    });
  }

  Future<void> _cancelLeave(LeaveRequestModel item) async {
    if (!item.canCancel) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Cancel Leave Request?'),
          ],
        ),
        content: const Text(
          'This action cannot be undone. Are you sure you want to cancel this pending leave request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await LeaveApi.cancelLeave(leaveId: item.id ?? '');
      _showSnackbar('Cancelled', 'Leave request cancelled successfully');
      await _loadMyLeaves();
    } catch (e) {
      _showSnackbar('Cancel failed', e.toString(), isError: true);
    }
  }

  void _showSnackbar(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.red.shade50 : Colors.green.shade50,
      colorText: isError ? Colors.red.shade900 : Colors.green.shade900,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  void _showLeaveFormDialog() {
    // Reset form when opening dialog
    _clearForm();
    _formKey.currentState?.reset();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.white, // White background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: Icon(
                        Icons.add_comment_outlined,
                        color: Colors.blue.shade700,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'New Leave Request',
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
                const SizedBox(height: 16),

                // Form Fields with Expanded to scroll
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Leave Type
                        TextFormField(
                          controller: _leaveTypeController,
                          decoration: InputDecoration(
                            labelText: 'Leave Type',
                            hintText: 'e.g. Annual, Sick, Maternity',
                            prefixIcon: Icon(
                              Icons.assignment_outlined,
                              color: Colors.grey.shade500,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter leave type';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Date Pickers
                        Row(
                          children: [
                            Expanded(
                              child: _buildDatePicker(
                                label: 'Start Date',
                                date: _startDate,
                                onTap: _pickStartDate,
                                icon: Icons.calendar_today_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDatePicker(
                                label: 'End Date',
                                date: _endDate,
                                onTap: _pickEndDate,
                                icon: Icons.calendar_today_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Reason
                        TextFormField(
                          controller: _reasonController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Reason',
                            hintText: 'Please provide a detailed reason...',
                            prefixIcon: Icon(
                              Icons.description_outlined,
                              color: Colors.grey.shade500,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            alignLabelWithHint: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter a reason';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Emergency Contact
                        TextFormField(
                          controller: _emergencyController,
                          decoration: InputDecoration(
                            labelText: 'Emergency Contact',
                            hintText: 'Phone number or email',
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              color: Colors.grey.shade500,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter emergency contact';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Document URL (Optional)
                        TextFormField(
                          controller: _documentUrlController,
                          decoration: InputDecoration(
                            labelText: 'Document URL (Optional)',
                            hintText: 'https://drive.google.com/...',
                            prefixIcon: Icon(
                              Icons.link_outlined,
                              color: Colors.grey.shade500,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Submitting...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_outlined, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Submit Request',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String? status) {
    final s = (status ?? '').toLowerCase();
    switch (s) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.blueGrey;
    }
  }

  String _getStatusIcon(String? status) {
    final s = (status ?? '').toLowerCase();
    switch (s) {
      case 'pending': return '⏳';
      case 'approved': return '✅';
      case 'rejected': return '❌';
      case 'cancelled': return '🚫';
      default: return '📋';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateStr.split('T').first;
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => setState(() => _selectedFilter = value),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Leave Management',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade900,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadMyLeaves,
            icon: Icon(Icons.refresh, color: Colors.grey.shade600),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLeaveFormDialog,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              _buildStatsRow(),
              const SizedBox(height: 20),

              // My Leaves Section
              _buildMyLeavesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Pending',
            _pendingCount.toString(),
            '⏳',
            Colors.orange.shade50,
            Colors.orange.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Approved',
            _approvedCount.toString(),
            '✅',
            Colors.green.shade50,
            Colors.green.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Rejected',
            _rejectedCount.toString(),
            '❌',
            Colors.red.shade50,
            Colors.red.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String count,
    String icon,
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
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(date),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildMyLeavesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              '${_filteredLeaves.length} requests',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Filter Chips
        SingleChildScrollView(
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
        ),
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
            child: _loadingLeaves
                ? _buildShimmerLoading()
                : _filteredLeaves.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedFilter == 'All'
                                  ? 'No leave requests yet'
                                  : 'No ${_selectedFilter.toLowerCase()} requests',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the + button to request leave',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _filteredLeaves.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, index) {
                          final item = _filteredLeaves[index];
                          final status = item.status ?? 'Pending';
                          final statusColor = _statusColor(status);

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: statusColor,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status Icon
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getStatusIcon(status),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.leaveType ?? 'Leave Request',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_formatDate(item.startDate)} → ${_formatDate(item.endDate)}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (item.reason != null &&
                                          item.reason!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.reason!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Status & Actions
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: statusColor.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (item.canCancel) ...[
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: () => _cancelLeave(item),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.cancel_outlined,
                                                size: 14,
                                                color: Colors.red.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.red.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  // Shimmer Loading Widget
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(
          4,
          (index) => Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                // Icon placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                // Text placeholders
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status placeholder
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
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