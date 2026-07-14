// lib/data/models/visit_related_models.dart
class VitalSignsRecord {
  final String? id;
  final String? visitId;
  final int? temperature;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final int? heartRate;
  final int? respiratoryRate;
  final int? oxygenSaturation;
  final DateTime? recordedAt;

  VitalSignsRecord({
    this.id,
    this.visitId,
    this.temperature,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.heartRate,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.recordedAt,
  });

  factory VitalSignsRecord.fromJson(Map<String, dynamic> json) {
    return VitalSignsRecord(
      id: json['id'] as String?,
      visitId: json['visit_id'] as String?,
      temperature: json['temperature'] as int?,
      bloodPressureSystolic: json['bloodPressureSystolic'] as int?,
      bloodPressureDiastolic: json['bloodPressureDiastolic'] as int?,
      heartRate: json['heartRate'] as int?,
      respiratoryRate: json['respiratoryRate'] as int?,
      oxygenSaturation: json['oxygenSaturation'] as int?,
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visit_id': visitId,
      'temperature': temperature,
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'heartRate': heartRate,
      'respiratoryRate': respiratoryRate,
      'oxygenSaturation': oxygenSaturation,
      'recordedAt': recordedAt?.toIso8601String(),
    };
  }
}

// Add other related models (PatientNote, Claim, Prescription, etc.) similarly
class PatientNote {
  final String? id;
  final String? visitId;
  final String? note;
  final DateTime? createdAt;

  PatientNote({this.id, this.visitId, this.note, this.createdAt});

  factory PatientNote.fromJson(Map<String, dynamic> json) {
    return PatientNote(
      id: json['id'] as String?,
      visitId: json['visit_id'] as String?,
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visit_id': visitId,
      'note': note,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class Claim {
  final String? id;
  final String? visitId;
  final String? claimType;
  final double? amount;
  final DateTime? createdAt;

  Claim({this.id, this.visitId, this.claimType, this.amount, this.createdAt});

  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      id: json['id'] as String?,
      visitId: json['visit_id'] as String?,
      claimType: json['claimType'] as String?,
      amount: json['amount'] as double?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visit_id': visitId,
      'claimType': claimType,
      'amount': amount,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class Prescription {
  final String? id;
  final String? visitId;
  final String? medication;
  final String? dosage;
  final String? frequency;
  final DateTime? createdAt;

  Prescription({
    this.id,
    this.visitId,
    this.medication,
    this.dosage,
    this.frequency,
    this.createdAt,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] as String?,
      visitId: json['visit_id'] as String?,
      medication: json['medication'] as String?,
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visit_id': visitId,
      'medication': medication,
      'dosage': dosage,
      'frequency': frequency,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class LabTestResult {
  final String? id;
  final String? visitId;
  final String? testName;
  final String? result;
  final DateTime? createdAt;

  LabTestResult({
    this.id,
    this.visitId,
    this.testName,
    this.result,
    this.createdAt,
  });

  factory LabTestResult.fromJson(Map<String, dynamic> json) {
    return LabTestResult(
      id: json['id'] as String?,
      visitId: json['visit_id'] as String?,
      testName: json['testName'] as String?,
      result: json['result'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visit_id': visitId,
      'testName': testName,
      'result': result,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class Diagnosis {
  final String? id;
  final String? visitId;
  final String? diagnosis;
  final DateTime? createdAt;

  Diagnosis({this.id, this.visitId, this.diagnosis, this.createdAt});

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      id: json['id'] as String?,
      visitId: json['visit_id'] as String?,
      diagnosis: json['diagnosis'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visit_id': visitId,
      'diagnosis': diagnosis,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class Appointment {
  final String? id;
  final String? visitId;
  final DateTime? appointmentDate;
  final String? status;
  final DateTime? createdAt;

  Appointment({
    this.id,
    this.visitId,
    this.appointmentDate,
    this.status,
    this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String?,
      visitId: json['visit_id'] as String?,
      appointmentDate: json['appointmentDate'] != null
          ? DateTime.parse(json['appointmentDate'])
          : null,
      status: json['status'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visit_id': visitId,
      'appointmentDate': appointmentDate?.toIso8601String(),
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class Procedure {
  final String? id;
  final String? visitId;
  final String? procedureName;
  final DateTime? performedAt;
  final DateTime? createdAt;

  Procedure({
    this.id,
    this.visitId,
    this.procedureName,
    this.performedAt,
    this.createdAt,
  });

  factory Procedure.fromJson(Map<String, dynamic> json) {
    return Procedure(
      id: json['id'] as String?,
      visitId: json['visit_id'] as String?,
      procedureName: json['procedureName'] as String?,
      performedAt: json['performedAt'] != null
          ? DateTime.parse(json['performedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visit_id': visitId,
      'procedureName': procedureName,
      'performedAt': performedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}



class Invoice {
  final String? id;
  final String? visitId;
  final double? amount;
  final DateTime? issuedAt;
  final DateTime? createdAt;

  Invoice({
    this.id,
    this.visitId,
    this.amount,
    this.issuedAt,
    this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String?,
      visitId: json['visit_id'] as String?,
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      issuedAt: json['issuedAt'] != null
          ? DateTime.parse(json['issuedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visit_id': visitId,
      'amount': amount,
      'issuedAt': issuedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}


class Department {
  final String? id;
  final String? name;
  final String? code;

  Department({this.id, this.name, this.code});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as String?,
      name: json['name'] as String?,
      code: json['code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }
}


