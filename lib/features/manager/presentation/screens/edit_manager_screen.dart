import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/core/utils/network_exception_mapper.dart';
import 'package:fieldguard/features/manager/data/datasource/manager_datasource_impl.dart';
import 'package:fieldguard/features/manager/data/dto/update_manager_request.dart';
import 'package:fieldguard/features/uploads/image_upload_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fieldguard/core/theme/app_colors.dart';
import 'package:fieldguard/core/constant/api_constant.dart';

class EditManagerScreen extends StatefulWidget {
  final int managerId;
  final String currentFullName;
  final String currentPhoneNumber;
  final String? currentEmail;
  final bool currentIsActive;
  final String? currentProfileImage;

  const EditManagerScreen({
    super.key,
    required this.managerId,
    required this.currentFullName,
    required this.currentPhoneNumber,
    this.currentEmail,
    required this.currentIsActive,
    this.currentProfileImage,
  });

  @override
  State<EditManagerScreen> createState() => _EditManagerScreenState();
}

class _EditManagerScreenState extends State<EditManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late bool _isActive;
  bool _isLoading = false;

  // Server-side phone error (400 invalid format / 409 already in use), shown
  // inline on the phone field via its validator; cleared on edit.
  String? _phoneServerError;
  File? _selectedImage;
  String? _uploadedImageKey;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.currentFullName);
    _phoneController = TextEditingController(text: widget.currentPhoneNumber);
    _emailController = TextEditingController(text: widget.currentEmail ?? '');
    _isActive = widget.currentIsActive;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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
        category: 'profiles',
        entityId: widget.managerId,
      );
      
      setState(() {
        _uploadedImageKey = uploadResult.imageKey;
        _isUploadingImage = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully'),
            backgroundColor: AppColors.blue,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateManager() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dio = DioClient.createDio();
      final dataSource = ManagerDataSourceImpl(dio);

      final request = UpdateManagerRequest(
        fullName: _fullNameController.text.trim().isEmpty 
            ? null 
            : _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty 
            ? null 
            : _emailController.text.trim(),
        isActive: _isActive,
        imageKey: _uploadedImageKey,
      );

      await dataSource.updateManager(widget.managerId.toString(), request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manager updated successfully'),
            backgroundColor: AppColors.blue,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } on DioException catch (e) {
      if (mounted) _handlePhoneAwareError(e);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update manager'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Surfaces a phone clash/format error (400 or 409) inline on the phone
  /// field; anything else goes to a snackbar. The 409 message is shown
  /// verbatim — it already names which record holds the number.
  void _handlePhoneAwareError(DioException e) {
    final mapped = NetworkExceptionMapper.map(e);
    final phoneError = mapped is ValidationException
        ? mapped.errorFor('phoneNumber')
        : null;
    final isPhoneConflict = e.response?.statusCode == 409 &&
        mapped.message.toLowerCase().contains('phone');

    if (phoneError != null || isPhoneConflict) {
      setState(() => _phoneServerError = phoneError ?? mapped.message);
      _formKey.currentState?.validate();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mapped.message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.blue,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Edit Manager',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(SizeConfig.scale(16)),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: SizeConfig.heightPercent(2)),
                  
                  // Profile Image Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: SizeConfig.scale(120),
                          height: SizeConfig.scale(120),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.blue,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blue.withValues(alpha: 0.2),
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
                                        color: AppColors.blue,
                                      ),
                                    ),
                                  )
                                : _selectedImage != null
                                    ? Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      )
                                    : widget.currentProfileImage != null
                                        ? Image.network(
                                            ApiConstant.imageUrl(widget.currentProfileImage!),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: AppColors.grey4,
                                                child: Icon(
                                                  Icons.person_rounded,
                                                  size: SizeConfig.scale(50),
                                                  color: AppColors.grey2,
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: AppColors.grey4,
                                            child: Icon(
                                              Icons.person_rounded,
                                              size: SizeConfig.scale(50),
                                              color: AppColors.grey2,
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
                              width: SizeConfig.scale(40),
                              height: SizeConfig.scale(40),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.blue,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.blue.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: SizeConfig.scale(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.heightPercent(3)),
                  
                  // Full Name Field
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter full name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: SizeConfig.scale(16)),

                  // Phone Number Field
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: (_) {
                      if (_phoneServerError != null) {
                        setState(() => _phoneServerError = null);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter phone number';
                      }
                      if (value.trim().length != 10) {
                        return 'Phone number must be exactly 10 digits';
                      }
                      return _phoneServerError;
                    },
                  ),
                  SizedBox(height: SizeConfig.scale(16)),

                  // Email Field (Optional)
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email (Optional)',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid email';
                        }
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: SizeConfig.scale(24)),

                  // Active Status Toggle
                  Container(
                    padding: EdgeInsets.all(SizeConfig.scale(16)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                      border: Border.all(color: AppColors.grey3),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: SizeConfig.scale(48),
                          height: SizeConfig.scale(48),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                          ),
                          child: Icon(
                            Icons.toggle_on,
                            color: AppColors.blue,
                            size: SizeConfig.scale(24),
                          ),
                        ),
                        SizedBox(width: SizeConfig.scale(16)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Status',
                                style: TextStyle(
                                  fontSize: SizeConfig.scaledFontSize(16),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                              SizedBox(height: SizeConfig.scale(4)),
                              Text(
                                _isActive ? 'Manager is active' : 'Manager is inactive',
                                style: TextStyle(
                                  fontSize: SizeConfig.scaledFontSize(13),
                                  color: AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isActive,
                          onChanged: (value) {
                            setState(() => _isActive = value);
                          },
                          activeColor: AppColors.blue,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.heightPercent(4)),

                  // Update Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateManager,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.scale(16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: SizeConfig.scale(20),
                            width: SizeConfig.scale(20),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Update Manager',
                            style: TextStyle(
                              fontSize: SizeConfig.scaledFontSize(16),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
          borderSide: const BorderSide(color: AppColors.grey3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
          borderSide: const BorderSide(color: AppColors.grey3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
