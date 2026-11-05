
import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_provider.dart';
import '../model/project_model.dart';

class ProjectController extends GetxController {
  final ApiProvider _api = Get.find<ApiProvider>();

  // ============================================================
  // PROJECT QUEUE STATE - API 1
  // ============================================================

  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  final Rxn<ProjectQueueResponse> queue =
  Rxn<ProjectQueueResponse>();

  // ============================================================
  // LAST USED PROJECT CODE
  // ============================================================

  static const String _prefsKey = 'last_project_code';

  final RxString lastProjectCode = ''.obs;

  // ============================================================
  // SURVEY RESPONSES STATE - API 2
  // Each survey has its own response data.
  // ============================================================

  final RxMap<String, SurveyResponsesResponse> responsesBySurvey =
      <String, SurveyResponsesResponse>{}.obs;

  final RxMap<String, bool> responseLoading =
      <String, bool>{}.obs;

  final RxMap<String, bool> loadingMore =
      <String, bool>{}.obs;

  final RxMap<String, String> responseErrors =
      <String, String>{}.obs;

  // ============================================================
  // FILTER STATE
  // ============================================================

  final RxString searchQuery = ''.obs;

  // Supported API values: '', today, yesterday
  final RxString selectedPeriod = ''.obs;

  final RxString startDate = ''.obs;
  final RxString endDate = ''.obs;

  // Dynamic filters.
  // Example: {"gender": "Male", "age": "25"}
  final RxMap<String, dynamic> fieldFilters =
      <String, dynamic>{}.obs;

  // ============================================================
  // PAGINATION
  // ============================================================

  static const int defaultLimit = 50;

  final RxInt pageLimit = defaultLimit.obs;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  @override
  void onInit() {
    super.onInit();
    _loadLastCode();
  }

  // ============================================================
  // CONVENIENCE GETTERS
  // ============================================================

  Project? get project => queue.value?.project;

  List<Survey> get surveys =>
      queue.value?.surveys ?? <Survey>[];

  /// Returns the complete API response for a survey.
  SurveyResponsesResponse? getResponses(String surveyId) {
    return responsesBySurvey[surveyId];
  }

  /// Returns only the response items.
  /// This method returns List<SurveyResponse>.
  List<SurveyResponse> getSurveyResponses(String surveyId) {
    return responsesBySurvey[surveyId]?.items ??
        <SurveyResponse>[];
  }

  /// Returns the total number of records from the API.
  int getTotalResponses(String surveyId) {
    return responsesBySurvey[surveyId]?.total ?? 0;
  }

  bool isSurveyLoading(String surveyId) {
    return responseLoading[surveyId] ?? false;
  }

  bool isLoadingMore(String surveyId) {
    return loadingMore[surveyId] ?? false;
  }

  String? getResponseError(String surveyId) {
    return responseErrors[surveyId];
  }

  bool hasMoreResponses(String surveyId) {
    return responsesBySurvey[surveyId]?.hasMore ?? false;
  }

  // ============================================================
  // SHARED PREFERENCES
  // ============================================================

