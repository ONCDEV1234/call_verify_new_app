import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/network/api_provider.dart';
import '../model/dashboard_model.dart';

enum DashboardFilterType { day, date, range }

class DashboardController extends GetxController {
  DashboardController({ApiProvider? apiProvider})
      : _api = apiProvider ?? Get.find<ApiProvider>();

  final ApiProvider _api;

  static const String _dashboardPath =
      '/api/leadtech/api/v1/calling-app/my-dashboard';

  static const String _pdfPath =
      '/api/leadtech/api/v1/calling-app/my-dashboard/pdf';

  final RxBool isLoading = false.obs;
  final RxBool isDownloadingPdf = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<DashboardModel?> dashboard = Rx<DashboardModel?>(null);

  final Rx<DashboardFilterType> filterType =
      DashboardFilterType.day.obs;

  final RxString selectedDay = 'today'.obs;

  final Rx<DateTime> selectedDate = DateTime.now().obs;

  final Rx<DateTime> rangeStart = DateTime.now().obs;
  final Rx<DateTime> rangeEnd = DateTime.now().obs;

  String _dateString(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
  }

  Map<String, String> _currentQuery() {
    switch (filterType.value) {
      case DashboardFilterType.day:
        return {'period': selectedDay.value};

      case DashboardFilterType.date:
        return {'date': _dateString(selectedDate.value)};

      case DashboardFilterType.range:
        return {
          'from_date': _dateString(rangeStart.value),
          'to_date': _dateString(rangeEnd.value),
        };
    }
  }


  String _urlWithQuery(String path) {
    return Uri(
      path: path,
      queryParameters: _currentQuery(),
    ).toString();
  }

  Future<void> fetchDashboard() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await _api.get(
        _urlWithQuery(_dashboardPath),
      );

      dashboard.value = DashboardModel.fromJson(response);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> chooseFilterType(DashboardFilterType type) async {
    filterType.value = type;
    await fetchDashboard();
  }

  Future<void> chooseDay(String day) async {
    selectedDay.value = day;
    filterType.value = DashboardFilterType.day;

    await fetchDashboard();
  }

  Future<void> chooseDate(DateTime date) async {
    selectedDate.value = date;
    filterType.value = DashboardFilterType.date;

    await fetchDashboard();
  }

  Future<void> chooseRange(DateTime start, DateTime end) async {
    rangeStart.value = start.isBefore(end) ? start : end;
    rangeEnd.value = start.isBefore(end) ? end : start;

    filterType.value = DashboardFilterType.range;

    await fetchDashboard();
  }

  Future<void> downloadAndOpenPdf() async {
    if (isDownloadingPdf.value) return;

    isDownloadingPdf.value = true;

    try {
      final uri = Uri.parse(
        '${ApiProvider.baseUrl}${_urlWithQuery(_pdfPath)}',
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/pdf',
          if (_api.hasToken)
            'Authorization': 'Bearer ${_api.authToken}',
        },
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'PDF request failed (${response.statusCode}): ${response.body}',
        );
      }

      final directory = await getTemporaryDirectory();

      final file = File(
        '${directory.path}/my_call_dashboard_'
            '${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      await file.writeAsBytes(response.bodyBytes, flush: true);

      final result = await OpenFilex.open(file.path);

      if (result.type != ResultType.done) {
        throw Exception(
          result.message.isNotEmpty
              ? result.message
              : 'Could not open the downloaded PDF.',
        );
      }
    } catch (e) {
      Get.snackbar(
        'PDF download failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDownloadingPdf.value = false;
    }
  }
}