import 'package:flutter/material.dart';

class LeaveStatsRow extends StatelessWidget {
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;

  const LeaveStatsRow({
    super.key,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Pending',
            pendingCount.toString(),
            '⏳',
            Colors.orange.shade50,
            Colors.orange.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Approved',
            approvedCount.toString(),
            '✅',
            Colors.green.shade50,
            Colors.green.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Rejected',
            rejectedCount.toString(),
            '❌',
            Colors.red.shade50,
            Colors.red.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String count,
    String icon,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}