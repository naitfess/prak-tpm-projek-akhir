class News {
  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  News({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'],
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'date': date.toIso8601String().split('T')[0],
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
