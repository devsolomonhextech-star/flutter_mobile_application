import 'package:doctor_app/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeaveFormData {
  final String leaveType;
  final String startDate;
  final String endDate;
  final String reason;
  final String emergencyContact;
  final String? documentUrl;

  LeaveFormData({
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.emergencyContact,
    this.documentUrl,
  });
}

class LeaveFormDialog extends StatefulWidget {
  final SessionService session;
  final Function(LeaveFormData) onSubmit;

  const LeaveFormDialog({
    super.key,
    required this.session,
    required this.onSubmit,
  });

  @override
  State<LeaveFormDialog> createState() => _LeaveFormDialogState();
}

class _LeaveFormDialogState extends State<LeaveFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _leaveTypeController = TextEditingController();
  final _reasonController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _documentUrlController = TextEditingController();

  // Date selection
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));

  bool _submitting = false;

  @override
  void dispose() {
    _leaveTypeController.dispose();
    _reasonController.dispose();
    _emergencyController.dispose();
    _documentUrlController.dispose();
    super.dispose();
  }

  String _dateToApi(DateTime d) => d.toIso8601String();

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

  Future<void> _submit() async {
    final userId = widget.session.userId;
    if (userId == null || userId.isEmpty) {
      // Show error
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      await widget.onSubmit(
        LeaveFormData(
          leaveType: _leaveTypeController.text.trim(),
          startDate: _dateToApi(_startDate),
          endDate: _dateToApi(_endDate),
          reason: _reasonController.text.trim(),
          emergencyContact: _emergencyController.text.trim(),
          documentUrl: _documentUrlController.text.trim().isEmpty
              ? null
              : _documentUrlController.text.trim(),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
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
              _buildHeader(),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildFormFields(),
                ),
              ),
              const SizedBox(height: 12),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitting ? null : _submit,
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
    );
  }
}