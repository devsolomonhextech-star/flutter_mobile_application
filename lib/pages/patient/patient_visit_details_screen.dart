import 'package:doctor_app/data/models/visit_models.dart';
import 'package:doctor_app/services/controller/visit_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PatientVisitDetailsScreen extends StatefulWidget {
  final String visitId;
  const PatientVisitDetailsScreen({super.key, required this.visitId});

  @override
  State<PatientVisitDetailsScreen> createState() =>
      _PatientVisitDetailsScreenState();
}

class _PatientVisitDetailsScreenState extends State<PatientVisitDetailsScreen> {
  final VisitController visitController = Get.find<VisitController>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Avoid triggering Obx rebuild timing issues during the same build phase.
    await Future<void>.delayed(Duration.zero);
    await visitController.getVisitDetails(widget.visitId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Visit Details')),
      body: Obx(() {
        final isLoading = visitController.isLoading.value;

        // If API returns null, show error from controller.
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final Visit? visit = visitController.visits.firstWhereOrNull(
          (v) => v.id == widget.visitId,
        );


        if (visit == null) {
          return Center(
            child: Text(
              visitController.errorMessage.value.isNotEmpty
                  ? visitController.errorMessage.value
                  : 'Visit not found',
              textAlign: TextAlign.center,
            ),
          );
        }

        return _VisitDetailsBody(visit: visit);
      }),
    );
  }
}

class _VisitDetailsBody extends StatelessWidget {
  final Visit visit;
  const _VisitDetailsBody({required this.visit});

  @override
  Widget build(BuildContext context) {
    final patient = visit.patient;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderCard(patient: patient, visit: visit),
        const SizedBox(height: 12),
        _SectionTitle('Visit Info'),
        const SizedBox(height: 8),
        _InfoRow(label: 'Visit ID', value: visit.id ?? 'N/A'),
        _InfoRow(label: 'Status', value: visit.status ?? 'N/A'),
        _InfoRow(label: 'Type', value: visit.visitType ?? 'N/A'),
        _InfoRow(label: 'Attendance', value: visit.attendanceType ?? 'N/A'),
        _InfoRow(label: 'Department', value: visit.department?.name ?? 'N/A'),
        _InfoRow(label: 'Bed', value: visit.bedNumber ?? 'N/A'),
        _InfoRow(
          label: 'Admission Status',
          value: visit.admissionStatus ?? 'N/A',
        ),
        const SizedBox(height: 12),
        _SectionTitle('Dates'),
        const SizedBox(height: 8),
        _InfoRow(label: 'Visit Date', value: _formatDate(visit.visitDate)),
        _InfoRow(label: 'Created At', value: _formatDate(visit.createdAt)),
        _InfoRow(label: 'Updated At', value: _formatDate(visit.updatedAt)),
        const SizedBox(height: 12),
        _SectionTitle('Patient Notes & Clinical Data'),
        const SizedBox(height: 8),
        if (visit.patientNotes?.isNotEmpty == true) ...[
          for (final note in visit.patientNotes!)
            _InfoBlock('Note', note.note ?? note.toString()),
        ] else ...[
          const Text('No notes found.'),
        ],
      ],
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'N/A';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _HeaderCard extends StatelessWidget {
  final dynamic patient;
  final Visit visit;
  const _HeaderCard({required this.patient, required this.visit});

  @override
  Widget build(BuildContext context) {
    final initials = patient?.initials ?? 'P';
    final name = patient?.fullName ?? 'Unknown Patient';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${visit.status ?? 'N/A'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (patient?.age != null)
                  Text('${patient!.age} yrs • ${patient?.gender ?? 'N/A'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final String body;
  const _InfoBlock(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(body),
        ],
      ),
    );
  }
}
