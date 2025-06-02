import 'package:flutter/material.dart';
import '../../models/news.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserAndComments();
  }

  Future<void> _loadUserAndComments() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _currentUserId = authProvider.user?.id;
      _currentUsername = authProvider.user?.username;
    });
    await _loadComments();
  }

  Future<void> _loadComments() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'comments_${widget.news.id}';
    final commentsString = prefs.getString(key);
    if (commentsString != null) {
      final List<dynamic> decoded = jsonDecode(commentsString);
      setState(() {
        _comments = decoded.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _saveComments() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'comments_${widget.news.id}';
    await prefs.setString(key, jsonEncode(_comments));
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('News Detail'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.news.imageUrl != null)
              Image.network(
                widget.news.imageUrl!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 100),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.news.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.news.date.day}/${widget.news.date.month}/${widget.news.date.year}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.news.content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const Text(
                    'Komentar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _comments.isEmpty
                      ? const Text('Belum ada komentar.')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            final isOwner = comment['userId'] == userId;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(comment['text']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Oleh: ${comment['username'] ?? 'User'}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold),
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
                                        onSelected: (value) async {
                                          if (value == 'edit') {
                                            final controller =
                                                TextEditingController(
                                                    text: comment['text']);
                                            final result =
                                                await showDialog<String>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title:
                                                    const Text('Edit Komentar'),
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
                                                        Navigator.pop(context),
                                                    child: const Text('Batal'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context,
                                                            controller.text),
                                                    child: const Text('Simpan'),
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
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                    'Hapus Komentar'),
                                                content: const Text(
                                                    'Yakin ingin menghapus komentar ini?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: const Text('Batal'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    child: const Text('Hapus',
                                                        style: TextStyle(
                                                            color: Colors.red)),
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
                          decoration: const InputDecoration(
                            hintText: 'Tulis komentar...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await _addComment(_commentController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        child: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
