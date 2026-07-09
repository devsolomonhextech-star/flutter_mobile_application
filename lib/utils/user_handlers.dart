// Check if user has valid session
import 'package:doctor_app/services/isar/isar_service.dart';

Future<bool> hasValidSession() async {
  final user = await IsarService.getLoggedInUser();
  return user != null && user.token != null && user.token!.isNotEmpty;
}

// Get user token
Future<String?> getUserToken() async {
  final user = await IsarService.getLoggedInUser();
  return user?.token;
}

// Update user profile
Future<void> updateUserProfile(Map<String, dynamic> data) async {
  final user = await IsarService.getLoggedInUser();
  if (user != null) {
    // Update fields
    user.username = data['username'] ?? user.username;
    // ... update other fields
    await IsarService.saveUser(user);
  }
}