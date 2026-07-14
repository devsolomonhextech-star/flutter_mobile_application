class DoctorAppointment {
  final String id;
  final String doctorId;
  final String patientId;
  final String patient;
  final String date;
  final String time;
  final String status;
  final String? reason;
  final String? type;


  DoctorAppointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.patient,
    required this.date,
    required this.time,
    required this.status,
    this.reason,
    this.type,
  });


  factory DoctorAppointment.fromJson(Map<String,dynamic> json){
    return DoctorAppointment(
      id: json['id'].toString(),
      doctorId: json['doctor_id'].toString(),
      patientId: json['patient_id'].toString(),
      patient: json['patient'] ?? 'Unknown',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? 'pending',
      reason: json['reason'],
      type: json['type'],
    );
  }
}