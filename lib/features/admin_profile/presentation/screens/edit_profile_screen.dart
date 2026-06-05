import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/networks/dio_client.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../auth/login/presentation/providers/login_provider.dart';
import '../../../auth/login/presentation/providers/login_state.dart';
import '../../../uploads/image_upload_service.dart';
import '../../data/dto/profile_response.dart';
import '../../data/dto/update_profile_request.dart';
import '../providers/profile_provider.dart';
import '../providers/profile_state.dart';
import 'package:fieldguard/core/theme/app_colors.dart';
import 'package:fieldguard/core/constant/api_constant.dart';

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

  // Server-side phone errors (from a 400 `errors[]`), shown inline under the
  // matching field; cleared when the user edits that field or re-submits.
  String? _phoneError;
  String? _companyPhoneError;

  static const String _countryCode = '+977';

  /// Phones are stored with the +977 country code, but the UI edits only the
  /// 10-digit local number — strip it for display, re-attach it on save.
  String _localPhone(String? full) {
    final p = (full ?? '').trim();
    return p.startsWith(_countryCode) ? p.substring(_countryCode.length) : p;
  }

  String? _fullPhone(String local) {
    final d = local.trim();
    return d.isEmpty ? null : '$_countryCode$d';
  }

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _phoneNumberController =
        TextEditingController(text: _localPhone(widget.profile.phoneNumber));
    _emailController = TextEditingController(text: widget.profile.email ?? '');
    _companyNameController = TextEditingController(
        text: widget.profile.company?.companyName ?? '');
    _companyEmailController =
        TextEditingController(text: widget.profile.company?.email ?? '');
    _companyPhoneController = TextEditingController(
        text: _localPhone(widget.profile.company?.phoneNumber));
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

  // Returns true if the logged-in user is a MANAGER.
  bool get _isManager {
    final loginState = ref.read(loginNotifierProvider);
    if (loginState is LoginSuccess) {
      return loginState.response.user.role.toUpperCase() == 'MANAGER';
    }
    return false;
  }

  Future<void> _pickImage() async {
    // Use image_picker (not file_picker): it preserves the photo's EXIF
    // orientation. file_picker strips EXIF while caching the content-URI,
    // leaving the backend with no orientation signal to bake — so photos
    // uploaded sideways. With EXIF intact, the server's sharp().rotate()
    // normalises the image to upright on confirm.
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: true,
    );

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
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
        category: 'profiles',
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
            backgroundColor: AppColors.green,
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
    if (!_formKey.currentState!.validate()) return;

    // Clear previous server-side field errors before re-submitting.
    setState(() {
      _phoneError = null;
      _companyPhoneError = null;
    });

    final UpdateProfileRequest request;

    if (_isManager) {
      // Manager API only accepts fullName, email, imageKey.
      final newName = _fullNameController.text.trim();
      final newEmail = _emailController.text.trim();

      request = UpdateProfileRequest(
        fullName: newName != widget.profile.fullName ? newName : null,
        email: newEmail != (widget.profile.email ?? '') ? newEmail : null,
        imageKey: _uploadedImageKey,
      );

      if (request.fullName == null &&
          request.email == null &&
          request.imageKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes to save'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } else {
      // Admin can update personal + company fields.
      request = UpdateProfileRequest(
        fullName: _fullNameController.text.trim() != widget.profile.fullName
            ? _fullNameController.text.trim()
            : null,
        phoneNumber:
            _fullPhone(_phoneNumberController.text) != widget.profile.phoneNumber
                ? _fullPhone(_phoneNumberController.text)
                : null,
        email: _emailController.text.trim() != (widget.profile.email ?? '')
            ? _emailController.text.trim()
            : null,
        imageKey: _uploadedImageKey,
        companyName: _companyNameController.text.trim() !=
                (widget.profile.company?.companyName ?? '')
            ? _companyNameController.text.trim()
            : null,
        companyEmail: _companyEmailController.text.trim() !=
                (widget.profile.company?.email ?? '')
            ? _companyEmailController.text.trim()
            : null,
        companyPhone: _fullPhone(_companyPhoneController.text) !=
                widget.profile.company?.phoneNumber
            ? _fullPhone(_companyPhoneController.text)
            : null,
      );

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
    }

    ref.read(profileNotifierProvider.notifier).updateProfile(request);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProfileState>(profileNotifierProvider, (_, next) {
      if (next is ProfileUpdateSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context, true);
      }
      if (next is ProfileUpdateFailure) {
        // Bind per-field server errors (e.g. a 400 on phoneNumber/companyPhone)
        // inline under the matching input; show anything unbound (e.g. a 409
        // phone conflict) as a snackbar.
        String? phoneErr;
        String? companyPhoneErr;
        for (final e in next.fieldErrors) {
          if (e.field == 'phoneNumber') phoneErr = e.message;
          if (e.field == 'companyPhone') companyPhoneErr = e.message;
        }
        setState(() {
          _phoneError = phoneErr;
          _companyPhoneError = companyPhoneErr;
        });
        if (phoneErr == null && companyPhoneErr == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    });

    final profileState = ref.watch(profileNotifierProvider);
    final isUpdating = profileState is ProfileUpdating;
    final isManager = _isManager;

    final w = SizeConfig.widthPercent(100);
    final h = SizeConfig.heightPercent(100);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.green,
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
                // ── Profile Image ──────────────────────────────────────────
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: w * 0.35,
                        height: w * 0.35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.green,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.green.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _isUploadingImage
                              ? Container(
                                  color: AppColors.grey4,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.green,
                                    ),
                                  ),
                                )
                              : _selectedImage != null
                                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                  : widget.profile.profileImage != null
                                      ? Image.network(
                                          ApiConstant.imageUrl(widget.profile.profileImage!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              _avatarPlaceholder(w),
                                        )
                                      : _avatarPlaceholder(w),
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
                              color: AppColors.green,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.green.withValues(alpha: 0.4),
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

                // ── Full Name ──────────────────────────────────────────────
                _fieldLabel('Full Name', w),
                SizedBox(height: h * 0.01),
                _textField(
                  controller: _fullNameController,
                  hint: 'Enter your full name',
                  icon: Icons.person_outline_rounded,
                  w: w,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),

                SizedBox(height: h * 0.025),

                // ── Email ──────────────────────────────────────────────────
                _fieldLabel('Email Address', w),
                SizedBox(height: h * 0.01),
                _textField(
                  controller: _emailController,
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  w: w,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return null; // Email is optional.
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(v)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                // ── Phone (ADMIN only) ─────────────────────────────────────
                if (!isManager) ...[
                  SizedBox(height: h * 0.025),
                  _fieldLabel('Phone Number', w),
                  SizedBox(height: h * 0.01),
                  _textField(
                    controller: _phoneNumberController,
                    hint: 'Enter phone number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    w: w,
                    errorText: _phoneError,
                    onChanged: (_) {
                      if (_phoneError != null) {
                        setState(() => _phoneError = null);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter phone number';
                      }
                      if (value.trim().length != 10) {
                        return 'Phone number must be exactly 10 digits';
                      }
                      return null;
                    },
                  ),
                ],

                // ── Company Section (ADMIN only) ───────────────────────────
                if (!isManager) ...[
                  SizedBox(height: h * 0.03),

                  // Section header
                  Container(
                    padding: EdgeInsets.all(w * 0.04),
                    decoration: BoxDecoration(
                      color: AppColors.green6,
                      borderRadius: BorderRadius.circular(w * 0.03),
                      border: Border.all(
                        color: AppColors.green.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.business_rounded,
                          color: AppColors.green,
                          size: w * 0.05,
                        ),
                        SizedBox(width: w * 0.02),
                        Text(
                          'Company Information',
                          style: TextStyle(
                            fontSize: w * 0.042,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.025),

                  _fieldLabel('Company Name', w),
                  SizedBox(height: h * 0.01),
                  _textField(
                    controller: _companyNameController,
                    hint: 'Enter company name',
                    icon: Icons.apartment_rounded,
                    w: w,
                  ),

                  SizedBox(height: h * 0.025),

                  _fieldLabel('Company Email', w),
                  SizedBox(height: h * 0.01),
                  _textField(
                    controller: _companyEmailController,
                    hint: 'Enter company email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    w: w,
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

                  _fieldLabel('Company Phone', w),
                  SizedBox(height: h * 0.01),
                  _textField(
                    controller: _companyPhoneController,
                    hint: 'Enter company phone',
                    icon: Icons.phone_in_talk_rounded,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    w: w,
                    errorText: _companyPhoneError,
                    onChanged: (_) {
                      if (_companyPhoneError != null) {
                        setState(() => _companyPhoneError = null);
                      }
                    },
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        if (value.trim().length != 10) {
                          return 'Phone number must be exactly 10 digits';
                        }
                      }
                      return null;
                    },
                  ),
                ],

                SizedBox(height: h * 0.04),

                // ── Save Button ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isUpdating ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: h * 0.018),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(w * 0.03),
                      ),
                      elevation: 2,
                      disabledBackgroundColor: AppColors.grey2,
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _avatarPlaceholder(double w) => Container(
        color: AppColors.grey4,
        child: Icon(
          Icons.person_rounded,
          size: w * 0.15,
          color: AppColors.grey2,
        ),
      );

  Widget _fieldLabel(String label, double w) => Text(
        label,
        style: TextStyle(
          fontSize: w * 0.04,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required double w,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? errorText,
    void Function(String)? onChanged,
  }) {
    final radius = BorderRadius.circular(w * 0.03);
    const enabledColor = AppColors.grey4;
    const focusColor = AppColors.green;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        prefixIcon: Icon(icon, color: focusColor),
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: enabledColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: focusColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
      ),
    );
  }
}
