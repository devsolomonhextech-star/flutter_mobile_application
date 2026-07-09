// department_chat_screen.dart
import 'package:doctor_app/pages/chat/department_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:doctor_app/services/socket/chat_socket_service.dart';
import 'package:doctor_app/services/session_service.dart';

class DepartmentChatScreen extends StatefulWidget {
  final Department department;

  const DepartmentChatScreen({
    super.key,
    required this.department,
  });

  @override
  State<DepartmentChatScreen> createState() => _DepartmentChatScreenState();
}

class _DepartmentChatScreenState extends State<DepartmentChatScreen> {
  final ChatSocketService chat = Get.find<ChatSocketService>();
  final SessionService session = Get.find<SessionService>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? get _userId => session.user?.userId?.toString();
  String? get _token => session.token;
  String? get _institutionId => session.user?.institutionId?.toString() ?? 
                                 "f5cbc162-25a1-4a25-94d3-258f68731eb9";
  String? get _userName => session.user?.firstName ?? 'User';

  @override
  void initState() {
    super.initState();
    _connectToDepartment();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _connectToDepartment() {
    final userId = _userId;
    final departmentId = widget.department.id;
    final institutionId = _institutionId;

    if (userId == null || departmentId.isEmpty || institutionId == null) {
      print('Missing required connection info');
      return;
    }

    if (!chat.isConnected.value) {
      chat.connect(
        departmentId: departmentId,
        institutionId: institutionId,
        userId: userId,
        token: _token,
      );
    } else {
      chat.joinDepartmentThread(threadDepartmentId: departmentId);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final messages = chat.messages;
              
              if (messages.isEmpty) {
                return _buildEmptyState();
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isCurrentUser = message.senderId == _userId || 
                                       message.senderAdminId == _userId;
                  final senderName = _getSenderName(message);
                  final timestamp = _parseCreatedAt(message.createdAt);

                  return _buildMessageBubble(
                    message: message.text ?? '',
                    isCurrentUser: isCurrentUser,
                    senderName: senderName,
                    timestamp: timestamp,
                    isFromAdmin: message.isFromAdmin,
                  );
                },
              );
            }),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.grey.shade800),
        onPressed: () {
          chat.leaveDepartmentThread(threadDepartmentId: widget.department.id);
          Navigator.pop(context);
        },
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getAvatarColor(widget.department.name),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                widget.department.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.department.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                Obx(() => Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: chat.isConnected.value 
                            ? Colors.green.shade500 
                            : Colors.orange.shade500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      chat.isConnected.value ? 'Connected' : 'Connecting...',
                      style: TextStyle(
                        fontSize: 12,
                        color: chat.isConnected.value 
                            ? Colors.green.shade700 
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
          onPressed: () {
            _showOptionsMenu();
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Messages Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with ${widget.department.name}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          if (chat.isConnected.value)
            ElevatedButton.icon(
              onPressed: () {
                _sendMessage('Hello from ${_userName ?? "Staff"}!');
              },
              icon: const Icon(Icons.send),
              label: const Text('Say Hello'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Obx(() {
      final isConnected = chat.isConnected.value;
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.attach_file,
                  color: isConnected ? Colors.grey.shade600 : Colors.grey.shade300,
                  size: 24,
                ),
                onPressed: isConnected ? () {
                  _showAttachmentOptions();
                } : null,
              ),
              IconButton(
                icon: Icon(
                  Icons.emoji_emotions_outlined,
                  color: isConnected ? Colors.grey.shade600 : Colors.grey.shade300,
                  size: 24,
                ),
                onPressed: isConnected ? () {
                  _showEmojiPicker();
                } : null,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.grey.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isConnected ? Colors.grey.shade200 : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    enabled: isConnected,
                    decoration: InputDecoration(
                      hintText: isConnected ? 'Type a message...' : 'Connecting...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: isConnected ? Colors.grey : Colors.grey.shade400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty) {
                        _sendMessage(text.trim());
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildSendButton(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSendButton() {
    return Obx(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      final isConnected = chat.isConnected.value;
      final canSend = isConnected && hasText;
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: canSend ? Colors.blue.shade700 : Colors.grey.shade200,
          shape: BoxShape.circle,
          boxShadow: canSend
              ? [
                  BoxShadow(
                    color: Colors.blue.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: IconButton(
          icon: Icon(
            Icons.send_rounded,
            color: canSend ? Colors.white : Colors.grey.shade500,
            size: 22,
          ),
          onPressed: canSend ? () {
            _sendMessage(_messageController.text.trim());
          } : null,
        ),
      );
    });
  }

  void _sendMessage(String text) {
    if (text.isEmpty) return;
    
    final departmentId = widget.department.id;
    final institutionId = _institutionId;
    final userId = _userId;

    if (userId == null || institutionId == null) return;

    chat.sendDepartmentMessage(
      fromDepartmentId: departmentId,
      toDepartmentId: departmentId,
      content: text,
      institutionId: institutionId,
      senderId: userId,
    );
    
    _messageController.clear();
    _scrollToBottom();
  }

  String _getSenderName(DepartmentChatMessage message) {
    if (message.senderName != null && message.senderName!.isNotEmpty) {
      return message.senderName!;
    }
    if (message.senderId == _userId) {
      return 'Me';
    }
    if (message.isFromAdmin) {
      return 'Admin';
    }
    return 'Staff';
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isCurrentUser,
    required String senderName,
    required DateTime timestamp,
    required bool isFromAdmin,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser)
            CircleAvatar(
              radius: 18,
              backgroundColor: isFromAdmin ? Colors.purple.shade100 : Colors.blue.shade100,
              child: Text(
                senderName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isFromAdmin ? Colors.purple.shade700 : Colors.blue.shade700,
                ),
              ),
            ),
          if (!isCurrentUser) const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentUser ? Colors.blue.shade600 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser) ...[
                    Row(
                      children: [
                        Text(
                          senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isFromAdmin ? Colors.purple.shade700 : Colors.blue.shade700,
                          ),
                        ),
                        if (isFromAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 15,
                      color: isCurrentUser
                          ? Colors.white
                          : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isCurrentUser
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade500,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.done_all,
                          size: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 10),
          if (isCurrentUser)
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                'Me',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Messages'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.people_outline, color: Colors.grey.shade700),
              title: Text('Department Members',
                  style: TextStyle(color: Colors.grey.shade700)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text('Clear Chat', style: TextStyle(color: Colors.red.shade400)),
              onTap: () {
                Navigator.pop(context);
                _showClearChatDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat?'),
        content: Text(
          'This will clear all messages in ${widget.department.name}. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              chat.messages.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Chat cleared for ${widget.department.name}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Attach',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentOption(Icons.photo_library, 'Gallery', () {
                  Navigator.pop(context);
                }),
                _buildAttachmentOption(Icons.camera_alt, 'Camera', () {
                  Navigator.pop(context);
                }),
                _buildAttachmentOption(Icons.file_present, 'Document', () {
                  Navigator.pop(context);
                }),
                _buildAttachmentOption(Icons.location_on, 'Location', () {
                  Navigator.pop(context);
                }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: _emojiList.length,
          itemBuilder: (context, index) {
            return IconButton(
              icon: Text(
                _emojiList[index],
                style: const TextStyle(fontSize: 28),
              ),
              onPressed: () {
                Navigator.pop(context);
                _messageController.text += _emojiList[index];
              },
            );
          },
        ),
      ),
    );
  }

  final List<String> _emojiList = [
    '😀', '😁', '😂', '🤣', '😃', '😄', '😅',
    '😆', '😉', '😊', '😋', '😎', '😍', '🥰',
    '😘', '😗', '😙', '😚', '🙂', '🤗', '🤩',
    '🤔', '🤨', '😐', '😑', '😶', '🙄', '😏',
    '😣', '😥', '😮', '🤐', '😯', '😪', '😫',
    '😴', '😌', '😛', '😜', '😝', '🤤', '😒',
    '😓', '😔', '😕', '🙃', '🤑', '😲', '☹️',
    '🙁', '😖', '😞', '😟', '😤', '😢', '😭',
    '😦', '😧', '😨', '😩', '🤯', '😬', '😰',
    '😱', '🥵', '🥶', '😳', '🤪', '😵', '😡',
  ];

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue.shade600,
      Colors.purple.shade600,
      Colors.pink.shade600,
      Colors.orange.shade600,
      Colors.green.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
      Colors.red.shade600,
    ];
    final index = name.hashCode % colors.length;
    return colors[index];
  }

  DateTime _parseCreatedAt(String? createdAt) {
    if (createdAt == null || createdAt.trim().isEmpty) {
      return DateTime.now();
    }
    try {
      return DateTime.parse(createdAt);
    } catch (_) {
      return DateTime.now();
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

extension ChatSocketServiceDepartmentThreadExtension on ChatSocketService {
  void leaveDepartmentThread({required String threadDepartmentId}) {
    // Placeholder for leaving a department thread.
    // Add proper implementation in ChatSocketService when available.
  }
}