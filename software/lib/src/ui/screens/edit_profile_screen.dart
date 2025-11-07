import 'dart:io' show File;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_image_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/chatbot/chatbot_wrapper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Image picking & preview
  final _picker = ImagePicker();
  XFile? _pickedFile;         // original file (for upload)
  File? _imageFile;           // preview (mobile/desktop)
  Uint8List? _webImageBytes;  // preview (web)

  // Current stored photo (Firestore)
  String? _currentPhotoUrl;
  String? _currentPhotoPath;

  bool _isLoading = false;

  final user = FirebaseAuth.instance.currentUser;
  final _imgService = SupabaseImageService(bucket: 'avatars'); // bucket name

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final u = user;
    if (u == null) return;

    _nameController.text = u.displayName ?? '';

    try {
      final snap =
      await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
      final data = snap.data();
      if (!mounted) return;
      if (data != null) {
        _bioController.text = (data['bio'] ?? '') as String;
        _phoneController.text = (data['phone'] ?? data['phoneNumber'] ?? '') as String;
        _currentPhotoUrl = (data['profilePicUrl'] ?? '') as String;
        _currentPhotoPath = (data['profilePicPath'] ?? '') as String?;
        setState(() {});
      }
    } catch (_) {
      // Ignore non-blocking read errors
    }
  }

  Future<void> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    _pickedFile = picked;

    if (kIsWeb) {
      _webImageBytes = await picked.readAsBytes();
      _imageFile = null;
    } else {
      _imageFile = File(picked.path);
      _webImageBytes = null;
    }
    if (mounted) setState(() {});
  }

  ImageProvider<Object>? _avatarProvider() {
    if (_webImageBytes != null) return MemoryImage(_webImageBytes!);
    if (_imageFile != null) return FileImage(_imageFile!);
    if ((_currentPhotoUrl ?? '').isNotEmpty) {
      return NetworkImage(_currentPhotoUrl!);
    }
    return null;
  }

  Future<void> updateProfile() async {
    final u = user;
    if (u == null) return;

    setState(() => _isLoading = true);

    try {
      final uid = u.uid;
      String? newUrl;
      String? newPath;

      // 1) Upload to Supabase if a new image is picked
      if (_pickedFile != null) {
        try {
          final res = await _imgService.uploadProfileImage(
            uid: uid,
            file: _pickedFile!,
          );
          newUrl = res.publicUrl;
          newPath = res.path;
        } on StorageException catch (se) {
          // Show message but continue with name/bio/password updates
          if (mounted) {
            final msg = se.message ?? 'Storage error';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Supabase upload failed: $msg\n'
                      'Check bucket="avatars", policies (INSERT/UPDATE), and your Project URL / anon key.',
                ),
                duration: const Duration(seconds: 6),
              ),
            );
          }
        }
      }

      // 2) Update Firestore
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      await userRef.update({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
        if (newUrl != null) 'profilePicUrl': newUrl,
        if (newPath != null) 'profilePicPath': newPath,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2b) Update publicProfiles (public-facing minimal profile) so public views work
      try {
        final publicRef = FirebaseFirestore.instance.collection('publicProfiles').doc(uid);
        await publicRef.set({
          'name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
          'email': u.email ?? '',  // Include email for contact button
          'phone': _phoneController.text.trim(),  // Include phone for contact button
          if (newUrl != null) 'photoUrl': newUrl,
          if (newUrl != null) 'profilePicUrl': newUrl,  // Support both field names
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('✅ Updated publicProfiles/${uid} with new profile data');
      } catch (e) {
        debugPrint('⚠️ Could not update publicProfiles/${uid}: $e');
        // best-effort: do not block the user if public profile write fails
      }

      // Reflect locally for UI
      if (newUrl != null) _currentPhotoUrl = newUrl;
      if (newPath != null) _currentPhotoPath = newPath;

      // 3) Update displayName
      final newName = _nameController.text.trim();
      if (newName.isNotEmpty) {
        await u.updateDisplayName(newName);
      }

      // 4) Optional: change password
      final oldPw = _oldPasswordController.text;
      final newPw = _newPasswordController.text;
      final confirmPw = _confirmPasswordController.text;

      if (oldPw.isNotEmpty || newPw.isNotEmpty || confirmPw.isNotEmpty) {
        if (newPw != confirmPw) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                Text('New password and confirm password do not match.'),
              ),
            );
          }
        } else {
          try {
            final cred = EmailAuthProvider.credential(
              email: u.email!,
              password: oldPw,
            );
            await u.reauthenticateWithCredential(cred);
            await u.updatePassword(newPw);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password updated successfully!')),
              );
            }
          } catch (pe) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Password update failed: $pe')),
              );
            }
          }
        }
      }

      // 5) If we uploaded a new photo, best-effort delete the old one
      if (newPath != null && _currentPhotoPath != null && _currentPhotoPath != newPath) {
        await _imgService.deleteIfExists(_currentPhotoPath);
      }
      _currentPhotoPath = newPath ?? _currentPhotoPath;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }

      // Clear local pick so avatar uses network image
      _pickedFile = null;
      _imageFile = null;
      _webImageBytes = null;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = _avatarProvider();

    return ChatbotWrapper(
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? const Icon(Icons.add_a_photo, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                hintText: 'Enter your contact number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Change Password',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _oldPasswordController,
              decoration:
              const InputDecoration(labelText: 'Old Password'),
              obscureText: true,
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _newPasswordController,
              decoration:
              const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _confirmPasswordController,
              decoration:
              const InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: updateProfile,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      ),
    );
  }
}
