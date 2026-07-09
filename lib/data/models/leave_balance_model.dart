class LeaveBalanceModel {
  final String? leaveType;
  final int? year;
  final double? remaining;
  final double? taken;

  const LeaveBalanceModel({
    this.leaveType,
    this.year,
    this.remaining,
    this.taken,
  });

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceModel(
      leaveType: json['leaveType']?.toString() ?? json['leave_type']?.toString(),
      year: json['year'] != null ? int.tryParse(json['year'].toString()) : null,
      remaining: json['remaining'] != null
          ? double.tryParse(json['remaining'].toString())
          : null,
      taken: json['taken'] != null
          ? double.tryParse(json['taken'].toString())
          : null,
    );
  }
}

