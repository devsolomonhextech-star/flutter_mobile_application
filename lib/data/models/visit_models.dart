// lib/data/models/visit_models.dart

import 'package:doctor_app/data/models/institution_models.dart';
import 'package:doctor_app/data/models/patient_model.dart';
import 'package:doctor_app/data/models/visit_related_models.dart';

class Visit {
  final String? id;
  final String? institutionId;
  final String? departmentId;
  final String? patientId;

  final String? status;
  final String? attendanceType;
  final String? visitType;

  final bool? onAdmission;
  final String? bedNumber;
  final String? admissionStatus;

  final DateTime? visitDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;


  final Patient? patient;
  final Institution? institution;
  final Department? department;


  final List<Invoice>? invoices;

  final List<VitalSignsRecord>? vitalSignsRecords;
  final List<PatientNote>? patientNotes;
  final List<Claim>? claims;
  final List<Prescription>? prescriptions;
  final List<LabTestResult>? labTests;
  final List<Diagnosis>? diagnosis;
  final List<Appointment>? appointments;
  final List<Procedure>? procedures;



  Visit({
    this.id,
    this.institutionId,
    this.departmentId,
    this.patientId,

    this.status,
    this.attendanceType,
    this.visitType,

    this.onAdmission,
    this.bedNumber,
    this.admissionStatus,

    this.visitDate,
    this.createdAt,
    this.updatedAt,

    this.patient,
    this.institution,
    this.department,

    this.invoices,

    this.vitalSignsRecords,
    this.patientNotes,
    this.claims,
    this.prescriptions,
    this.labTests,
    this.diagnosis,
    this.appointments,
    this.procedures,
  });



  factory Visit.fromJson(Map<String, dynamic> json) {


    List<dynamic>? asList(dynamic value) {

      if (value == null) {
        return null;
      }


      if (value is List) {
        return value;
      }


      if (value is Map && value['items'] is List) {
        return value['items'];
      }


      return null;
    }



    return Visit(

      id: json['id'],

      institutionId: json['institution_id'],

      departmentId: json['department_id'],

      patientId: json['patient_id'],


      status: json['status'],


      attendanceType: json['attendance_type'],


      visitType: json['visit_type'],



      onAdmission: json['on_admission'],


      bedNumber: json['bed_number'],


      admissionStatus: json['admission_status'],



      visitDate: json['visit_date'] != null
          ? DateTime.tryParse(
              json['visit_date'].toString(),
            )
          : null,



      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(
              json['createdAt'].toString(),
            )
          : null,


      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(
              json['updatedAt'].toString(),
            )
          : null,




      patient: json['patient'] != null
          ? Patient.fromJson(
              json['patient'],
            )
          : null,



      institution: json['institution'] != null
          ? Institution.fromJson(
              json['institution'],
            )
          : null,



      department: json['department'] != null
          ? Department.fromJson(
              json['department'],
            )
          : null,




      invoices: asList(json['invoice'])
          ?.map(
            (e) => Invoice.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),





      vitalSignsRecords: asList(
        json['vitalSignsRecords'],
      )
          ?.map(
            (e) => VitalSignsRecord.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),




      patientNotes: asList(
        json['patientNotes'],
      )
          ?.map(
            (e) => PatientNote.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),





      claims: asList(
        json['claims'],
      )
          ?.map(
            (e) => Claim.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),





      prescriptions: asList(
        json['prescriptions'],
      )
          ?.map(
            (e) => Prescription.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),





      labTests: asList(
        json['labTests'],
      )
          ?.map(
            (e) => LabTestResult.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),




      diagnosis: asList(
        json['diagnosis'],
      )
          ?.map(
            (e) => Diagnosis.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),





      appointments: asList(
        json['appointments'],
      )
          ?.map(
            (e) => Appointment.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),





      procedures: asList(
        json['procedures'],
      )
          ?.map(
            (e) => Procedure.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),

    );
  }




  Map<String, dynamic> toJson() {

    return {

      "id": id,

      "institution_id": institutionId,

      "department_id": departmentId,

      "patient_id": patientId,


      "status": status,

      "attendance_type": attendanceType,

      "visit_type": visitType,


      "on_admission": onAdmission,

      "bed_number": bedNumber,

      "admission_status": admissionStatus,


      "visit_date": visitDate?.toIso8601String(),

      "createdAt": createdAt?.toIso8601String(),

      "updatedAt": updatedAt?.toIso8601String(),



      "patient": patient?.toJson(),

      "institution": institution?.toJson(),

      "department": department?.toJson(),



      "invoice":
          invoices?.map((e) => e.toJson()).toList(),


      "vitalSignsRecords":
          vitalSignsRecords
              ?.map((e) => e.toJson())
              .toList(),



      "patientNotes":
          patientNotes
              ?.map((e) => e.toJson())
              .toList(),



      "claims":
          claims
              ?.map((e) => e.toJson())
              .toList(),



      "prescriptions":
          prescriptions
              ?.map((e) => e.toJson())
              .toList(),



      "labTests":
          labTests
              ?.map((e) => e.toJson())
              .toList(),



      "diagnosis":
          diagnosis
              ?.map((e) => e.toJson())
              .toList(),



      "appointments":
          appointments
              ?.map((e) => e.toJson())
              .toList(),



      "procedures":
          procedures
              ?.map((e) => e.toJson())
              .toList(),

    };
  }
}