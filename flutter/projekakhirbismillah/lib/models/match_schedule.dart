import 'team.dart';

class MatchSchedule {
  final int id;
  final int team1Id;
  final int team2Id;
  final DateTime date;
  final String time;
  final int? skor1;
  final int? skor2;
  final bool isFinished; // Add this field
  final DateTime createdAt;
  final DateTime updatedAt;
  final Team? team1;
  final Team? team2;

  MatchSchedule({
    required this.id,
    required this.team1Id,
    required this.team2Id,
    required this.date,
    required this.time,
    this.skor1,
    this.skor2,
    required this.isFinished, // Add this field
    required this.createdAt,
    required this.updatedAt,
    this.team1,
    this.team2,
  });

  factory MatchSchedule.fromJson(Map<String, dynamic> json) {
    return MatchSchedule(
      id: json['id'] ?? 0,
      team1Id: json['team1_id'] ?? json['team1Id'] ?? 0,
      team2Id: json['team2_id'] ?? json['team2Id'] ?? 0,
      date: json['date'] is String
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      time: json['time'] ?? '00:00',
      skor1: json['skor1'] ?? 0,
      skor2: json['skor2'] ?? 0,
      isFinished: json['is_finished'] ?? false, // Add this field
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      team1: json['team1'] != null ? Team.fromJson(json['team1']) : null,
      team2: json['team2'] != null ? Team.fromJson(json['team2']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team1_id': team1Id,
      'team2_id': team2Id,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      'skor1': skor1,
      'skor2': skor2,
      'is_finished': isFinished, // Add this field
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get status {
    if (!isFinished) return 'Belum Dimainkan';
    return 'Selesai';
  }
  
  String get winner {
    if (!isFinished) return 'Belum Dimainkan';
    if (skor1! > skor2!) return team1?.name ?? 'Team 1';
    if (skor2! > skor1!) return team2?.name ?? 'Team 2';
    return 'Seri';
  }

  String get result {
    if (!isFinished || skor1 == null || skor2 == null) {
      return 'vs';
    }
    return '$skor1 - $skor2';
  }
}