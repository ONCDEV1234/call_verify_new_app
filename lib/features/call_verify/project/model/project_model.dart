
class ProjectQueueResponse {
  final Project project;
  final List<Survey> surveys;

  const ProjectQueueResponse({
    required this.project,
    required this.surveys,
  });

  factory ProjectQueueResponse.fromJson(Map<String, dynamic> json) {
    final projectMap = json['project'];
    final surveysList = json['surveys'];

    return ProjectQueueResponse(
      project: Project.fromJson(
        projectMap is Map
            ? Map<String, dynamic>.from(projectMap)
            : <String, dynamic>{},
      ),
      surveys: (surveysList is List)
          ? surveysList
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
      code: (json['code'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
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
    final fieldsList = json['fields'];
    final responsesList = json['responses'];

    return Survey(
      surveyId: json['survey_id']?.toString() ?? '',
      surveyTitle: json['survey_title']?.toString() ?? '',
      mobileFieldName: json['mobile_field_name']?.toString() ?? '',
      fields: (fieldsList is List)
          ? fieldsList.map((e) => e.toString()).toList()
          : <String>[],
      responses: (responsesList is List)
          ? responsesList
          .whereType<Map>()
          .map((e) => SurveyResponse.fromJson(Map<String, dynamic>.from(e)))
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
    final answersMap = json['answers'];
    final lastCallMap = json['last_call'];

    return SurveyResponse(
      responseId: (json['response_id'] as num?)?.toInt() ?? 0,
      phone: json['phone']?.toString() ?? '',
      answers: answersMap is Map
          ? Map<String, dynamic>.from(answersMap)
          : <String, dynamic>{},
      createdAt: json['created_at']?.toString() ?? '',
      lastCall: (lastCallMap is Map && lastCallMap.isNotEmpty)
          ? LastCall.fromJson(Map<String, dynamic>.from(lastCallMap))
          : null,
    );
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
      status: json['status']?.toString() ?? '',
      callerName: json['caller_name']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      callDuration: (json['call_duration'] as num?)?.toInt() ?? 0,
    );
  }
}