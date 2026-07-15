import 'package:doctor_app/data/models/visit_models.dart';

class PatientLabVisit {
  final Visit visit;
  final List<LabTestResult> labResults;

  PatientLabVisit({
    required this.visit,
    required this.labResults,
  });

  factory PatientLabVisit.fromJson(Map<String, dynamic> json) {
    return PatientLabVisit(
      visit: Visit.fromJson(json['visit'] as Map<String, dynamic>),
      labResults: (json['labResults'] as List? ?? [])
          .map((e) => LabTestResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LabTestResult {
  final String? id;
  final String? status;
  final dynamic values;
  final String? notes;
  final DateTime? createdAt;

  final LabTestTemplate? template;

  LabTestResult({
    this.id,
    this.status,
    this.values,
    this.notes,
    this.createdAt,
    this.template,
  });

  factory LabTestResult.fromJson(Map<String, dynamic> json) {
    return LabTestResult(
      id: json['id']?.toString(),
      status: json['status']?.toString(),
      values: json['values'],
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      template: json['template'] != null
          ? LabTestTemplate.fromJson(
              (json['template'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }
}

class LabTestTemplate {
  final String? id;
  final String? description;
  final List<LabTestField> fields;

  LabTestTemplate({
    this.id,
    this.description,
    required this.fields,
  });

  factory LabTestTemplate.fromJson(Map<String, dynamic> json) {
    return LabTestTemplate(
      id: json['id']?.toString(),
      description: json['description']?.toString(),
      fields: (json['fields'] as List? ?? [])
          .map((e) => LabTestField.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LabTestField {
  final String? label;
  final String? fieldType;

  LabTestField({this.label, this.fieldType});

  factory LabTestField.fromJson(Map<String, dynamic> json) {
    return LabTestField(
      label: json['label']?.toString(),
      fieldType: json['fieldType']?.toString(),
    );
  }
}

