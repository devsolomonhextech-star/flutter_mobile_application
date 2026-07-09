import 'dart:async';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DepartmentChatMessage {
  final String? id;
  final String? text;
  final String? senderId;
  final String? receiverId;
  final String? senderDepartmentId;
  final String? receiverDepartmentId;
  final String? senderAdminId;
  final String? senderName;
  final String? receiverName;
  final String? createdAt;

  DepartmentChatMessage({
    this.id,
    this.text,
    this.senderId,
    this.receiverId,
    this.senderDepartmentId,
    this.receiverDepartmentId,
    this.senderAdminId,
    this.senderName,
    this.receiverName,
    this.createdAt,
  });

  factory DepartmentChatMessage.fromJson(Map<String, dynamic> json) {
    // Handle different response formats
    final data = json['data'] ?? json;
    
    return DepartmentChatMessage(
      id: data['id']?.toString(),
      text: data['text']?.toString() ?? data['message']?.toString(),
      senderId: data['senderId']?.toString(),
      receiverId: data['receiverId']?.toString(),
      senderDepartmentId: data['senderDepartmentId']?.toString(),
      receiverDepartmentId: data['receiverDepartmentId']?.toString(),
      senderAdminId: data['senderAdminId']?.toString(),
      senderName: data['Sender'] != null 
          ? '${data['Sender']?['firstName'] ?? ''} ${data['Sender']?['lastName'] ?? ''}'.trim()
          : data['senderName']?.toString(),
      receiverName: data['Receiver'] != null
          ? '${data['Receiver']?['firstName'] ?? ''} ${data['Receiver']?['lastName'] ?? ''}'.trim()
          : data['receiverName']?.toString(),
      createdAt: data['createdAt']?.toString(),
    );
  }

  bool get isFromAdmin => senderAdminId != null && senderAdminId!.isNotEmpty;
}

class ChatSocketService extends GetxService {
  static const String defaultSocketUrl = 'http://localhost:5001';

  IO.Socket? _socket;

  final RxBool isConnected = false.obs;
  final RxList<DepartmentChatMessage> messages = <DepartmentChatMessage>[].obs;
  final RxString currentDepartmentId = ''.obs;
  final RxString currentUserId = ''.obs;
  final RxString currentInstitutionId = ''.obs;
  final RxBool isLoading = false.obs;

  IO.Socket? get socket => _socket;

  /// Connect and register for department chat
  Future<void> connect({
    String? socketUrl,
    required String departmentId,
    required String institutionId,
    required String userId,
    String? token,
    String? userName,
  }) async {
    await disconnect();

    final url = socketUrl ?? defaultSocketUrl;

    print('Connecting to socket: $url');
    print('Department ID: $departmentId');
    print('User ID: $userId');

    final s = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setTimeout(20000)
          .setAuth(token != null ? {'token': token} : {})
          .setExtraHeaders({
            'userId': userId,
            'departmentId': departmentId,
            'institutionId': institutionId,
          })
          .build(),
    );

    _socket = s;

    // Socket event handlers
    s.onConnect((_) {
      print('Socket connected successfully');
      isConnected.value = true;
      currentDepartmentId.value = departmentId;
      currentUserId.value = userId;
      currentInstitutionId.value = institutionId;

      // Register for chat
      s.emit('register', {
        'userId': userId,
        'departmentId': departmentId,
        'institutionId': institutionId,
      });
      
      print('Registered with socket server');
    });

    s.onConnectError((data) {
      print('Socket connection error: $data');
      isConnected.value = false;
    });

    s.onDisconnect((_) {
      print('Socket disconnected');
      isConnected.value = false;
    });

    // Handle new messages from WebSocket
    s.on('new_message', (data) {
      print('Received new_message: $data');
      if (data is Map) {
        final map = data.cast<String, dynamic>();
        final message = DepartmentChatMessage.fromJson(map);
        
        // Only add if it belongs to this department
        if (message.senderDepartmentId == departmentId || 
            message.receiverDepartmentId == departmentId) {
          messages.add(message);
          print('Added message to list: ${message.text}');
        }
      }
    });

