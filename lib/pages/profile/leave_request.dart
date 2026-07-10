import 'package:doctor_app/pages/profile/stepper/leave_request_stepper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../services/api/leave_api.dart';
import '../../data/models/leave_models.dart';
import '../../services/session_service.dart';
import 'widgets/leave_stats_row.dart';
import 'widgets/leave_list_section.dart';

class LeaveRequest extends StatefulWidget {
  const LeaveRequest({super.key});

  @override
  State<LeaveRequest> createState() => _LeaveRequestState();
}

class _LeaveRequestState extends State<LeaveRequest> {
  final SessionService _session = Get.find<SessionService>();

  // State variables
  bool _loadingLeaves = false;
  List<LeaveRequestModel> _myLeaves = [];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadMyLeaves();
  }

  // Getters for stats
  int get _pendingCount =>
      _myLeaves.where((item) => item.status?.toLowerCase() == 'pending').length;

  int get _approvedCount => _myLeaves
      .where((item) => item.status?.toLowerCase() == 'approved')
      .length;

  int get _rejectedCount => _myLeaves
      .where((item) => item.status?.toLowerCase() == 'rejected')
      .length;

  List<LeaveRequestModel> get _filteredLeaves {
    if (_selectedFilter == 'All') return _myLeaves;
    return _myLeaves.where((item) {
      final status = item.status?.toLowerCase() ?? '';
      return status == _selectedFilter.toLowerCase();
    }).toList();
  }

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

  void _showLeaveFormDialog() {
    Get.to(
      () => LeaveRequestStepper(
        session: SessionService(),
        onSubmit: _handleSubmit,
      ),
    );
    
  }

  Future<void> _handleSubmit(LeaveFormData data) async {
    try {
      await LeaveApi.requestLeave(
        leaveType: data.leaveType,
        startDate: data.startDate,
        endDate: data.endDate,
        reason: data.reason,
        emergencyContact: data.emergencyContact,
        documentUrl: data.documentUrl,
      );

      _showSnackbar('Success! 🎉', 'Your leave request has been submitted');
      await _loadMyLeaves();
      Get.back(); // Close the dialog
    } catch (e) {
      _showSnackbar('Request failed', e.toString(), isError: true);
    }
  }

  Future<void> _cancelLeave(LeaveRequestModel item) async {
    if (!item.canCancel) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildCancelDialog(context),
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

  Widget _buildCancelDialog(BuildContext context) {
    return AlertDialog(
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
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LeaveStatsRow(
                pendingCount: _pendingCount,
                approvedCount: _approvedCount,
                rejectedCount: _rejectedCount,
              ),
              const SizedBox(height: 20),
              LeaveListSection(
                loadingLeaves: _loadingLeaves,
                filteredLeaves: _filteredLeaves,
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) =>
                    setState(() => _selectedFilter = filter),
                onCancelLeave: _cancelLeave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
