import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/news_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddNewsScreen extends StatefulWidget {
  const AddNewsScreen({super.key});

  @override
  State<AddNewsScreen> createState() => _AddNewsScreenState();
}

class _AddNewsScreenState extends State<AddNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

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
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = Colors.blue[700]!;
    final Color bgColor = Colors.green[50]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Add News'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: const Icon(Icons.title),
                    filled: true,
                    fillColor: bgColor,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: const Icon(Icons.article),
                    filled: true,
                    fillColor: bgColor,
                  ),
                  maxLines: 8,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter content';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _imageUrlController,
                        decoration: InputDecoration(
                          labelText: 'Image URL (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          prefixIcon: const Icon(Icons.image),
                          filled: true,
                          fillColor: bgColor,
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
                const SizedBox(height: 18),
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
                      lastDate: DateTime.now().add(const Duration(days: 365)),
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
                        final newsProvider =
                            Provider.of<NewsProvider>(context, listen: false);

                        String? imageUrl;
                        if (_pickedImage != null) {
                          // TODO: Upload image to server or cloud storage, get the URL
                          // For now, just show a warning
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
                          'date': _selectedDate.toIso8601String().split('T')[0],
                        };

                        final success = await newsProvider.createNews(newsData);

                        if (success) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('News created successfully')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Failed to create news')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Text('Create News',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
