import 'match_schedule.dart';

class Prediction {
  final int id;
  final int userId;
  final int matchScheduleId;
  final int predictedTeamId;
  final bool? status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Prediction({
    required this.id,
    required this.userId,
    required this.matchScheduleId,
    required this.predictedTeamId,
    this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      id: json['id'],
      userId: json['user_id'],
      matchScheduleId: json['match_schedule_id'],
      predictedTeamId: json['predicted_team_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
