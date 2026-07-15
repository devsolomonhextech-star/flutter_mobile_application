// lib/app/modules/patient_visit_details/views/patient_ai_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../services/controller/ai_controller.dart';

/// Shared design tokens — mint/teal palette
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
  static const shadow = Color(0xFF000000);
  static const aiMessage = Color(0xFFF0F7FF);
  static const userMessage = Color(0xFFE3F5EE);
}

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isTyping;

  Message({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isTyping = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Message.typing({required this.isUser})
    : text = '',
      timestamp = DateTime.now(),
      isTyping = true;
}

class PatientAiSummaryScreen extends StatefulWidget {
  final String visitId;
  const PatientAiSummaryScreen({super.key, required this.visitId});

  @override
  State<PatientAiSummaryScreen> createState() => _PatientAiSummaryScreenState();
}

class _PatientAiSummaryScreenState extends State<PatientAiSummaryScreen>
    with TickerProviderStateMixin {
  final AiController _aiController = Get.put(AiController());
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Message> _messages = [];
  bool _isAiTyping = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _aiController.loadPatientAiSummary(widget.visitId);
    
    // Add initial AI message
    final summary = _aiController.aiSummary.value.trim();
    if (summary.isNotEmpty) {
      setState(() {
        _messages.add(Message(
          text: summary,
          isUser: false,
        ));
      });
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(Message(text: text, isUser: true));
      _messageController.clear();
      _isAiTyping = true;
    });

    _scrollToBottom();

    // Simulate AI response
    await Future.delayed(Duration(milliseconds: 800 + (300 * text.length / 10).toInt()));

    // Generate AI response based on context
    final response = _generateAIResponse(text);
    
    setState(() {
      _isAiTyping = false;
      _messages.add(Message(text: response, isUser: false));
    });

    _scrollToBottom();
  }

  String _generateAIResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    final summary = _aiController.aiSummary.value.trim();
    final patientName = _safeToString(
      _aiController.patient['name'],
      defaultValue: 'the patient',
    );

    // Context-aware responses
    if (lowerMessage.contains('hello') || lowerMessage.contains('hi') || lowerMessage.contains('hey')) {
      return 'Hello! I\'m your AI assistant. I\'ve analyzed ${patientName}\'s medical data. How can I help you today?';
    }
    
    if (lowerMessage.contains('diagnosis') || lowerMessage.contains('condition')) {
      return 'Based on the medical records, ${patientName} has been diagnosed with multiple conditions. The primary diagnosis appears to be related to ${_extractDiagnosis(summary)}. Would you like me to elaborate on any specific diagnosis?';
    }
    
    if (lowerMessage.contains('treatment') || lowerMessage.contains('medication') || lowerMessage.contains('prescription')) {
      return 'The treatment plan for ${patientName} includes several medications and therapies. I can see prescriptions for ${_extractMedications(summary)}. Would you like more details about the treatment plan?';
    }
    
    if (lowerMessage.contains('vital') || lowerMessage.contains('lab') || lowerMessage.contains('test')) {
      return 'Recent vital signs and lab results for ${patientName} show ${_extractVitals(summary)}. Some values are within normal range, while others require monitoring. Would you like to see the detailed lab reports?';
    }
    
    if (lowerMessage.contains('progress') || lowerMessage.contains('improve')) {
      return 'Looking at the medical history, ${patientName} has shown ${_extractProgress(summary)}. The treatment appears to be effective, but continued monitoring is recommended. Would you like more specific progress metrics?';
    }
    
    if (lowerMessage.contains('risk') || lowerMessage.contains('concern')) {
      return 'The key risk factors for ${patientName} include ${_extractRisks(summary)}. I recommend regular check-ups and monitoring of these areas. Would you like to discuss any specific risk factor in more detail?';
    }

    // Default intelligent response
    return 'I understand your question about ${patientName}. Based on the medical data available, I can see that ${_extractRelevantInfo(summary)}. Could you please be more specific about what you\'d like to know? I\'m here to help with any aspect of the patient\'s care.';
  }

  String _extractDiagnosis(String summary) {
    // Extract diagnosis from summary
    final diagnosisKeywords = ['diagnosed with', 'diagnosis:', 'condition:', 'primary diagnosis'];
    for (final keyword in diagnosisKeywords) {
      final index = summary.indexOf(keyword);
      if (index != -1) {
        final endIndex = summary.indexOf('.', index);
        if (endIndex != -1) {
          return summary.substring(index + keyword.length, endIndex).trim();
        }
        return summary.substring(index + keyword.length).trim();
      }
    }
    return 'multiple conditions';
  }

  String _extractMedications(String summary) {
    final medKeywords = ['prescribed', 'medication:', 'medications:', 'treatment includes'];
    for (final keyword in medKeywords) {
      final index = summary.indexOf(keyword);
      if (index != -1) {
        final endIndex = summary.indexOf('.', index);
        if (endIndex != -1) {
          return summary.substring(index + keyword.length, endIndex).trim();
        }
        return summary.substring(index + keyword.length).trim();
      }
    }
    return 'various medications';
  }

  String _extractVitals(String summary) {
    final vitalsKeywords = ['vitals:', 'vital signs:', 'blood pressure', 'heart rate'];
    for (final keyword in vitalsKeywords) {
      final index = summary.indexOf(keyword);
      if (index != -1) {
        final endIndex = summary.indexOf('.', index);
        if (endIndex != -1) {
          return summary.substring(index, endIndex).trim();
        }
        return summary.substring(index).trim();
      }
    }
    return 'various vital signs';
  }

  String _extractProgress(String summary) {
    if (summary.contains('improving') || summary.contains('progressing')) {
      return 'positive progress with the current treatment plan';
    } else if (summary.contains('stable')) {
      return 'stable condition with no major changes';
    } else if (summary.contains('worsening')) {
      return 'some concerning trends that require attention';
    }
    return 'a mixed recovery pattern';
  }

  String _extractRisks(String summary) {
    final riskKeywords = ['risks:', 'risk factors:', 'concerns:', 'complications'];
    for (final keyword in riskKeywords) {
      final index = summary.indexOf(keyword);
      if (index != -1) {
        final endIndex = summary.indexOf('.', index);
        if (endIndex != -1) {
          return summary.substring(index + keyword.length, endIndex).trim();
        }
        return summary.substring(index + keyword.length).trim();
      }
    }
    return 'various risk factors that require monitoring';
  }

  String _extractRelevantInfo(String summary) {
    final sentences = summary.split('.');
    if (sentences.length > 2) {
      return sentences.sublist(0, 2).join('.').trim();
    }
    return summary.substring(0, summary.length > 100 ? 100 : summary.length).trim();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _safeToString(dynamic v, {required String defaultValue}) {
    if (v == null) return defaultValue;
    final s = v.toString();
    return s.isEmpty ? defaultValue : s;
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_T.primary, _T.primaryDark],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Patient Summary',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _T.textPrimary,
                  ),
                ),
                Obx(() {
                  final patientName = _safeToString(
                    _aiController.patient['name'],
                    defaultValue: 'Patient',
                  );
                  return Text(
                    patientName,
                    style: TextStyle(
                      fontSize: 11,
                      color: _T.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Refresh or reset conversation
              _messages.clear();
              _loadData();
              Get.snackbar(
                'Refreshed',
                'AI summary has been refreshed',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: _T.primary,
                colorText: Colors.white,
                borderRadius: 12,
                margin: const EdgeInsets.all(16),
              );
            },
            icon: Icon(Icons.refresh_rounded, color: _T.textSecondary),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _T.border),
        ),
      ),
      body: Obx(() {
        if (_aiController.isLoading.value && _messages.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_T.primary),
            ),
          );
        }

        if (_aiController.errorMessage.value.isNotEmpty && _messages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0656B).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: const Color(0xFFE0656B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Error Loading Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _T.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _aiController.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _T.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemCount: _messages.length + (_isAiTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isAiTyping) {
                    return _buildTypingIndicator();
                  }
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
            // Input bar
            Container(
              decoration: BoxDecoration(
                color: _T.surface,
                border: Border(
                  top: BorderSide(color: _T.border, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _T.shadow.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _T.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _T.border),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _T.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Ask me anything about the patient...',
                          hintStyle: TextStyle(
                            fontSize: 13.5,
                            color: _T.textMuted,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_T.primary, _T.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _sendMessage,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _buildAvatar(),
          if (!isUser) const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? _T.primary : _T.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isUser ? 14 : 4),
                      topRight: Radius.circular(isUser ? 4 : 14),
                      bottomLeft: const Radius.circular(14),
                      bottomRight: const Radius.circular(14),
                    ),
                    border: isUser ? null : Border.all(color: _T.border),
                    boxShadow: [
                      BoxShadow(
                        color: _T.shadow.withOpacity(isUser ? 0.08 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Text(
                                'AI Assistant',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _T.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: _T.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'AI',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: _T.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isUser ? Colors.white : _T.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isUser 
                              ? Colors.white.withOpacity(0.7)
                              : _T.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 10),
          if (isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: _T.border),
            ),
            child: Row(
              children: [
                _buildDot('assets/animations/typing_animation.json', 0),
                const SizedBox(width: 4),
                _buildDot('assets/animations/typing_animation.json', 1),
                const SizedBox(width: 4),
                _buildDot('assets/animations/typing_animation.json', 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(String animation, int delay) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _T.primary.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_T.primary, _T.primaryDark],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _T.textSecondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: _T.textSecondary,
          size: 18,
        ),
      ),
    );
  }
}