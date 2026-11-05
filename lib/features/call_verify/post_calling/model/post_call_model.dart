
class PostCallModel {
  final int responseId;
  final String phoneDialed;
  final String status;
  final String remarks;
  final int callDuration;
  final DateTime callStartAt;
  final DateTime callEndAt;
  final int processDuration;
  final String source;

  const PostCallModel({
    required this.responseId,
    required this.phoneDialed,
    required this.status,
    required this.remarks,
    required this.callDuration,
    required this.callStartAt,
    required this.callEndAt,
    required this.processDuration,
    this.source = 'mobile_app',
  });

  /// Existing JSON conversion.
  /// Preserved for compatibility with existing code.
  Map<String, dynamic> toJson() {
    return {
      'response_id': responseId,
      'phone_dialed': phoneDialed,
      'status': status,
      'remarks': remarks,
      'call_duration': callDuration,
      'call_start_at': callStartAt.toUtc().toIso8601String(),
      'call_end_at': callEndAt.toUtc().toIso8601String(),
      'process_duration': processDuration,
      'source': source,
    };
  }

  /// New multipart form fields.
  /// Used by ApiProvider.postMultipart().
  Map<String, String> toMultipartFields() {
    return {
      'response_id': responseId.toString(),
      'phone_dialed': phoneDialed,
      'status': status,
      'remarks': remarks,
      'call_duration': callDuration.toString(),
      'call_start_at': callStartAt.toUtc().toIso8601String(),
      'call_end_at': callEndAt.toUtc().toIso8601String(),
      'process_duration': processDuration.toString(),
      'source': source,
    };
  }

  factory PostCallModel.fromJson(Map<String, dynamic> json) {
    return PostCallModel(
      responseId: _toInt(json['response_id']),
      phoneDialed: (json['phone_dialed'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      remarks: (json['remarks'] ?? '').toString(),
      callDuration: _toInt(json['call_duration']),
      callStartAt: _parseDateTime(json['call_start_at']),
      callEndAt: _parseDateTime(json['call_end_at']),
      processDuration: _toInt(json['process_duration']),
      source: (json['source'] ?? 'mobile_app').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;

    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
