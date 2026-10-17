
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_provider.dart';
import '../model/project_model.dart';

class ProjectController extends GetxController {
  final ApiProvider _api = Get.find<ApiProvider>();

  // ── Reactive state
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  final Rxn<ProjectQueueResponse> queue = Rxn<ProjectQueueResponse>();

  // ── Last used code (persisted)
  static const String _prefsKey = 'last_project_code';
  final RxString lastProjectCode = ''.obs;

  // ── Convenience
  Project? get project => queue.value?.project;
  List<Survey> get surveys => queue.value?.surveys ?? <Survey>[];

  @override
  void onInit() {
    super.onInit();
    _loadLastCode();
  }

  Future<void> _loadLastCode() async {
    final prefs = await SharedPreferences.getInstance();
    lastProjectCode.value = prefs.getString(_prefsKey) ?? '';
  }

  Future<void> _saveLastCode(String code) async {
    lastProjectCode.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }

  // LOAD QUEUE — requires a non-empty project code
  Future<bool> loadQueue(String projectCode) async {

    if (projectCode.trim().isEmpty) {
      errorMessage.value = 'Project code is required.';
      return false;
    }

    if (isLoading.value) return false;

    isLoading.value = true;
    errorMessage.value = null;
    queue.value = null;

    try {
      final code = projectCode.trim();
      final url =
          '${ApiProvider.apiPrefix}/calling-app/queue?project_code=$code';
      print(' [ProjectController] GET $url');

      final resp = await _api.get(url);
      final parsed = ProjectQueueResponse.fromJson(resp);

      queue.value = parsed;
      await _saveLastCode(code);

      print(
        '[ProjectController] Loaded "${parsed.project.name}" '
            '(${parsed.surveys.length} surveys) for code=$code',
      );
      return true;
    } on ApiException catch (e) {
      print(' [ProjectController] API error: ${e.message}');
      if (e.statusCode == 404) {
        errorMessage.value =
        'Project not found. Please check the code and try again.';
      } else if (e.statusCode == 422) {
        errorMessage.value = 'Invalid project code.';
      } else if (e.isNetworkError) {
        errorMessage.value = 'No internet connection. Please try again.';
      } else {
        errorMessage.value = e.message;
      }
      return false;
    } catch (e) {
      print(' [ProjectController] Unexpected error: $e');
      errorMessage.value = 'Failed to load project. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refresh() async {
    final code = lastProjectCode.value;
    if (code.isEmpty) return;
    await loadQueue(code);
  }
}