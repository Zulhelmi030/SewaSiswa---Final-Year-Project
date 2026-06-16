import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/widgets/user_avatar.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _client = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _profilePictureImagePicker = ImagePicker();

  bool _isInitialLoading = true;
  bool _isSaving = false;

  String _email = '';
  String _displayName = '';
  String? _avatarUrl;
  String? _nameError;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserData() async {
    final User? user = _client.auth.currentUser;
    if (user != null) {
      try {
        final userData = await _client
            .from('users')
            .select()
            .eq('id', user.id)
            .single();

        setState(() {
          _email = user.email ?? '';
          _displayName = user.userMetadata?['full_name'] ?? '';
          _nameController.text = _displayName;
          _avatarUrl = userData['avatar_url'] as String?;
          _isInitialLoading = false;
        });
      } catch (e) {
        debugPrint('Error fetching user data: $e');
        setState(() => _isInitialLoading = false);
      }
    } else {
      setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _pickProfilePicture() async {
    try {
      final XFile? image = await _profilePictureImagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 80,
      );
      if (image == null) return;

      // Just hold the image locally; don't upload it yet!
      setState(() {
        _selectedImage = image;
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _saveChanges() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      setState(() {
        _nameError = 'Name cannot be empty';
      });
      return;
    }

    setState(() {
      _nameError = null;
      _isSaving = true;
    });

    final user = _client.auth.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      String? newAvatarUrl = _avatarUrl;

      // 1. Upload to bucket ONLY if a new image was picked
      if (_selectedImage != null) {
        // Cleanup old avatar if it exists
        if (_avatarUrl != null && _avatarUrl!.contains('avatars/')) {
          try {
            final uri = Uri.parse(_avatarUrl!);
            final pathSegments = uri.pathSegments;
            final avatarsIndex = pathSegments.indexOf('avatars');
            if (avatarsIndex != -1 && avatarsIndex + 1 < pathSegments.length) {
              final oldFileName = pathSegments
                  .sublist(avatarsIndex + 1)
                  .join('/');
              await _client.storage.from('avatars').remove([oldFileName]);
            }
          } catch (e) {
            debugPrint('Failed to clean up old avatar: $e');
          }
        }

        // Upload the newly picked image
        final fileName = '${user.id}-${DateTime.now().millisecondsSinceEpoch}';
        final bytes = await _selectedImage!.readAsBytes();
        final contentType = _selectedImage!.mimeType ?? 'image/jpeg';

        await _client.storage
            .from('avatars')
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(contentType: contentType),
            );

        newAvatarUrl = _client.storage.from('avatars').getPublicUrl(fileName);
      }

      // 2. Update the public.users table
      await _client
          .from('users')
          .update({'full_name': newName, 'avatar_url': ?newAvatarUrl})
          .eq('id', user.id);

      // 3. Update auth metadata
      await _client.auth.updateUser(
        UserAttributes(data: {'full_name': newName}),
      );

      setState(() {
        if (newAvatarUrl != null) _avatarUrl = newAvatarUrl;
        _selectedImage = null; // Clear local state since it's saved
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong while saving your changes.'),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
        backgroundColor: context.appColors.background,
        elevation: 0,
      ),
      backgroundColor: context.appColors.background,
      body: _isInitialLoading
          ? Center(
              child: CircularProgressIndicator(
                color: context.appColors.primary,
              ),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Minimalist Avatar Section
          Center(
            child: GestureDetector(
              onTap: _isSaving ? null : _pickProfilePicture,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Show the local image if one was picked, otherwise show the network avatar
                  if (_selectedImage != null)
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: FileImage(File(_selectedImage!.path)),
                    )
                  else
                    UserAvatar(imageUrl: _avatarUrl, radius: 50),

                  // Overlay spinner over the avatar while saving a newly picked image
                  if (_isSaving && _selectedImage != null)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),

                  if (!_isSaving)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.appColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.appColors.background,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Legal Name Edit
          Text('Legal name', style: context.appTextStyles.labelMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            enabled: !_isSaving,
            decoration: InputDecoration(
              hintText: 'First name on your ID',
              errorText: _nameError,
              border: const UnderlineInputBorder(),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: context.appColors.primary,
                  width: 2,
                ),
              ),
            ),
            style: context.appTextStyles.bodyLarge,
          ),

          const SizedBox(height: 32),

          // Read-only Email
          Text('Email address', style: context.appTextStyles.labelMedium),
          const SizedBox(height: 8),
          Text(
            _email,
            style: context.appTextStyles.bodyLarge.copyWith(
              color: context.appColors.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is the email address you use to sign in. It’s not visible to others.',
            style: context.appTextStyles.bodySmall.copyWith(
              color: context.appColors.outline,
            ),
          ),

          const SizedBox(height: 48),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appColors.primary,
                disabledBackgroundColor: context.appColors.primary.withValues(
                  alpha: 0.5,
                ),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
