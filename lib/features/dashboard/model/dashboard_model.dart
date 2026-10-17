class DashboardModel {
  final DateRangeModel dateRange;
  final int totalCalls;
  final int acceptedCalls;
  final int rejectedCalls;
  final List<HourlyCallModel> hourlyChart;
  final List<RecentCallModel> recentCalls;

  const DashboardModel({
    required this.dateRange,
    required this.totalCalls,
    required this.acceptedCalls,
    required this.rejectedCalls,
    required this.hourlyChart,
    required this.recentCalls,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final chartJson = json['hourly_chart'] as List? ?? [];
    final recentJson = json['recent_calls'] as List? ?? [];

    return DashboardModel(
      dateRange: DateRangeModel.fromJson(
        json['date_range'] as Map<String, dynamic>? ?? {},
      ),
      totalCalls: _asInt(json['total_calls']),
      acceptedCalls: _asInt(json['accepted_calls']),
      rejectedCalls: _asInt(json['rejected_calls']),
      hourlyChart: chartJson
          .whereType<Map>()
          .map((item) => HourlyCallModel.fromJson(
        Map<String, dynamic>.from(item),
      ))
          .toList(),
      recentCalls: recentJson
          .whereType<Map>()
          .map((item) => RecentCallModel.fromJson(
        Map<String, dynamic>.from(item),
      ))
          .toList(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DateRangeModel {
  final String fromDate;
  final String toDate;

  const DateRangeModel({
    required this.fromDate,
    required this.toDate,
  });

  factory DateRangeModel.fromJson(Map<String, dynamic> json) {
    return DateRangeModel(
      fromDate: json['from_date']?.toString() ?? '',
      toDate: json['to_date']?.toString() ?? '',
    );
  }
}

class HourlyCallModel {
  final int hour;
  final int total;
  final int accepted;
  final int rejected;

  const HourlyCallModel({
    required this.hour,
    required this.total,
    required this.accepted,
    required this.rejected,
  });

  factory HourlyCallModel.fromJson(Map<String, dynamic> json) {
    return HourlyCallModel(
      hour: DashboardModel._asInt(json['hour']),
      total: DashboardModel._asInt(json['total']),
      accepted: DashboardModel._asInt(json['accepted']),
      rejected: DashboardModel._asInt(json['rejected']),
    );
  }
}

class RecentCallModel {
  final String phone;
  final DateTime? callTime;
  final int callDuration;
  final int processDuration;
  final String userStatus;
  final String classification;
  final String direction;

  const RecentCallModel({
    required this.phone,
    required this.callTime,
    required this.callDuration,
    required this.processDuration,
    required this.userStatus,
    required this.classification,
    required this.direction,
  });

  bool get isAccepted =>
      classification.trim().toLowerCase() == 'accepted';

  factory RecentCallModel.fromJson(Map<String, dynamic> json) {
    final rawTime = json['call_start_at'] ??
        json['call_start_time'] ??
        json['created_at'];

    return RecentCallModel(
      phone: (json['phone_dialed'] ??
          json['phone'] ??
          json['phone_number'] ??
          'Unknown number')
          .toString(),
      callTime: _parseDate(rawTime),
      callDuration: DashboardModel._asInt(json['call_duration']),
      processDuration: DashboardModel._asInt(json['process_duration']),
      userStatus: (json['status'] ?? 'Not specified').toString(),
      classification: (json['classification'] ??
          json['call_classification'] ??
          _fallbackClassification(json))
          .toString(),
      direction: (json['direction'] ?? json['call_type'] ?? '')
          .toString()
          .toLowerCase(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static String _fallbackClassification(Map<String, dynamic> json) {
    final status = (json['status'] ?? '').toString().trim().toLowerCase();
    final duration = DashboardModel._asInt(json['call_duration']);

    return status == 'correct' && duration > 5 ? 'Accepted' : 'Rejected';
  }
}