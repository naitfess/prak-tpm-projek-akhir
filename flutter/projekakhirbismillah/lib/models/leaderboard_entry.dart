class LeaderboardEntry {
  final int rank;
  final int id;
  final String username;
  final int poin;

  LeaderboardEntry({
    required this.rank,
    required this.id,
    required this.username,
    required this.poin,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      poin: json['poin'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'id': id,
      'username': username,
      'poin': poin,
    };
  }
}

class LeaderboardStats {
  final int totalUsers;
  final int highestScore;
  final double averageScore;
  final int totalPoints;
  final LeaderboardTopUser? topUser;

  LeaderboardStats({
    required this.totalUsers,
    required this.highestScore,
    required this.averageScore,
    required this.totalPoints,
    this.topUser,
  });

  factory LeaderboardStats.fromJson(Map<String, dynamic> json) {
    return LeaderboardStats(
      totalUsers: json['totalUsers'] ?? 0,
      highestScore: json['highestScore'] ?? 0,
      averageScore: double.tryParse(json['averageScore'].toString()) ?? 0.0,
      totalPoints: json['totalPoints'] ?? 0,
      topUser: json['topUser'] != null 
        ? LeaderboardTopUser.fromJson(json['topUser']) 
        : null,
    );
  }
}

class LeaderboardTopUser {
  final String username;
  final int poin;

  LeaderboardTopUser({
    required this.username,
    required this.poin,
  });

  factory LeaderboardTopUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardTopUser(
      username: json['username'] ?? '',
      poin: json['poin'] ?? 0,
    );
  }
}

class UserRank {
  final int rank;
  final String username;
  final int poin;
  final int totalUsers;

  UserRank({
    required this.rank,
    required this.username,
    required this.poin,
    required this.totalUsers,
  });

  factory UserRank.fromJson(Map<String, dynamic> json) {
    return UserRank(
      rank: json['rank'] ?? 0,
      username: json['username'] ?? '',
      poin: json['poin'] ?? 0,
      totalUsers: json['totalUsers'] ?? 0,
    );
  }
}
