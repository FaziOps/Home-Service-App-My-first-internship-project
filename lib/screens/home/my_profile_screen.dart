import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

class MyProfileScreen extends StatefulWidget {
  final String uid;
  final String initialName;
  final String initialEmail;
  final String initialAbout;
  final String initialProfileImageUrl;

  const MyProfileScreen({
    super.key,
    required this.uid,
    required this.initialName,
    required this.initialEmail,
    required this.initialAbout,
    required this.initialProfileImageUrl,
  });

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _aboutController;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _aboutController = TextEditingController(text: widget.initialAbout);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      String imageUrl = widget.initialProfileImageUrl;

      if (_imageFile != null) {
        // Upload profile image to Firebase Storage with a unique filename to prevent caching issues
        final String newFileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance
            .ref()
            .child('users')
            .child(widget.uid)
            .child(newFileName);
        
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();

        // Try to delete the old profile image from Storage to clean up space
        if (widget.initialProfileImageUrl.isNotEmpty &&
            widget.initialProfileImageUrl.contains('firebasestorage')) {
          try {
            final oldRef = FirebaseStorage.instance.refFromURL(widget.initialProfileImageUrl);
            await oldRef.delete();
          } catch (e) {
            // Log/ignore deletion failure (e.g. if the file did not exist or permissions prevent deleting)
            debugPrint('Failed to delete old profile image: $e');
          }
        }
      }

      // Update Firestore user document
      await FirestoreService.instance.updateUserProfile(
        widget.uid,
        fullName: _nameController.text,
        email: _emailController.text,
        about: _aboutController.text,
        profileImageUrl: imageUrl,
      );

      // Also update FirebaseAuth user profile if currently signed in user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == widget.uid) {
        await currentUser.updateDisplayName(_nameController.text.trim());
        await currentUser.updatePhotoURL(imageUrl);
        await currentUser.reload();
      }

      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider avatarImage;
    if (_imageFile != null) {
      avatarImage = FileImage(_imageFile!);
    } else if (widget.initialProfileImageUrl.isNotEmpty) {
      avatarImage = NetworkImage(widget.initialProfileImageUrl);
    } else {
      avatarImage = const AssetImage('assets/images/john_smith_profile.png');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.black),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Picture centered
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 4,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 65,
                                backgroundImage: avatarImage,
                                backgroundColor: const Color(0xFFF6F6F6),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 4,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  height: 36,
                                  width: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3F8CFF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Full Name field
                      const Text(
                        'Full Name',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your name',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Name is required'
                                : null,
                      ),
                      const SizedBox(height: 20),

                      // Email field
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Enter your email',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // About field
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _aboutController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Tell us about yourself...',
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Save button
                      ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
