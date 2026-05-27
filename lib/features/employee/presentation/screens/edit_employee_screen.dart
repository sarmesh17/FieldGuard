import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/core/utils/network_exception_mapper.dart';
import 'package:fieldguard/features/employee/data/datasource/employee_datasource_impl.dart';
import 'package:fieldguard/features/employee/data/dto/update_employee_request.dart';
import 'package:fieldguard/features/uploads/image_upload_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class EditEmployeeScreen extends StatefulWidget {
  final int employeeId;
  final String currentFullName;
  final String currentPhoneNumber;
  final String? currentEmail;
  final bool currentIsActive;
  final String? currentProfileImage;

  const EditEmployeeScreen({
    super.key,
    required this.employeeId,
    required this.currentFullName,
    required this.currentPhoneNumber,
    this.currentEmail,
    required this.currentIsActive,
    this.currentProfileImage,
  });

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
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
        entityId: widget.employeeId,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dio = DioClient.createDio();
      final dataSource = EmployeeDataSourceImpl(dio);

      final request = UpdateEmployeeRequest(
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

      await dataSource.updateEmployee(widget.employeeId.toString(), request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee updated successfully'),
            backgroundColor: Color(0xff0E5A3B),
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
            content: Text('Failed to update employee'),
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
          backgroundColor: const Color(0xFFF8FAF9),
          appBar: AppBar(
            backgroundColor: const Color(0xff0E5A3B),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Edit Employee',
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
                                    : widget.currentProfileImage != null
                                        ? Image.network(
                                            widget.currentProfileImage!.startsWith('http')
                                                ? widget.currentProfileImage!
                                                : 'https://fieldguard-be.onrender.com/${widget.currentProfileImage}',
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: const Color(0xffE5E7EB),
                                                child: Icon(
                                                  Icons.person_rounded,
                                                  size: SizeConfig.scale(50),
                                                  color: const Color(0xff9CA3AF),
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: const Color(0xffE5E7EB),
                                            child: Icon(
                                              Icons.person_rounded,
                                              size: SizeConfig.scale(50),
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
                              width: SizeConfig.scale(40),
                              height: SizeConfig.scale(40),
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
                      border: Border.all(color: const Color(0xffE8E3DD)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: SizeConfig.scale(48),
                          height: SizeConfig.scale(48),
                          decoration: BoxDecoration(
                            color: const Color(0xff0E5A3B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                          ),
                          child: Icon(
                            Icons.toggle_on,
                            color: const Color(0xff0E5A3B),
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
                                  color: const Color(0xff111111),
                                ),
                              ),
                              SizedBox(height: SizeConfig.scale(4)),
                              Text(
                                _isActive ? 'Employee is active' : 'Employee is inactive',
                                style: TextStyle(
                                  fontSize: SizeConfig.scaledFontSize(13),
                                  color: const Color(0xff667085),
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
                          activeColor: const Color(0xff0E5A3B),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.heightPercent(4)),

                  // Update Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateEmployee,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0E5A3B),
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
                            'Update Employee',
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
        prefixIcon: Icon(icon, color: const Color(0xff0E5A3B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
          borderSide: const BorderSide(color: Color(0xffE8E3DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
          borderSide: const BorderSide(color: Color(0xffE8E3DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
          borderSide: const BorderSide(color: Color(0xff0E5A3B), width: 2),
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