    // Handle department message notifications
    s.on('department-message-notification', (data) {
      print('Received department-message-notification: $data');
      if (data is Map) {
        final map = data.cast<String, dynamic>();
        messages.add(DepartmentChatMessage.fromJson(map));
      }
    });

    s.onError((data) {
      print('Socket error: $data');
    });

    // Reconnect logic
    s.onReconnect((_) {
      print('Socket reconnecting...');
    });

    s.onReconnectAttempt((_) {
      print('Socket reconnect attempt...');
    });
  }

  Future<void> disconnect() async {
    try {
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    isConnected.value = false;
    messages.clear();
  }

  /// Join a department chat room
  void joinDepartmentThread({required String threadDepartmentId}) {
    if (_socket != null && isConnected.value) {
      _socket?.emit('join-department-room', {'departmentId': threadDepartmentId});
      print('Joined department room: $threadDepartmentId');
    }
  }

  /// Send a message to a department
  void sendDepartmentMessage({
    required String fromDepartmentId,
    required String toDepartmentId,
    required String content,
    required String institutionId,
    required String senderId,
    String? senderAdminId,
    String? receiverId,
  }) {
    if (_socket == null || !isConnected.value) {
      print('Socket not connected, cannot send message');
      return;
    }

    final payload = {
      'senderDepartmentId': fromDepartmentId,
      'receiverDepartmentId': toDepartmentId,
      'institution_id': institutionId,
      'senderId': senderId,
      'text': content,
    };

    // Add admin ID if provided
    if (senderAdminId != null && senderAdminId.isNotEmpty) {
      payload['adminId'] = senderAdminId;
    }

    // Add receiver ID if provided
    if (receiverId != null && receiverId.isNotEmpty) {
      payload['receiverId'] = receiverId;
    }

    print('Sending message payload: $payload');
    
    // Emit to backend
    _socket?.emit('send-message', payload);
    
    // Add message locally for immediate feedback
    final localMessage = DepartmentChatMessage(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      text: content,
      senderDepartmentId: fromDepartmentId,
      receiverDepartmentId: toDepartmentId,
      senderId: senderId,
      senderAdminId: senderAdminId,
      createdAt: DateTime.now().toIso8601String(),
    );
    
    messages.add(localMessage);
    print('Added local message to list');
  }

  /// Load recent chat messages
  Future<List<DepartmentChatMessage>> getRecentChats({
    required String userId,
    required String departmentId,
    bool isAdmin = false,
  }) async {
    isLoading.value = true;

    try {
      // Simulate a fetch operation for recent chats.
      // Replace this with a real REST API call when available.
      await Future.delayed(const Duration(milliseconds: 250));

      final recent = messages.where((message) {
        final belongsToDepartment =
            message.senderDepartmentId == departmentId ||
            message.receiverDepartmentId == departmentId;

        if (!belongsToDepartment) return false;
        if (isAdmin) return true;

        return message.senderId == userId || message.receiverId == userId;
      }).toList();

      messages.assignAll(recent);
      return recent;
    } catch (e) {
      print('Error loading recent chats: $e');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch departments for an institution
  Future<List<Map<String, dynamic>>> getDepartmentsByInstitution({
    required String institutionId,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 250));

      final departmentMap = <String, Map<String, dynamic>>{};

      for (final message in messages) {
        if (message.senderDepartmentId != null && message.senderDepartmentId!.isNotEmpty) {
          departmentMap.putIfAbsent(message.senderDepartmentId!, () {
            return {
              'id': message.senderDepartmentId!,
              'name': message.senderName ?? 'Department ${message.senderDepartmentId}',
              'institutionId': institutionId,
            };
          });
        }

        if (message.receiverDepartmentId != null && message.receiverDepartmentId!.isNotEmpty) {
          departmentMap.putIfAbsent(message.receiverDepartmentId!, () {
            return {
              'id': message.receiverDepartmentId!,
              'name': message.receiverName ?? 'Department ${message.receiverDepartmentId}',
              'institutionId': institutionId,
            };
          });
        }
      }

      return departmentMap.values.toList();
    } catch (e) {
      print('Error fetching departments: $e');
      return [];
    }
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}