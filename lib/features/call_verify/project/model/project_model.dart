class ProjectQueueResponse {
  final Project project;
  final List<Survey> surveys;

  const ProjectQueueResponse({
    required this.project,
    required this.surveys,
  });

  factory ProjectQueueResponse.fromJson(Map<String, dynamic> json) {
    final projectJson = json['project'];
    final surveyJson = json['surveys'];

    return ProjectQueueResponse(
      project: Project.fromJson(
        projectJson is Map
            ? Map<String, dynamic>.from(projectJson)
            : <String, dynamic>{},
      ),
      surveys: surveyJson is List
          ? surveyJson
          .whereType<Map>()
          .map((e) => Survey.fromJson(Map<String, dynamic>.from(e)))
          .toList()
          : <Survey>[],
    );
  }
}

class Project {
  final int code;
  final String name;

  const Project({
    required this.code,
    required this.name,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      code: _toInt(json['code']),
      name: _toStringValue(json['name']),
    );
  }
}

class Survey {
  final String surveyId;
  final String surveyTitle;
  final String mobileFieldName;
  final List<String> fields;
  final List<SurveyResponse> responses;

  const Survey({
    required this.surveyId,
    required this.surveyTitle,
    required this.mobileFieldName,
    required this.fields,
    required this.responses,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      surveyId: _toStringValue(json['survey_id']),
      surveyTitle: _toStringValue(json['survey_title']),
      mobileFieldName: _toStringValue(json['mobile_field_name']),
      fields: _toStringList(json['fields']),
      responses: json['responses'] is List
          ? (json['responses'] as List)
          .whereType<Map>()
          .map((e) => SurveyResponse.fromJson(
        Map<String, dynamic>.from(e),
      ))
          .toList()
          : <SurveyResponse>[],
    );
  }
}

class SurveyResponsesResponse {
  final String surveyId;
  final String surveyTitle;
  final String mobileFieldName;
  final List<String> fields;

  /// API-provided dropdown values for each field.
  /// Example: { "what_is_your_name": ["Gourav", "Aman"] }
  final Map<String, List<String>> fieldValues;

  final int total;
  final int skip;
  final int limit;
  final List<SurveyResponse> items;

  const SurveyResponsesResponse({
    required this.surveyId,
    required this.surveyTitle,
    required this.mobileFieldName,
    required this.fields,
    this.fieldValues = const <String, List<String>>{},
    required this.total,
    required this.skip,
    required this.limit,
    required this.items,
  });

  bool get hasMore => skip + items.length < total;
  int get loadedCount => items.length;

  factory SurveyResponsesResponse.fromJson(Map<String, dynamic> json) {
    final rawFieldValues = json['field_values'];
    final parsedFieldValues = <String, List<String>>{};

    if (rawFieldValues is Map) {
      rawFieldValues.forEach((key, value) {
        parsedFieldValues[key.toString()] = _toStringList(value);
      });
    }

    final rawItems = json['items'];

    return SurveyResponsesResponse(
      surveyId: _toStringValue(json['survey_id']),
      surveyTitle: _toStringValue(json['survey_title']),
      mobileFieldName: _toStringValue(json['mobile_field_name']),
      fields: _toStringList(json['fields']),
      fieldValues: parsedFieldValues,
      total: _toInt(json['total']),
      skip: _toInt(json['skip']),
      limit: _toInt(json['limit'], fallback: 50),
      items: rawItems is List
          ? rawItems
          .whereType<Map>()
          .map((e) => SurveyResponse.fromJson(
        Map<String, dynamic>.from(e),
      ))
          .toList()
          : <SurveyResponse>[],
    );
  }
}

class SurveyResponse {
  final int responseId;
  final String phone;
  final Map<String, dynamic> answers;
  final String createdAt;
  final LastCall? lastCall;

  const SurveyResponse({
    required this.responseId,
    required this.phone,
    required this.answers,
    required this.createdAt,
    required this.lastCall,
  });

  factory SurveyResponse.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'];

    return SurveyResponse(
      responseId: _toInt(json['response_id']),
      phone: _toStringValue(json['phone']),
      answers: rawAnswers is Map
          ? Map<String, dynamic>.from(rawAnswers)
          : <String, dynamic>{},
      createdAt: _toStringValue(json['created_at']),
      lastCall: json['last_call'] is Map
          ? LastCall.fromJson(
        Map<String, dynamic>.from(json['last_call']),
      )
          : null,
    );
  }

  String get name => _toStringValue(answers['what_is_your_name']);
  String get candidate => _toStringValue(answers['vendor_name']);
  String get gender => _toStringValue(answers['gender']);
  String get acName => _toStringValue(answers['ac_name']);
  String get user => _toStringValue(answers['what_is_your_mobile_number']);

  String get village {
    final value = answers['select_state'];
    if (value is List) return value.map((e) => e.toString()).join(', ');
    return _toStringValue(value);
  }

  String get slotNo => _toStringValue(answers['what_is_your_age']);
  String get block => _toStringValue(answers['select_country']);
  String get passFailStatus => lastCall?.status ?? 'Pending';
  String get extraDetails => '—';

  dynamic getAnswer(String key) => answers[key];

  static String formatAnswer(dynamic value) {
    if (value == null) return '—';

    if (value is String) {
      return value.trim().isEmpty ? '—' : value;
    }

    if (value is List) {
      if (value.isEmpty) return '—';
      return value.map(formatAnswer).where((e) => e != '—').join(', ');
    }

    if (value is Map) {
      if (value.isEmpty) return '—';
      return value.entries
          .map((e) => '${e.key}: ${formatAnswer(e.value)}')
          .join('\n');
    }

    return value.toString();
  }
}

class LastCall {
  final String status;
  final String callerName;
  final String createdAt;
  final int callDuration;

  const LastCall({
    required this.status,
    required this.callerName,
    required this.createdAt,
    required this.callDuration,
  });

  factory LastCall.fromJson(Map<String, dynamic> json) {
    return LastCall(
      status: _toStringValue(json['status']),
      callerName: _toStringValue(json['caller_name']),
      createdAt: _toStringValue(json['created_at']),
      callDuration: _toInt(json['call_duration']),
    );
  }

  String get formattedDuration {
    final seconds = callDuration;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${remainingSeconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _toStringValue(dynamic value) => value?.toString() ?? '';

List<String> _toStringList(dynamic value) {
  if (value is! List) return <String>[];
  return value.map((e) => e?.toString() ?? '').toList();
}