  Future<void> _loadLastCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      lastProjectCode.value =
          prefs.getString(_prefsKey) ?? '';
    } catch (e) {
      print('[ProjectController] Load project code error: $e');
    }
  }

  Future<void> _saveLastCode(String code) async {
    lastProjectCode.value = code;

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_prefsKey, code);
    } catch (e) {
      print('[ProjectController] Save project code error: $e');
    }
  }

  // ============================================================
  // API 1: LOAD PROJECT QUEUE
  //
  // GET /calling-app/queue?project_code=9999
  //
  // Returns:
  // Project + Surveys
  // ============================================================

  Future<bool> loadQueue(String projectCode) async {
    if (projectCode.trim().isEmpty) {
      errorMessage.value = 'Project code is required.';
      return false;
    }

    if (isLoading.value) return false;

    isLoading.value = true;
    errorMessage.value = null;
    queue.value = null;

    // Clear old response data when loading another project.
    responsesBySurvey.clear();
    responseLoading.clear();
    loadingMore.clear();
    responseErrors.clear();

    // Reset filter state.
    _resetFilterState();

    try {
      final code = projectCode.trim();

      final endpoint =
          '${ApiProvider.apiPrefix}/calling-app/queue';

      final uri = Uri(
        path: endpoint,
        queryParameters: {
          'project_code': code,
        },
      );

      print('[ProjectController] GET $uri');

      final resp = await _api.get(uri.toString());

      final parsed = ProjectQueueResponse.fromJson(
        Map<String, dynamic>.from(resp),
      );

      queue.value = parsed;

      await _saveLastCode(code);

      print(
        '[ProjectController] Loaded "${parsed.project.name}" '
            '(${parsed.surveys.length} surveys) for code=$code',
      );

      return true;
    } on ApiException catch (e) {
      print('[ProjectController] API error: ${e.message}');

      if (e.statusCode == 404) {
        errorMessage.value =
        'Project not found. Please check the code and try again.';
      } else if (e.statusCode == 422) {
        errorMessage.value = 'Invalid project code.';
      } else if (e.isNetworkError) {
        errorMessage.value =
        'No internet connection. Please try again.';
      } else {
        errorMessage.value = e.message;
      }

      return false;
    } catch (e) {
      print('[ProjectController] Unexpected error: $e');

      errorMessage.value =
      'Failed to load project. Please try again.';

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // API 2: LOAD SURVEY RESPONSES
  //
  // GET /calling-app/queue/{survey_id}/responses
  //
  // Query parameters:
  // search
  // period
  // start_date
  // end_date
  // field_filters
  // skip
  // limit
  // ============================================================

  Future<bool> loadSurveyResponses(
      String surveyId, {
        bool reset = true,
      }) async {
    if (surveyId.trim().isEmpty) {
      print('[ProjectController] Survey ID is empty.');
      return false;
    }

    if (responseLoading[surveyId] == true) {
      return false;
    }

    if (!reset && loadingMore[surveyId] == true) {
      return false;
    }

    final existing = responsesBySurvey[surveyId];

    // Calculate pagination offset.
    final int skip = reset ? 0 : (existing?.items.length ?? 0);

    // Stop when all available responses have been loaded.
    if (!reset && existing != null && !existing.hasMore) {
      return false;
    }

    responseLoading[surveyId] = true;
    loadingMore[surveyId] = !reset;

    if (reset) {
      responseErrors.remove(surveyId);
    }

    try {
      final endpoint =
          '${ApiProvider.apiPrefix}/calling-app/queue/'
          '${Uri.encodeComponent(surveyId)}/responses';

      final Map<String, String> params = {
        'skip': skip.toString(),
        'limit': pageLimit.value.toString(),
      };

      // SEARCH FILTER
      if (searchQuery.value.trim().isNotEmpty) {
        params['search'] = searchQuery.value.trim();
      }

      // PERIOD FILTER
      if (selectedPeriod.value.isNotEmpty) {
        params['period'] = selectedPeriod.value;
      }

      // START DATE FILTER
      if (startDate.value.isNotEmpty) {
        params['start_date'] = startDate.value;
      }

      // END DATE FILTER
      if (endDate.value.isNotEmpty) {
        params['end_date'] = endDate.value;
      }

      // DYNAMIC FIELD FILTERS
      if (fieldFilters.isNotEmpty) {
        params['field_filters'] = jsonEncode(
          Map<String, dynamic>.from(fieldFilters),
        );
      }

      final uri = Uri(
        path: endpoint,
        queryParameters: params,
      );

      print('[ProjectController] GET $uri');

      final resp = await _api.get(uri.toString());

      final parsed = SurveyResponsesResponse.fromJson(
        Map<String, dynamic>.from(resp),
      );

      if (reset || existing == null) {
        // First page or applying new filters.
        responsesBySurvey[surveyId] = parsed;
      } else {
        // Append the next page without removing existing records.
        final combinedItems = <SurveyResponse>[
          ...existing.items,
          ...parsed.items,
        ];

        responsesBySurvey[surveyId] = SurveyResponsesResponse(
          surveyId: parsed.surveyId,
          surveyTitle: parsed.surveyTitle,
          mobileFieldName: parsed.mobileFieldName,
          fields: parsed.fields,
          fieldValues: parsed.fieldValues.isNotEmpty
              ? parsed.fieldValues
              : existing.fieldValues,
          total: parsed.total,
          skip: 0,
          limit: parsed.limit,
          items: combinedItems,
        );
      }

      responseErrors.remove(surveyId);

      print(
        '[ProjectController] Responses loaded: '
            '${responsesBySurvey[surveyId]?.items.length}/'
            '${parsed.total} for survey=$surveyId',
      );

      return true;
    } on ApiException catch (e) {
      print(
        '[ProjectController] Response API error: ${e.message}',
      );

      responseErrors[surveyId] = _getApiErrorMessage(e);

      return false;
    } catch (e) {
      print(
        '[ProjectController] Unexpected response error: $e',
      );

      responseErrors[surveyId] =
      'Failed to load responses. Please try again.';

      return false;
    } finally {
      responseLoading[surveyId] = false;
      loadingMore[surveyId] = false;
    }
  }

  // ============================================================
  // LOAD MORE RESPONSES
  // ============================================================

  Future<void> loadMoreResponses(String surveyId) async {
    if (!hasMoreResponses(surveyId)) return;

    if (isSurveyLoading(surveyId)) return;

    await loadSurveyResponses(
      surveyId,
      reset: false,
    );
  }

  // ============================================================
  // REFRESH SURVEY RESPONSES
  // ============================================================

  Future<void> refreshSurveyResponses(String surveyId) async {
    await loadSurveyResponses(
      surveyId,
      reset: true,
    );
  }

  // ============================================================
  // APPLY ALL FILTERS
  //
  // Supports:
  // search
  // today
  // yesterday
  // custom date range
  // this week
  // this month
  // dynamic field filters
  // ============================================================

  Future<void> applyResponseFilters({
    String search = '',
    String period = '',
    String fromDate = '',
    String toDate = '',
    Map<String, dynamic> filters = const {},
    required String surveyId,
  }) async {
    searchQuery.value = search.trim();

    startDate.value = fromDate;
    endDate.value = toDate;

    selectedPeriod.value = period;

    // The documented API supports only today and yesterday
    // as period values. Convert week/month to date ranges.
    if (period == 'this_week') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Monday is the first day of the week.
      final monday = today.subtract(
        Duration(days: today.weekday - 1),
      );

      startDate.value = _formatDate(monday);
      endDate.value = _formatDate(today);
      selectedPeriod.value = '';
    } else if (period == 'this_month') {
      final now = DateTime.now();

      final firstDay = DateTime(now.year, now.month, 1);
      final today = DateTime(now.year, now.month, now.day);

      startDate.value = _formatDate(firstDay);
      endDate.value = _formatDate(today);
      selectedPeriod.value = '';
    } else if (fromDate.isNotEmpty || toDate.isNotEmpty) {
      // Custom date selection takes precedence over period.
      selectedPeriod.value = '';
    }

    fieldFilters.assignAll(filters);

    await loadSurveyResponses(
      surveyId,
      reset: true,
    );
  }

  // ============================================================
  // SEARCH FILTER
  // ============================================================

  Future<void> searchResponses(
      String surveyId,
      String search,
      ) async {
    searchQuery.value = search.trim();

    await loadSurveyResponses(
      surveyId,
      reset: true,
    );
  }

  // ============================================================
  // TODAY / YESTERDAY FILTER
  // ============================================================

  Future<void> filterByPeriod(
      String surveyId,
      String period,
      ) async {
    if (period != '' &&
        period != 'today' &&
        period != 'yesterday') {
      print(
        '[ProjectController] Unsupported API period: $period',
      );
      return;
    }

    selectedPeriod.value = period;
    startDate.value = '';
    endDate.value = '';

    await loadSurveyResponses(
      surveyId,
      reset: true,
    );
  }

  // ============================================================
  // DATE RANGE FILTER
  // Dates must be YYYY-MM-DD
  // ============================================================

  Future<void> filterByDateRange(
      String surveyId, {
        required String fromDate,
        required String toDate,
      }) async {
    selectedPeriod.value = '';

    startDate.value = fromDate;
    endDate.value = toDate;

    await loadSurveyResponses(
      surveyId,
      reset: true,
    );
  }

  // ============================================================
  // DYNAMIC FIELD FILTER
  //
  // Example:
  // updateFieldFilter(
  //   surveyId: id,
  //   fieldName: 'gender',
  //   value: 'Male',
  // );
  // ============================================================

  Future<void> updateFieldFilter({
    required String surveyId,
    required String fieldName,
    required dynamic value,
  }) async {
    if (value == null || value.toString().trim().isEmpty) {
      fieldFilters.remove(fieldName);
    } else {
      fieldFilters[fieldName] = value;
    }

    await loadSurveyResponses(
      surveyId,
      reset: true,
    );
  }

  // ============================================================
  // CLEAR ALL FILTERS
  // ============================================================

  Future<void> clearFilters(String surveyId) async {
    _resetFilterState();

    await loadSurveyResponses(
      surveyId,
      reset: true,
    );
  }

  void _resetFilterState() {
    searchQuery.value = '';
    selectedPeriod.value = '';
    startDate.value = '';
    endDate.value = '';
    fieldFilters.clear();
  }

  // ============================================================
  // DATE HELPER
  // ============================================================

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  // ============================================================
  // ERROR MESSAGE HELPER
  // ============================================================

  String _getApiErrorMessage(ApiException e) {
    if (e.statusCode == 404) {
      return 'Survey responses not found.';
    }

    if (e.statusCode == 422) {
      return 'Invalid filter parameters.';
    }

    if (e.isNetworkError) {
      return 'No internet connection. Please try again.';
    }

    return e.message;
  }

  // ============================================================
  // REFRESH PROJECT QUEUE
  // ============================================================

  Future<void> refresh() async {
    final code = lastProjectCode.value;

    if (code.isEmpty) return;

    await loadQueue(code);
  }
}
