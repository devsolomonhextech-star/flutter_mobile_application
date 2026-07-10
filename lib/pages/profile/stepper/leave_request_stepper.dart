// leave_request_stepper.dart
import 'package:doctor_app/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ==================== DATA MODEL ====================
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

// ==================== MAIN STEPPER WIDGET ====================
class LeaveRequestStepper extends StatefulWidget {
  final SessionService session;
  final Function(LeaveFormData) onSubmit;

  const LeaveRequestStepper({
    super.key,
    required this.session,
    required this.onSubmit,
  });

  @override
  State<LeaveRequestStepper> createState() => _LeaveRequestStepperState();
}

class _LeaveRequestStepperState extends State<LeaveRequestStepper> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _errorMessage;

  // Form data
  final _formKey = GlobalKey<FormState>();
  final _leaveTypeController = TextEditingController();
  final _reasonController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _documentUrlController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));

  // Step data
  final List<StepData> _steps = [
    StepData(
      title: 'Leave Type',
      subtitle: 'Select the type of leave',
      icon: Icons.assignment_outlined,
    ),
    StepData(
      title: 'Date & Reason',
      subtitle: 'When and why',
      icon: Icons.calendar_today_outlined,
    ),
    StepData(
      title: 'Contact & Document',
      subtitle: 'Additional details',
      icon: Icons.contact_mail_outlined,
    ),
  ];

  @override
  void dispose() {
    _leaveTypeController.dispose();
    _reasonController.dispose();
    _emergencyController.dispose();
    _documentUrlController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _leaveTypeController.clear();
    _reasonController.clear();
    _emergencyController.clear();
    _documentUrlController.clear();
    setState(() {
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 1));
      _currentStep = 0;
      _isSuccess = false;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final data = LeaveFormData(
        leaveType: _leaveTypeController.text.trim(),
        startDate: _startDate.toIso8601String(),
        endDate: _endDate.toIso8601String(),
        reason: _reasonController.text.trim(),
        emergencyContact: _emergencyController.text.trim(),
        documentUrl: _documentUrlController.text.trim().isEmpty
            ? null
            : _documentUrlController.text.trim(),
      );

      await widget.onSubmit(data);

      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
        _currentStep = 3;
      });

      // Auto-close after success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Request Leave'),
      // ),
      body: SafeArea(
        child: Column(
              children: [
                // Header
                _buildHeader(),
                // Stepper
                Expanded(
                  child: _isSuccess 
                      ? _buildSuccessView()
                      : _buildStepperContent(),
                ),
                // Footer
                _buildFooter(),
              ],
            ),
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.assignment_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request Leave',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Complete all steps to submit your request',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (!_isSuccess)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== STEPPER CONTENT ====================
  Widget _buildStepperContent() {
    return Column(
      children: [
        // Step Progress
        _buildStepProgress(),
        const SizedBox(height: 8),
        // Step Content
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _getStepWidget(_currentStep),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(_steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          final step = _steps[index];

          return Expanded(
            child: Row(
              children: [
                // Step Circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.blue.shade700
                        : isCompleted
                        ? Colors.green.shade500
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.blue.shade200,
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, color: Colors.white, size: 18)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
                if (index < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: isCompleted
                          ? Colors.green.shade300
                          : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _getStepWidget(int step) {
    switch (step) {
      case 0:
        return _buildStep1LeaveType();
      case 1:
        return _buildStep2DateReason();
      case 2:
        return _buildStep3ContactDocument();
      default:
        return const SizedBox.shrink();
    }
  }

  // ==================== STEP 1: LEAVE TYPE ====================
  Widget _buildStep1LeaveType() {
    final leaveTypes = [
      'Annual Leave',
      'Sick Leave',
      'Emergency Leave',
      'Maternity Leave',
      'Paternity Leave',
      'Study Leave',
      'Unpaid Leave',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Leave Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the type of leave you want to request',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: leaveTypes.map((type) {
            final isSelected = _leaveTypeController.text == type;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _leaveTypeController.text = type;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.shade700
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.blue.shade700
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.blue.shade200,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getLeaveTypeIcon(type),
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_leaveTypeController.text.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select a leave type',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ),
      ],
    );
  }

  IconData _getLeaveTypeIcon(String type) {
    switch (type) {
      case 'Annual Leave':
        return Icons.beach_access_outlined;
      case 'Sick Leave':
        return Icons.medical_services_outlined;
      case 'Emergency Leave':
        return Icons.warning_amber_outlined;
      case 'Maternity Leave':
        return Icons.family_restroom_outlined;
      case 'Paternity Leave':
        return Icons.man_outlined;
      case 'Study Leave':
        return Icons.school_outlined;
      case 'Unpaid Leave':
        return Icons.money_off_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  // ==================== STEP 2: DATE & REASON ====================
  Widget _buildStep2DateReason() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date & Reason',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select the date range and provide a reason',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
        // Duration Badge
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                'Duration: ${_endDate.difference(_startDate).inDays + 1} day${_endDate.difference(_startDate).inDays + 1 > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Reason
        TextFormField(
          controller: _reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Reason',
            hintText: 'Please provide a detailed reason...',
            prefixIcon: Icon(
              Icons.description_outlined,
              color: Colors.grey.shade500,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
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

  // ==================== STEP 3: CONTACT & DOCUMENT ====================
  Widget _buildStep3ContactDocument() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact & Document',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Provide emergency contact and supporting documents',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        // Emergency Contact
        TextFormField(
          controller: _emergencyController,
          decoration: InputDecoration(
            labelText: 'Emergency Contact',
            hintText: 'Phone number or email',
            prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey.shade500),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        // Document URL
        TextFormField(
          controller: _documentUrlController,
          decoration: InputDecoration(
            labelText: 'Document URL (Optional)',
            hintText: 'https://drive.google.com/...',
            prefixIcon: Icon(Icons.link_outlined, color: Colors.grey.shade500),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 12),
        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📋 Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 8),
              _buildSummaryRow('Leave Type', _leaveTypeController.text),
              _buildSummaryRow(
                'Duration',
                '${_endDate.difference(_startDate).inDays + 1} day(s)',
              ),
              _buildSummaryRow(
                'Emergency Contact',
                _emergencyController.text.isEmpty
                    ? 'Not provided'
                    : _emergencyController.text,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not set' : value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: value.isEmpty
                    ? Colors.grey.shade400
                    : Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SUCCESS VIEW ====================
  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.shade200, width: 3),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 50,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Request Submitted!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your leave request has been sent for approval',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'You will be notified once it\'s approved',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ERROR VIEW ====================
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Submission Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An error occurred. Please try again.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isSubmitting = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== FOOTER ====================
  Widget _buildFooter() {
    if (_isSuccess || _errorMessage != null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentStep--);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentStep == _steps.length - 1
                  ? _submit
                  : () {
                      if (_currentStep == 0 &&
                          _leaveTypeController.text.isEmpty) {
                        // Show error for step 1
                        return;
                      }
                      setState(() => _currentStep++);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep == _steps.length - 1
                              ? 'Submit Request'
                              : 'Continue',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_currentStep != _steps.length - 1) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== STEP DATA MODEL ====================
class StepData {
  final String title;
  final String subtitle;
  final IconData icon;

  StepData({required this.title, required this.subtitle, required this.icon});
}
