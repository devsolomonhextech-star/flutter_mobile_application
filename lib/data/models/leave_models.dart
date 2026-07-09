class LeaveRequestModel {
  final String? id;
  final String? leaveType;
  final String? startDate;
  final String? endDate;
  final int? durationDays;
  final String? reason;
  final String? emergencyContact;
  final String? documentUrl;
  final String? status;
  final String? rejectionReason;
  final String? approvedById;

  const LeaveRequestModel({
    this.id,
    this.leaveType,
    this.startDate,
    this.endDate,
    this.durationDays,
    this.reason,
    this.emergencyContact,
    this.documentUrl,
    this.status,
    this.rejectionReason,
    this.approvedById,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: (json['id'] ?? json['leaveId'])?.toString(),
      leaveType: json['leaveType']?.toString() ?? json['leave_type']?.toString(),
      startDate: (json['startDate'] ?? json['start_date'])?.toString(),
      endDate: (json['endDate'] ?? json['end_date'])?.toString(),
      durationDays: json['durationDays'] != null
          ? int.tryParse(json['durationDays'].toString())
          : (json['duration_days'] != null
              ? int.tryParse(json['duration_days'].toString())
              : null),
      reason: json['reason']?.toString(),
      emergencyContact:
          json['emergencyContact']?.toString() ?? json['emergency_contact']?.toString(),
      documentUrl: (json['documentUrl'] ?? json['document_url'])?.toString(),
      status: json['status']?.toString(),
      rejectionReason: json['rejectionReason']?.toString() ?? json['rejection_reason']?.toString(),
      approvedById: (json['approvedById'] ?? json['approved_by_id'])?.toString(),
    );
  }

  bool get canCancel => status == 'Pending';
}

