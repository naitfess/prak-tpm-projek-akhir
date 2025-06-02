import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/news_provider.dart';
import '../../models/news.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditNewsScreen extends StatefulWidget {
  final News news;
  const EditNewsScreen({super.key, required this.news});

  @override
  State<EditNewsScreen> createState() => _EditNewsScreenState();
}

class _EditNewsScreenState extends State<EditNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _imageUrlController;
  late DateTime _selectedDate;

  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImageFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
        _imageUrlController.clear();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.news.title);
    _contentController = TextEditingController(text: widget.news.content);
    _imageUrlController =
        TextEditingController(text: widget.news.imageUrl ?? '');
    _selectedDate = widget.news.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text('Edit News'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 6,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(Icons.sports_soccer,
                        size: 60, color: Colors.green),
                    const SizedBox(height: 16),
                    const Text(
                      'Edit Berita',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.article),
                      ),
                      maxLines: 8,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter content';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _imageUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Image URL (Optional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.image),
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty && _pickedImage != null) {
                                setState(() {
                                  _pickedImage = null;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.photo_library),
                          tooltip: 'Pick from gallery',
                          onPressed: _pickImageFromGallery,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_pickedImage != null)
                      Column(
                        children: [
                          Image.file(_pickedImage!, height: 120),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _pickedImage = null;
                              });
                            },
                            child: const Text('Remove selected image'),
                          ),
                        ],
                      )
                    else if (_imageUrlController.text.isNotEmpty)
                      Image.network(_imageUrlController.text,
                          height: 120,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.broken_image)),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Date'),
                      subtitle: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final newsProvider = Provider.of<NewsProvider>(
                                context,
                                listen: false);

                            String? imageUrl;
                            if (_pickedImage != null) {
                              // TODO: Upload image to server or cloud storage, get the URL
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Image picked from gallery, but upload logic is not implemented. Please use URL for now.')),
                              );
                              return;
                            } else if (_imageUrlController.text.isNotEmpty) {
                              imageUrl = _imageUrlController.text;
                            }

                            final newsData = {
                              'title': _titleController.text,
                              'content': _contentController.text,
                              'imageUrl': imageUrl,
                              'date':
                                  _selectedDate.toIso8601String().split('T')[0],
                            };

                            final success = await newsProvider.updateNews(
                                widget.news.id, newsData);

                            if (success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('News updated successfully')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Failed to update news')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Update News',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
