// department_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:doctor_app/services/socket/chat_socket_service.dart';
import 'package:doctor_app/services/session_service.dart';
import 'package:doctor_app/services/api/chat_api.dart';
import 'department_chat_screen.dart';

class DepartmentListScreen extends StatefulWidget {
  const DepartmentListScreen({super.key});

  @override
  State<DepartmentListScreen> createState() => _DepartmentListScreenState();
}

class _DepartmentListScreenState extends State<DepartmentListScreen> {
  final ChatSocketService chat = Get.put(ChatSocketService());
  final SessionService session = Get.find<SessionService>();

  final RxList<Department> _departments = <Department>[].obs;
  final RxBool _loadingDepartments = false.obs;

  String? get _userId => session.user?.userId?.toString();
  String? get _token => session.token;
  String? get _institutionId => Get.arguments?['institutionId'] ?? 
                                  session.user?.institutionId?.toString() ??
                                  "f5cbc162-25a1-4a25-94d3-258f68731eb9";

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    final institutionId = _institutionId;
    if (institutionId == null || institutionId.isEmpty) {
      print('Institution ID is missing. Cannot fetch departments.');
      return;
    }

    _loadingDepartments.value = true;
    try {
      final response = await ChatApi.getDepartmentsByInstitution(
        institutionId: institutionId,
        token: _token,
      );
      
      if (response['success'] == true && response['departments'] != null) {
        final departments = (response['departments'] as List)
            .map((d) => Department.fromJson(d))
            .toList();
        _departments.assignAll(departments);
      }
    } catch (e) {
      print('Error fetching departments: $e');
    } finally {
      _loadingDepartments.value = false;
    }
  }

  void _connectSocket(String departmentId) {
    final userId = _userId;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.forum_outlined,
                color: Colors.blue.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Department Chats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                Obx(() => Text(
                  _loadingDepartments.value 
                      ? 'Loading...' 
                      : '${_departments.length} departments',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                )),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.grey.shade600),
            onPressed: () {
              showSearch(
                context: context,
                delegate: DepartmentSearchDelegate(_departments),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey.shade600),
            onPressed: _fetchDepartments,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: Obx(() {
        // Show shimmer while loading
        if (_loadingDepartments.value) {
          return _buildShimmerList();
        }

        if (_departments.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          itemCount: _departments.length,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemBuilder: (context, index) {
            final department = _departments[index];
            return _buildDepartmentTile(department);
          },
        );
      }),
    );
  }

  // Shimmer loading effect
  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      enabled: true,
      child: ListView.builder(
        itemCount: 6,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemBuilder: (context, index) {
          return _buildShimmerItem();
        },
      ),
    );
  }

  Widget _buildShimmerItem() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar shimmer
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 12),
            // Text shimmer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 16,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 12,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
            // Chevron shimmer
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 50,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Departments Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any departments to chat with',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchDepartments,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
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

  Widget _buildDepartmentTile(Department department) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: () {
          _connectSocket(department.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DepartmentChatScreen(
                department: department,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildDepartmentAvatar(department.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      department.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to start chatting',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentAvatar(String name) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _getAvatarColor(name),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          name.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

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

  @override
  void dispose() {
    chat.disconnect();
    super.dispose();
  }
}

// Search Delegate
class DepartmentSearchDelegate extends SearchDelegate<Department?> {
  final RxList<Department> departments;

  DepartmentSearchDelegate(this.departments);

  @override
  String get searchFieldLabel => 'Search departments...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = departments.where((dept) =>
        dept.name.toLowerCase().contains(query.toLowerCase())).toList();
    return _buildResultsList(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Search for departments',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final suggestions = departments.where((dept) =>
        dept.name.toLowerCase().contains(query.toLowerCase())).toList();
    return _buildResultsList(suggestions);
  }

  Widget _buildResultsList(List<Department> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No departments found',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final department = results[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                department.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          title: Text(department.name),
          onTap: () {
            close(context, department);
          },
        );
      },
    );
  }
}

class Department {
  final String id;
  final String name;

  Department({
    required this.id,
    required this.name,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
    );
  }
}