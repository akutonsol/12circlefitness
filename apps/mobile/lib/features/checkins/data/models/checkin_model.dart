enum CheckinStatus { pending, submitted, reviewed }

class CheckinQuestion {
  final String id;
  final String question;
  final String type;
  final List<String>? options;

  CheckinQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.options,
  });
}

class CheckinResponse {
  final String questionId;
  final dynamic answer;

  CheckinResponse({required this.questionId, required this.answer});
}

class CoachFeedback {
  final String message;
  final List<String> recommendations;
  final DateTime reviewedAt;
  final String coachName;

  CoachFeedback({
    required this.message,
    required this.recommendations,
    required this.reviewedAt,
    required this.coachName,
  });
}

class WeeklyCheckin {
  final String id;
  final int weekNumber;
  final DateTime weekStartDate;
  final CheckinStatus status;
  final List<CheckinResponse> responses;
  final CoachFeedback? feedback;
  final double overallScore;
  final DateTime? submittedAt;

  WeeklyCheckin({
    required this.id,
    required this.weekNumber,
    required this.weekStartDate,
    required this.status,
    required this.responses,
    this.feedback,
    required this.overallScore,
    this.submittedAt,
  });
}
