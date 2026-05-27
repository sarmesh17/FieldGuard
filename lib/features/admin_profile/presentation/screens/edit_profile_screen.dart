import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/networks/dio_client.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../uploads/image_upload_service.dart';
import '../../data/dto/profile_response.dart';
import '../../data/dto/update_profile_request.dart';
import '../providers/profile_provider.dart';
import '../providers/profile_state.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final ProfileResponse profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _emailController;
  late TextEditingController _companyNameController;
  late TextEditingController _companyEmailController;
  late TextEditingController _companyPhoneController;
  File? _selectedImage;
  String? _uploadedImageKey;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _phoneNumberController = TextEditingController(text: widget.profile.phoneNumber);
    _emailController = TextEditingController(text: widget.profile.email ?? '');
    _companyNameController = TextEditingController(text: widget.profile.company?.companyName ?? '');
    _companyEmailController = TextEditingController(text: widget.profile.company?.email ?? '');
    _companyPhoneController = TextEditingController(text: widget.profile.company?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final dio = DioClient.createDio();
      final uploadService = ImageUploadService(dio);
      
      final uploadResult = await uploadService.upload(
        filePath: _selectedImage!.path,
        category: 'profiles',  // Changed from 'profile' to 'profiles'
        entityId: widget.profile.id,
      );
      
      setState(() {
        _uploadedImageKey = uploadResult.imageKey;
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully'),
            backgroundColor: Color(0xff0E5A3B),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final request = UpdateProfileRequest(
        fullName: _fullNameController.text.trim() != widget.profile.fullName
            ? _fullNameController.text.trim()
            : null,
        phoneNumber: _phoneNumberController.text.trim() != widget.profile.phoneNumber
            ? _phoneNumberController.text.trim()
            : null,
        email: _emailController.text.trim() != (widget.profile.email ?? '')
            ? _emailController.text.trim()
            : null,
        imageKey: _uploadedImageKey,
        companyName: _companyNameController.text.trim() != (widget.profile.company?.companyName ?? '')
            ? _companyNameController.text.trim()
            : null,
        companyEmail: _companyEmailController.text.trim() != (widget.profile.company?.email ?? '')
            ? _companyEmailController.text.trim()
            : null,
        companyPhone: _companyPhoneController.text.trim() != (widget.profile.company?.phoneNumber ?? '')
            ? _companyPhoneController.text.trim().isNotEmpty
                ? _companyPhoneController.text.trim()
                : null
            : null,
      );

      // Check if any field has changed
      if (request.fullName == null &&
          request.phoneNumber == null &&
          request.email == null &&
          request.imageKey == null &&
          request.companyName == null &&
          request.companyEmail == null &&
          request.companyPhone == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes to save'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      ref.read(profileNotifierProvider.notifier).updateProfile(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProfileState>(profileNotifierProvider, (_, next) {
      if (next is ProfileUpdateSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xff0E5A3B),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
      if (next is ProfileUpdateFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    });

    final profileState = ref.watch(profileNotifierProvider);
    final isUpdating = profileState is ProfileUpdating;

    final w = SizeConfig.widthPercent(100);
    final h = SizeConfig.heightPercent(100);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xff0E5A3B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(w * 0.05),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image Section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: w * 0.35,
                        height: w * 0.35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xff0E5A3B),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff0E5A3B).withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _isUploadingImage
                              ? Container(
                                  color: const Color(0xffE5E7EB),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xff0E5A3B),
                                    ),
                                  ),
                                )
                              : _selectedImage != null
                                  ? Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    )
                                  : widget.profile.profileImage != null
                                      ? Image.network(
                                          widget.profile.profileImage!.startsWith('http')
                                              ? widget.profile.profileImage!
                                              : 'https://fieldguard-be.onrender.com/${widget.profile.profileImage}',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: const Color(0xffE5E7EB),
                                              child: Icon(
                                                Icons.person_rounded,
                                                size: w * 0.15,
                                                color: const Color(0xff9CA3AF),
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: const Color(0xffE5E7EB),
                                          child: Icon(
                                            Icons.person_rounded,
                                            size: w * 0.15,
                                            color: const Color(0xff9CA3AF),
                                          ),
                                        ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _isUploadingImage ? null : _pickImage,
                          child: Container(
                            width: w * 0.12,
                            height: w * 0.12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xff0E5A3B),
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xff0E5A3B).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: w * 0.055,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: h * 0.04),

                // Full Name Field
                Text(
                  'Full Name',
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff111827),
                  ),
                ),
                SizedBox(height: h * 0.01),
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xff0E5A3B),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: const BorderSide(
                        color: Color(0xffE5E7EB),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: const BorderSide(
                        color: Color(0xff0E5A3B),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: BorderSide(
                        color: Colors.red.shade400,
                        width: 1,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),

                SizedBox(height: h * 0.025),

                // Email Field
                Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff111827),
                  ),
                ),
                SizedBox(height: h * 0.01),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xff0E5A3B),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: const BorderSide(
                        color: Color(0xffE5E7EB),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: const BorderSide(
                        color: Color(0xff0E5A3B),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: BorderSide(
                        color: Colors.red.shade400,
                        width: 1,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                SizedBox(height: h * 0.025),

                // Phone Number Field
                Text(
                  'Phone Number',
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff111827),
                  ),
                ),
                SizedBox(height: h * 0.01),
                TextFormField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      color: Color(0xff0E5A3B),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: const BorderSide(
                        color: Color(0xffE5E7EB),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: const BorderSide(
                        color: Color(0xff0E5A3B),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: BorderSide(
                        color: Colors.red.shade400,
                        width: 1,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (value.trim().length != 10) {
                      return 'Phone number must be exactly 10 digits';
                    }
                    if (!RegExp(r'^\d+$').hasMatch(value)) {
                      return 'Phone number must contain only digits';
                    }
                    return null;
                  },
                ),

                SizedBox(height: h * 0.03),

                // Company Information Section
                Container(
                  padding: EdgeInsets.all(w * 0.04),
                  decoration: BoxDecoration(
                    color: const Color(0xffF0FAF5),
                    borderRadius: BorderRadius.circular(w * 0.03),
                    border: Border.all(
                      color: const Color(0xff0E5A3B).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.business_rounded,
                            color: const Color(0xff0E5A3B),
                            size: w * 0.05,
                          ),
                          SizedBox(width: w * 0.02),
                          Text(
                            'Company Information',
                            style: TextStyle(
                              fontSize: w * 0.042,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xff0E5A3B),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: h * 0.015),
                      Text(
                        'Update your company details',
                        style: TextStyle(
                          fontSize: w * 0.032,
                          color: const Color(0xff6B7280),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: h * 0.025),

                // Company Name Field
                Text(
                  'Company Name',
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff111827),
                  ),
                ),
                SizedBox(height: h * 0.01),
                TextFormField(
                  controller: _companyNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter company name',
                    prefixIcon: const Icon(
                      Icons.apartment_rounded,
                      color: Color(0xff0E5A3B),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: const BorderSide(
                        color: Color(0xffE5E7EB),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: const BorderSide(
                        color: Color(0xff0E5A3B),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h * 0.025),

                // Company Email Field
                Text(
                  'Company Email',
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff111827),
                  ),
                ),
                SizedBox(height: h * 0.01),
                TextFormField(
                  controller: _companyEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter company email',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xff0E5A3B),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: const BorderSide(
                        color: Color(0xffE5E7EB),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: const BorderSide(
                        color: Color(0xff0E5A3B),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                    }
                    return null;
                  },
                ),

                SizedBox(height: h * 0.025),

                // Company Phone Field
                Text(
                  'Company Phone',
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff111827),
                  ),
                ),
                SizedBox(height: h * 0.01),
                TextFormField(
                  controller: _companyPhoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter company phone',
                    prefixIcon: const Icon(
                      Icons.phone_in_talk_rounded,
                      color: Color(0xff0E5A3B),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: const BorderSide(
                        color: Color(0xffE5E7EB),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: const BorderSide(
                        color: Color(0xff0E5A3B),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (value.trim().length != 10) {
                        return 'Phone number must be exactly 10 digits';
                      }
                      if (!RegExp(r'^\d+$').hasMatch(value)) {
                        return 'Phone number must contain only digits';
                      }
                    }
                    return null;
                  },
                ),

                SizedBox(height: h * 0.04),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isUpdating ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0E5A3B),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: h * 0.018),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(w * 0.03),
                      ),
                      elevation: 2,
                      disabledBackgroundColor: const Color(0xff9CA3AF),
                    ),
                    child: isUpdating
                        ? SizedBox(
                            height: w * 0.05,
                            width: w * 0.05,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: w * 0.042,
                              fontWeight: FontWeight.w700,
                            ),
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
