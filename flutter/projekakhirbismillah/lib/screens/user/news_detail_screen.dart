import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/news.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NewsDetailScreen extends StatefulWidget {
  final News news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  List<Map<String, dynamic>> _comments = [];
  final _commentController = TextEditingController();
  int? _currentUserId;
  String? _currentUsername;
  Box? _commentsBox;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initHive();
      await _loadUser();
      await _loadComments();
    });
  }

  Future<void> _initHive() async {
    // Pastikan Hive sudah diinisialisasi di main.dart
    if (!Hive.isBoxOpen('commentsBox')) {
      _commentsBox = await Hive.openBox('commentsBox');
    } else {
      _commentsBox = Hive.box('commentsBox');
    }
  }

  Future<void> _loadUser() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _currentUserId = authProvider.user?.id;
      _currentUsername = authProvider.user?.username;
    });
  }

  Future<void> _loadComments() async {
    final key = 'comments_${widget.news.id}';
    if (_commentsBox == null) return;
    final List<dynamic>? stored = _commentsBox!.get(key);
    setState(() {
      // Pastikan casting aman, jika null atau bukan List<Map> maka fallback ke []
      _comments = (stored != null && stored is List)
          ? stored.map((e) => Map<String, dynamic>.from(e)).toList()
          : [];
    });
  }

  Future<void> _saveComments() async {
    final key = 'comments_${widget.news.id}';
    if (_commentsBox == null) return;
    await _commentsBox!.put(key, _comments);
  }

  Future<void> _addComment(String text) async {
    if (text.trim().isEmpty ||
        _currentUserId == null ||
        _currentUsername == null) return;
    setState(() {
      _comments.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'userId': _currentUserId,
        'username': _currentUsername,
        'text': text,
        'createdAt': DateTime.now().toIso8601String(),
      });
    });
    await _saveComments();
    _commentController.clear();
  }

  Future<void> _editComment(int index, String newText) async {
    setState(() {
      _comments[index]['text'] = newText;
      _comments[index]['editedAt'] = DateTime.now().toIso8601String();
    });
    await _saveComments();
  }

  Future<void> _deleteComment(int index) async {
    setState(() {
      _comments.removeAt(index);
    });
    await _saveComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _currentUserId;

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        elevation: 2,
        title: Row(
          children: [
            const Icon(Icons.newspaper, color: Colors.white, size: 26),
            const SizedBox(width: 8),
            const Text('News Detail',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.news.imageUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(18)),
                child: Image.network(
                  widget.news.imageUrl!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 220,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 100),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sports_soccer,
                              color: Colors.green, size: 28),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.news.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.green[700]),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.news.date.day}/${widget.news.date.month}/${widget.news.date.year}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.news.content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.comment,
                              color: Colors.green, size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Komentar',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _comments.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('Belum ada komentar.',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _comments.length,
                              itemBuilder: (context, index) {
                                final comment = _comments[index];
                                final isOwner = comment['userId'] == userId;
                                return Card(
                                  color: Colors.green[50],
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.green[200],
                                      child: Text(
                                        (comment['username'] ?? 'U')[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(comment['text']),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Oleh: ${comment['username'] ?? 'User'}',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green),
                                        ),
                                        Text(
                                          'Dibuat: ${DateTime.parse(comment['createdAt']).toLocal()}'
                                          '${comment['editedAt'] != null ? '\nDiedit: ${DateTime.parse(comment['editedAt']).toLocal()}' : ''}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    trailing: isOwner
                                        ? PopupMenuButton<String>(
                                            icon: const Icon(CupertinoIcons
                                                .ellipsis_vertical),
                                            onSelected: (value) async {
                                              if (value == 'edit') {
                                                final controller =
                                                    TextEditingController(
                                                        text: comment['text']);
                                                final result =
                                                    await showDialog<String>(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: const Text(
                                                        'Edit Komentar'),
                                                    content: TextField(
                                                      controller: controller,
                                                      autofocus: true,
                                                      decoration:
                                                          const InputDecoration(
                                                        labelText: 'Komentar',
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child:
                                                            const Text('Batal'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context,
                                                                controller
                                                                    .text),
                                                        child: const Text(
                                                            'Simpan'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (result != null &&
                                                    result.trim().isNotEmpty) {
                                                  await _editComment(
                                                      index, result.trim());
                                                }
                                              } else if (value == 'delete') {
                                                final confirm =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: const Text(
                                                        'Hapus Komentar'),
                                                    content: const Text(
                                                        'Yakin ingin menghapus komentar ini?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, false),
                                                        child:
                                                            const Text('Batal'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, true),
                                                        child: const Text(
                                                            'Hapus',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .red)),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  await _deleteComment(index);
                                                }
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Edit'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Hapus'),
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'Tulis komentar...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.green[50],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              await _addComment(_commentController.text);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
