// lib/data/models/staff_comment_model.dart


import 'package:doctor_app/services/api/staff_model.dart';

class StaffComment {
  final String? id;
  final String? patientNoteId;
  final String? staffId;
  final String? comment;

  final List<String>? taggedStaffIds;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Associations
  final Staff? author;
  final List<Staff>? taggedStaff;

  StaffComment({
    this.id,
    this.patientNoteId,
    this.staffId,
    this.comment,
    this.taggedStaffIds,
    this.createdAt,
    this.updatedAt,
    this.author,
    this.taggedStaff,
  });

  factory StaffComment.fromJson(
    Map<String, dynamic> json,
  ) {
    return StaffComment(
      id: json["id"],

      patientNoteId: json["patient_note_id"],

      staffId: json["staff_id"],

      comment: json["comment"],

      taggedStaffIds:
          (json["tagged_staff_ids"] as List?)
              ?.map((e) => e.toString())
              .toList(),

      createdAt: json["createdAt"] != null
          ? DateTime.tryParse(
              json["createdAt"],
            )
          : null,

      updatedAt: json["updatedAt"] != null
          ? DateTime.tryParse(
              json["updatedAt"],
            )
          : null,

      author: json["author"] != null
          ? Staff.fromJson(
              json["author"],
            )
          : null,

      taggedStaff: (json["taggedStaff"] as List?)
          ?.map(
            (e) => Staff.fromJson(
              e,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,

      "patient_note_id": patientNoteId,

      "staff_id": staffId,

      "comment": comment,

      "tagged_staff_ids": taggedStaffIds,

      "createdAt":
          createdAt?.toIso8601String(),

      "updatedAt":
          updatedAt?.toIso8601String(),

      "author": author?.toJson(),

      "taggedStaff":
          taggedStaff
              ?.map(
                (e) => e.toJson(),
              )
              .toList(),
    };
  }
}