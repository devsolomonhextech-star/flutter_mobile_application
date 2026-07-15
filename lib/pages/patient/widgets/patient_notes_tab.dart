// lib/app/modules/patient_visit_details/widgets/patient_notes_tab.dart
import 'package:doctor_app/data/models/visit_related_models.dart';
import 'package:doctor_app/services/controller/visit_controller.dart';
import 'package:doctor_app/services/api/staff_comment_model.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Shared design tokens — using the same mint/teal palette as the main screen
class _T {
  static const bg = Color(0xFFF6FAF8);
  static const surface = Colors.white;
  static const primary = Color(0xFF3EBE93);
  static const primaryDark = Color(0xFF2FA37D);
  static const primarySoft = Color(0xFFE3F5EE);
  static const textPrimary = Color(0xFF1F2A24);
  static const textSecondary = Color(0xFF8B9892);
  static const textMuted = Color(0xFFB7C0BB);
  static const border = Color(0xFFE7ECE9);
  static const notes = Color(0xFF8B9892);
  static const shadow = Color(0xFF000000);
}

String _formatDateTime(DateTime? d) =>
    d == null ? 'N/A' : DateFormat('dd MMM yyyy, HH:mm').format(d);

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: _T.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _T.border),
    boxShadow: [
      BoxShadow(
        color: _T.shadow.withOpacity(0.04),
        blurRadius: 12,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

/// Date grouping helper
enum DateGroup { today, yesterday, thisWeek, thisMonth, lastMonth, older }

class _DateGroupHelper {
  static DateGroup getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = DateTime(now.year, now.month - 1, now.day);
    final twoMonthsAgo = DateTime(now.year, now.month - 2, now.day);

    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) return DateGroup.today;
    if (dateDay == yesterday) return DateGroup.yesterday;
    if (dateDay.isAfter(weekAgo)) return DateGroup.thisWeek;
    if (dateDay.isAfter(monthAgo)) return DateGroup.thisMonth;
    if (dateDay.isAfter(twoMonthsAgo)) return DateGroup.lastMonth;
    return DateGroup.older;
  }

  static String getGroupLabel(DateGroup group) {
    switch (group) {
      case DateGroup.today:
        return 'Today';
      case DateGroup.yesterday:
        return 'Yesterday';
      case DateGroup.thisWeek:
        return 'This Week';
      case DateGroup.thisMonth:
        return 'This Month';
      case DateGroup.lastMonth:
        return 'Last Month';
      case DateGroup.older:
        return 'Older';
    }
  }

  static IconData getGroupIcon(DateGroup group) {
    switch (group) {
      case DateGroup.today:
        return Icons.today_rounded;
      case DateGroup.yesterday:
        return Icons.toll_rounded;
      case DateGroup.thisWeek:
        return Icons.weekend_rounded;
      case DateGroup.thisMonth:
        return Icons.calendar_month_rounded;
      case DateGroup.lastMonth:
        return Icons.calendar_view_month_rounded;
      case DateGroup.older:
        return Icons.history_rounded;
    }
  }
}

/// A dedicated widget section for fetching patient notes
/// and adding comments to a note.
class PatientNotesTab extends StatefulWidget {
  final String visitId;

  const PatientNotesTab({super.key, required this.visitId});

  @override
  State<PatientNotesTab> createState() => _PatientNotesTabState();
}

