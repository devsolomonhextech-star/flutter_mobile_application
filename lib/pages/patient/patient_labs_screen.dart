import 'package:doctor_app/data/models/lab_models.dart';
import 'package:doctor_app/services/controller/lab_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PatientLabsScreen extends StatefulWidget {
  final String patientId;
  const PatientLabsScreen({super.key, required this.patientId});

  @override
  State<PatientLabsScreen> createState() => _PatientLabsScreenState();
}

class _PatientLabsScreenState extends State<PatientLabsScreen> {
  final LabController labController = Get.put(LabController());

  @override
  void initState() {
    super.initState();
    labController.loadPatientLabs(patientId: widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF6FAF8);
    const textPrimary = Color(0xFF1F2A24);
    const textSecondary = Color(0xFF8B9892);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Patient Labs',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        foregroundColor: textPrimary,
      ),
      body: Obx(() {
        if (labController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (labController.errorMessage.value.isNotEmpty &&
            labController.patientLabs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                labController.errorMessage.value,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textSecondary),
              ),
            ),
          );
        }

        if (labController.patientLabs.isEmpty) {
          return const Center(
            child: Text(
              'No lab records found',
              style: TextStyle(color: textSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: labController.patientLabs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, i) {
            final visitBlock = labController.patientLabs[i];
            final visit = visitBlock.visit;

            return _VisitLabsCard(
              visit: visit,
              results: visitBlock.labResults,
            );
          },
        );
      }),
    );
  }
}

class _VisitLabsCard extends StatelessWidget {
  final dynamic visit;
  final List<LabTestResult> results;

  const _VisitLabsCard({
    super.key,
    required this.visit,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF1F2A24);
    const textSecondary = Color(0xFF8B9892);

    final createdAt = visit.createdAt;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_rounded, color: Color(0xFF8B7FD1)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Visit ${visit.id ?? ''}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              if (createdAt != null)
                Text(
                  createdAt.toString().length > 10
                      ? createdAt.toString().substring(0, 10)
                      : createdAt.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No lab tests for this visit',
                style: TextStyle(color: textSecondary),
              ),
            )
          else
            ...results.map((r) => _ResultRow(result: r)),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final LabTestResult result;
  const _ResultRow({required this.result});

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF1F2A24);
    const textSecondary = Color(0xFF8B9892);

    final title = result.template?.description ?? 'Lab Test';
    final status = result.status ?? 'pending';

    final values = result.values;
    String resultText = '';
    if (values is Map) {
      // show first key/value
      final first = values.entries.firstOrNull;
      if (first != null) {
        resultText = '${first.key}: ${first.value}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            resultText.isNotEmpty ? resultText : 'Pending',
            style: const TextStyle(fontSize: 12.5, color: textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Status: ${status.toString().toUpperCase()}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

