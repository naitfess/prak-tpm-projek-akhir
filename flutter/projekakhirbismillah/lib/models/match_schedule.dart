import 'team.dart';

class MatchSchedule {
  final int id;
  final int team1Id;
  final int team2Id;
  final DateTime date;
  final String time;
  final int? skor1;
  final int? skor2;
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
      skor1: json['skor1'],
      skor2: json['skor2'],
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isBaru => skor1 == 0 && skor2 == 0 && createdAt == updatedAt;

  bool get isFinished {
    // Jika skor sudah diupdate (updatedAt != createdAt) atau skor tidak 0-0, anggap sudah selesai
    if (isBaru) return false;
    return true;
  }

  String get status {
    if (isBaru) return 'Belum Dimainkan';
    return 'Selesai';
  }

  String get winner {
    if (skor1 == 0 && skor2 == 0) return 'Belum Dimainkan';
    if (skor1! > skor2!) return team1?.name ?? 'Team 1';
    if (skor2! > skor1!) return team2?.name ?? 'Team 2';
    return 'Seri';
  }

  String get result {
    if (skor1 == null || skor2 == null) {
      return 'vs';
    }
    return '$skor1 - $skor2';
  }
}