class _PatientNotesTabState extends State<PatientNotesTab>
    with SingleTickerProviderStateMixin {
  final VisitController visitController = Get.find<VisitController>();
  late final AnimationController _animationController;

  // Loading state for sending notifications from this screen
  final RxBool _isSendingNotification = false.obs;


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _load();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await visitController.loadPatientNotes(visitId: widget.visitId);
    if (visitController.patientNotes.isNotEmpty) {
      _animationController.forward();
    }
  }

  Future<void> _addComment({
    required String noteId,
    required String comment,
  }) async {
    if (noteId.isEmpty || comment.isEmpty) return;

    await visitController.addCommentToNote(noteId: noteId, comment: comment);

    if (visitController.patientNotesError.isNotEmpty) {
      Get.snackbar(
        'Error',
        visitController.patientNotesError.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE0656B),
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    await visitController.loadPatientNotes(visitId: widget.visitId);

    Get.snackbar(
      'Success',
      'Comment added successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _T.primary,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = visitController.isPatientNotesLoading.value;
      final notes = visitController.patientNotes;
      final err = visitController.patientNotesError.value;

      if (isLoading) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_T.primary),
          ),
        );
      }

      if (err.isNotEmpty && notes.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: _T.textMuted,
                ),
                const SizedBox(height: 14),
                Text(
                  err,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _T.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (notes.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _T.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.note_add_rounded,
                  size: 48,
                  color: _T.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No patient notes yet',
                style: TextStyle(
                  color: _T.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Medical notes will appear here',
                style: TextStyle(color: _T.textMuted, fontSize: 14),
              ),
            ],
          ),
        );
      }

      // Group notes by date
      final groupedNotes = <DateGroup, List<PatientNote>>{};
      for (final note in notes) {
        if (note.createdAt != null) {
          final group = _DateGroupHelper.getDateGroup(note.createdAt!);
          groupedNotes.putIfAbsent(group, () => []).add(note);
        }
      }

      // Sort groups
      final groupOrder = [
        DateGroup.today,
        DateGroup.yesterday,
        DateGroup.thisWeek,
        DateGroup.thisMonth,
        DateGroup.lastMonth,
        DateGroup.older,
      ];

      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final opacity = _animationController.value.clamp(0.0, 1.0);
          return Opacity(opacity: opacity, child: child);
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: groupOrder.length,
          itemBuilder: (context, groupIndex) {
            final group = groupOrder[groupIndex];
            final notesInGroup = groupedNotes[group] ?? [];
            if (notesInGroup.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        _DateGroupHelper.getGroupIcon(group),
                        size: 18,
                        color: _T.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _DateGroupHelper.getGroupLabel(group),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _T.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _T.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${notesInGroup.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _T.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...notesInGroup.map((note) {
                  final noteIndex = notes.indexOf(note);
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(
                      milliseconds: 300 + (noteIndex * 40).clamp(0, 500),
                    ),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      final opacity = value.clamp(0.0, 1.0);
                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, (1 - opacity) * 15),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PatientNoteCard(
                        note: note,
                        onAddComment: (comment) {
                          print('Adding comment to note ${note.id}');
                          return _addComment(noteId: note.id.toString(), comment: comment);
                         
                        },
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      );
    });
  }
}

class _PatientNoteCard extends StatefulWidget {
  final PatientNote note;
  final Future<void> Function(String comment) onAddComment;

  const _PatientNoteCard({required this.note, required this.onAddComment});

  @override
  State<_PatientNoteCard> createState() => _PatientNoteCardState();
}

class _PatientNoteCardState extends State<_PatientNoteCard>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late final AnimationController _expandController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await widget.onAddComment(text);
    _controller.clear();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _expandController.forward() : _expandController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final comments = note.comments ?? <StaffComment>[];
    final hasComments = comments.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: hasComments ? _toggleExpand : null,
        child: Container(
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Note Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _T.primary.withOpacity(0.15),
                                _T.primary.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.note_alt_rounded,
                            size: 20,
                            color: _T.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.note ?? 'No note content',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _T.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: _T.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDateTime(note.createdAt),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: _T.textMuted,
                                    ),
                                  ),
                                  if (hasComments) ...[
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 3,
                                      height: 3,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _T.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _T.primarySoft,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.comment_rounded,
                                            size: 12,
                                            color: _T.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${comments.length}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: _T.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (hasComments)
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              Icons.expand_more_rounded,
                              size: 24,
                              color: _T.textMuted,
                            ),
                          ),
                      ],
                    ),

                    // Comments Section
                    if (hasComments)
                      SizeTransition(
                        sizeFactor: _expandController,
                        axisAlignment: -1,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            children: [
                              Divider(height: 1, color: _T.border),
                              const SizedBox(height: 12),
                              ...comments.map(
                                (comment) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _CommentRow(comment: comment),
                                ),
                              ),
                              Divider(height: 1, color: _T.border),
                              const SizedBox(height: 12),
                              _AddCommentComposer(
                                controller: _controller,
                                onSubmit: _submit,
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      const SizedBox(height: 12),
                      _AddCommentComposer(
                        controller: _controller,
                        onSubmit: _submit,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  final StaffComment comment;

  const _CommentRow({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _T.primary.withOpacity(0.2),
                _T.primary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              _getInitials(comment.author?.fullName ?? 'S'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _T.primaryDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      comment.author?.fullName ?? 'Staff',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _T.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _T.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimeAgo(comment.createdAt!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: _T.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                comment.comment ?? '',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: _T.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _AddCommentComposer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _AddCommentComposer({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 2,
              style: const TextStyle(fontSize: 13.5, color: _T.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: TextStyle(fontSize: 13, color: _T.textMuted),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _T.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onSubmit,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
