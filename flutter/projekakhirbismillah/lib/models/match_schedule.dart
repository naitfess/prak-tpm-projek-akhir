import 'team.dart';

class MatchSchedule {
  final int id;
  final int? team1Id;
  final int? team2Id;
  final String date;
  final String time;
  final int skor1; // Remove nullable - make it non-null with default 0
  final int skor2; // Remove nullable - make it non-null with default 0
  final String? createdAt;
  final String? updatedAt;
  final Team? team1;
  final Team? team2;

  MatchSchedule({
    required this.id,
    this.team1Id,
    this.team2Id,
    required this.date,
    required this.time,
    this.skor1 = 0, // Default value 0
    this.skor2 = 0, // Default value 0
    this.createdAt,
    this.updatedAt,
    this.team1,
    this.team2,
  });

  factory MatchSchedule.fromJson(Map<String, dynamic> json) {
    return MatchSchedule(
      id: json['id'],
      team1Id: json['team1_id'],
      team2Id: json['team2_id'],
      date: json['date'],
      time: json['time'],
      skor1: json['skor1'] ?? 0, // Handle null with default 0
      skor2: json['skor2'] ?? 0, // Handle null with default 0
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
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
    // Match dianggap finished jika ada perubahan dari created ke updated
    // dan skor tidak 0-0
    if (createdAt != null && updatedAt != null && createdAt != updatedAt) {
      return skor1 > 0 || skor2 > 0;
    }
    return false;
  }

  String get status {
    if (isFinished) {
      return 'Selesai';
    }
    
    try {
      // Cek apakah match sudah dimulai berdasarkan waktu
      final now = DateTime.now();
      // Parse date dan time dengan format yang benar
      final matchDate = DateTime.parse(date);
      final timeParts = time.split(':');
      final matchDateTime = DateTime(
        matchDate.year,
        matchDate.month,
        matchDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        timeParts.length > 2 ? int.parse(timeParts[2]) : 0,
      );
      
      if (now.isAfter(matchDateTime)) {
        return 'Berlangsung';
      }
    } catch (e) {
      print('Error parsing date/time: $e');
      // Fallback jika ada error parsing
    }
    
    return 'Belum Dimainkan';
  }

  String get winner {
    if (!isFinished) return '';
    
    if (skor1 > skor2) {
      return team1?.name ?? 'Tim 1';
    } else if (skor2 > skor1) {
      return team2?.name ?? 'Tim 2';
    } else {
      return 'Seri'; // Draw result
    }
  }

  String get result {
    if (skor1 == null || skor2 == null) {
      return 'vs';
    }
    return '$skor1 - $skor2';
  }
}
