import 'package:get/get.dart';
import '../controllers/base_controller.dart';
import '../core/helper/secure_storage_service.dart';
import '../core/repos/profile_repo.dart';
import '../models/profile_model.dart';

class ProfileController extends BaseController {
  final ProfileRepo profileRepo;

  ProfileController({required this.profileRepo});

  final Rx<ProfileModel?> profile = Rx<ProfileModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    showLoading();
    try {
      final result = await profileRepo.getProfile();
      profile.value = result;
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> logout() async {
    await SecureStorage.removeToken();
    Get.offAllNamed('/login');
  }
}