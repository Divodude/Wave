import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage>
    with SingleTickerProviderStateMixin {
  File? _selectedImage;
  File? _selectedAudioFile;
  String? _audioFileName;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  late AnimationController _animationController;
  late Animation<double> _animation;
  String base_url = "https://api-1039005314066.europe-west1.run.app/";
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      setState(() {
        _selectedAudioFile = File(result.files.single.path!);
        _audioFileName = result.files.single.name;
      });
    }
  }

  Future<void> _uploadContent() async {
    // Validate inputs
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a title');
      return;
    }

    if (_artistController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter an artist name');
      return;
    }

    if (_selectedAudioFile == null) {
      _showErrorSnackBar('Please select an audio file');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      var url = Uri.parse(base_url);
      var request = http.MultipartRequest('POST', url);

      // Add form fields
      request.fields['name'] = _titleController.text.trim();
      request.fields['artist'] = _artistController.text.trim();

      // Add audio file (required)
      request.files.add(
        await http.MultipartFile.fromPath('song', _selectedAudioFile!.path)
      );

      // Add cover image if selected
      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('song_cover', _selectedImage!.path)
        );
      }

      print('Sending request to: $base_url');
      print('Fields: ${request.fields}');
      print('Files: ${request.files.map((f) => '${f.field}: ${f.filename}').join(', ')}');

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('Response status: ${response.statusCode}');
      print('Response body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessSnackBar('Upload successful!');
        _clearForm();
      } else {
        _showErrorSnackBar('Upload failed! Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Upload error: $e');
      _showErrorSnackBar('Upload failed: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearForm() {
    setState(() {
      _selectedImage = null;
      _selectedAudioFile = null;
      _audioFileName = null;
      _titleController.clear();
      _artistController.clear();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    _animation.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                    _animation.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF0f3460),
                    const Color(0xFF1a1a2e),
                    _animation.value,
                  )!,
                ],
                stops: [
                  0.0 + (_animation.value * 0.1),
                  0.5 + (_animation.value * 0.2),
                  1.0,
                ],
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                title: const Text(
                  'Upload Page',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                backgroundColor: const Color.fromARGB(255, 32, 32, 32),
              ),
              body: Column(
                children: [
                  const SizedBox(height: 80),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.transparent,
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Card(
                          elevation: 0,
                          color: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  // Image Upload Container
                                  GestureDetector(
                                    onTap: _isUploading ? null : _pickImage,
                                    child: Container(
                                      width: double.infinity,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 2,
                                          style: BorderStyle.solid,
                                        ),
                                        image: _selectedImage != null
                                            ? DecorationImage(
                                                image: FileImage(_selectedImage!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: _selectedImage == null
                                          ? Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add_photo_alternate_outlined,
                                                  size: 50,
                                                  color:
                                                      Colors.white.withOpacity(0.7),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  'Tap to select cover image (optional)',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : null,
                                    ),
                                  ),

                                  const SizedBox(height: 40),

                                  // Title TextField
                                  TextField(
                                    controller: _titleController,
                                    enabled: !_isUploading,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      labelText: "Title *",
                                      labelStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.05),
                                    ),
                                  ),

                                  const SizedBox(height: 30),

                                  // Artist Name TextField
                                  TextField(
                                    controller: _artistController,
                                    enabled: !_isUploading,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      labelText: "Artist Name *",
                                      labelStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.05),
                                    ),
                                  ),

                                  const SizedBox(height: 30),

                                  // Audio Upload Field
                                  GestureDetector(
                                    onTap: _isUploading ? null : _pickAudioFile,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _selectedAudioFile != null
                                                ? Icons.audiotrack
                                                : Icons.upload_file,
                                            color: Colors.white.withOpacity(0.8),
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _audioFileName ??
                                                  'Tap to select audio file *',
                                              style: TextStyle(
                                                color: _selectedAudioFile != null
                                                    ? Colors.white
                                                    : Colors.white
                                                        .withOpacity(0.8),
                                                fontSize: 16,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (_selectedAudioFile != null)
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.green.withOpacity(0.8),
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 40),

                                  // Upload Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isUploading ? null : _uploadContent,
                                      icon: _isUploading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.cloud_upload,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                      label: Text(
                                        _isUploading ? 'Uploading...' : 'Upload',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        elevation: 10,
                                        shadowColor:
                                            const Color.fromARGB(255, 21, 21, 21)
                                                .withOpacity(0.5),
                                        backgroundColor: _isUploading
                                            ? const Color.fromARGB(255, 60, 60, 60)
                                            : const Color.fromARGB(255, 35, 36, 36),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Required fields note
                                  Text(
                                    '* Required fields',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).asGlass(
                          tintColor: Colors.white.withOpacity(0.1),
                          blurX: 10,
                          blurY: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}