import 'package:get/get.dart';
import 'package:doctor_app/data/models/user_models.dart';
import 'package:doctor_app/services/api/auth_service.dart';
import 'package:doctor_app/services/session_service.dart';

class HomeUserDetailsController extends GetxController {
  final SessionService sessionService;

  HomeUserDetailsController({required this.sessionService});

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    final userId = sessionService.userId;
    final token = sessionService.token;

    if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
      // If session doesn't have enough, fall back to cached user.
      user.value = sessionService.user;
      isLoading.value = false;
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final fetched = await AuthService.getUserDetails(
        userId: userId,
        token: token,
      );

      if (fetched != null) {
        user.value = fetched;
      } else {
        // Keep the cached one
        user.value = sessionService.user;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      user.value = sessionService.user;
    } finally {
      isLoading.value = false;
    }
  }
}
