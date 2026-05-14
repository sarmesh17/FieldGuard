import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/features/manager/data/datasource/manager_datasource_impl.dart';
import 'package:fieldguard/features/manager/data/dto/create_manager_request.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class CreateManagerScreen extends StatefulWidget {
  const CreateManagerScreen({super.key});

  @override
  State<CreateManagerScreen> createState() => _CreateManagerScreenState();
}

class _CreateManagerScreenState extends State<CreateManagerScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;
  bool _isLoading = false;
  File? _selectedImage;
  String? _base64Image;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedImage = file;
          _base64Image = base64Encode(bytes);
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = CreateManagerRequest(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        password: _passwordController.text,
        profileImage: _base64Image,
      );

      final dio = DioClient.createDio();
      final dataSource = ManagerDataSourceImpl(dio);
      final response = await dataSource.createManager(request);

      if (mounted) {
        if (response.manager != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Manager created successfully! Code: ${response.manager!.managerCode}',
              ),
              backgroundColor: const Color(0xff6558FF),
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create manager'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        final errorMessage = _extractErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  String _extractErrorMessage(DioException e) {
    // Try to extract error message from response
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      
      // Check for errors array (validation errors)
      if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        final errors = data['errors'] as List;
        final errorMessages = errors
            .map((error) => error['message'] as String?)
            .where((msg) => msg != null)
            .join('\n');
        if (errorMessages.isNotEmpty) return errorMessages;
      }
      
      // Check for message field
      if (data['message'] is String && (data['message'] as String).isNotEmpty) {
        return data['message'] as String;
      }
    }
    
    // Fallback to generic error message
    return 'Failed to create manager. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Color(0xff6558FF)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Create New Manager',
              style: TextStyle(
                color: Color(0xff111111),
                fontWeight: FontWeight.w700,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: const Color(0xffE8E3DD),
              ),
            ),
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(SizeConfig.scale(20)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Image Picker
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: SizeConfig.scale(120),
                            height: SizeConfig.scale(120),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xff6558FF), Color(0xff8B3DFF)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xff6558FF)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: _selectedImage != null
                                ? ClipOval(
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    Icons.add_a_photo_rounded,
                                    size: SizeConfig.scale(40),
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: SizeConfig.heightPercent(1)),
                      Center(
                        child: Text(
                          'Tap to add profile photo',
                          style: TextStyle(
                            color: const Color(0xff667085),
                            fontSize: SizeConfig.scaledFontSize(12),
                          ),
                        ),
                      ),
                      SizedBox(height: SizeConfig.heightPercent(3)),

                      // Full Name Field
                      _buildLabel('Full Name *'),
                      _buildTextField(
                        controller: _fullNameController,
                        hint: 'Enter full name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: SizeConfig.heightPercent(2)),

                      // Phone Number Field
                      _buildLabel('Phone Number *'),
                      _buildTextField(
                        controller: _phoneController,
                        hint: '+91 98000 00000',
                        icon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: SizeConfig.heightPercent(2)),

                      // Email Field
                      _buildLabel('Email (Optional)'),
                      _buildTextField(
                        controller: _emailController,
                        hint: 'email@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: SizeConfig.heightPercent(2)),

                      // Password Field
                      _buildLabel('Password *'),
                      _buildTextField(
                        controller: _passwordController,
                        hint: 'Enter password',
                        icon: Icons.lock_outline,
                        obscureText: _hidePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xff667085),
                          ),
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: SizeConfig.heightPercent(4)),

                      // Submit Button
                      _buildSubmitButton(),
                      SizedBox(height: SizeConfig.heightPercent(2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.scale(8)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: SizeConfig.scaledFontSize(14),
          fontWeight: FontWeight.w600,
          color: const Color(0xff111111),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
        border: Border.all(color: const Color(0xffE8E3DD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xff9CA3AF),
            fontSize: SizeConfig.scaledFontSize(14),
          ),
          prefixIcon: Icon(icon, color: const Color(0xff6558FF)),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: SizeConfig.scale(16),
            vertical: SizeConfig.scale(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: SizeConfig.scale(56),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff6558FF), Color(0xff8B3DFF)],
        ),
        borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff6558FF).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _submitForm,
          borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.supervisor_account_rounded,
                        color: Colors.white,
                      ),
                      SizedBox(width: SizeConfig.scale(8)),
                      Text(
                        'Create Manager',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: SizeConfig.scaledFontSize(16),
                          fontWeight: FontWeight.w700,
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
