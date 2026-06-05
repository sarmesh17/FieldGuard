import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/core/utils/network_exception_mapper.dart';
import 'package:fieldguard/core/services/session.dart';
import 'package:fieldguard/features/employee/data/datasource/employee_datasource_impl.dart';
import 'package:fieldguard/features/employee/data/dto/create_employee_request.dart';
import 'package:fieldguard/features/subscription/presentation/widgets/seat_limit_dialog.dart';
import 'package:fieldguard/features/team/data/datasource/team_datasource_impl.dart';
import 'package:fieldguard/features/team/data/dto/managers_list_response.dart';
import 'package:fieldguard/features/uploads/image_upload_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({super.key});

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Manager picker (ADMIN only) — fetched from the managers list so the admin
  // selects by name instead of remembering a numeric id.
  List<ManagerItem> _managers = [];
  String? _selectedManagerId;
  bool _loadingManagers = false;

  // Server-side phone error from a 400 (e.g. invalid format) or 409 (already
  // in use), surfaced via the phone field's validator. Cleared when the user
  // edits the field so the stale error doesn't linger.
  String? _phoneServerError;

  bool _hidePassword = true;
  bool _isLoading = false;
  // The Manager ID field is admin-only — a manager can't assign an employee
  // to another manager, so hide it for them.
  bool _isManagerUser = false;
  File? _selectedImage;
  String? _uploadedImageKey;
  bool _isUploadingImage = false;

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
    _checkRole();
  }

  Future<void> _checkRole() async {
    final isManager = await Session.isManager();
    if (!mounted) return;
    setState(() => _isManagerUser = isManager);
    // Only ADMIN assigns a manager — load the list for the dropdown.
    if (!isManager) _loadManagers();
  }

  Future<void> _loadManagers() async {
    setState(() => _loadingManagers = true);
    try {
      final dio = DioClient.createDio();
      final res = await TeamDataSourceImpl(dio).getManagers();
      if (!mounted) return;
      setState(() {
        _managers = res.managers;
        _loadingManagers = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingManagers = false);
    }
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
        setState(() {
          _selectedImage = File(result.files.single.path!);
        });
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      
      // Use a temporary entityId (0) since employee doesn't exist yet
      final uploadResult = await uploadService.upload(
        filePath: _selectedImage!.path,
        category: 'profiles',
        entityId: 0, // Temporary ID, will be updated after employee creation
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = CreateEmployeeRequest(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        password: _passwordController.text,
        managerId: _selectedManagerId,
        imageKey: _uploadedImageKey,
      );

      final dio = DioClient.createDio();
      final dataSource = EmployeeDataSourceImpl(dio);
      final response = await dataSource.createEmployee(request);

      if (mounted) {
        if (response.employee != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Employee created successfully! Code: ${response.employee!.employeeCode}',
              ),
              backgroundColor: AppColors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create employee'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on DioException catch (e) {
      // 402 = staff seat limit reached → prompt to upgrade the plan.
      if (e.response?.statusCode == 402) {
        if (mounted) {
          showSeatLimitDialog(context, NetworkExceptionMapper.map(e).message);
        }
        return;
      }
      if (mounted) _handlePhoneAwareError(e);
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

  /// Surfaces a phone clash/format error (400 or 409) inline on the phone
  /// field; anything else goes to a snackbar. The 409 message is shown
  /// verbatim — it already names which record holds the number.
  void _handlePhoneAwareError(DioException e) {
    final mapped = NetworkExceptionMapper.map(e);
    final phoneError = mapped is ValidationException
        ? mapped.errorFor('phoneNumber')
        : null;
    final isPhoneConflict =
        e.response?.statusCode == 409 && _looksLikePhoneMessage(mapped.message);

    if (phoneError != null || isPhoneConflict) {
      setState(() => _phoneServerError = phoneError ?? mapped.message);
      _formKey.currentState?.validate();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mapped.message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  bool _looksLikePhoneMessage(String message) =>
      message.toLowerCase().contains('phone');

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: AppColors.green),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Create New Employee',
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: AppColors.grey3,
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
                        child: Stack(
                          children: [
                            Container(
                              width: SizeConfig.scale(120),
                              height: SizeConfig.scale(120),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _selectedImage != null
                                    ? null
                                    : const LinearGradient(
                                        colors: [AppColors.green, AppColors.gradientStart],
                                      ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.green
                                        .withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: _isUploadingImage
                                  ? Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.grey4,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.green,
                                        ),
                                      ),
                                    )
                                  : _selectedImage != null
                                      ? ClipOval(
                                          child: Image.file(
                                            _selectedImage!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Icon(
                                          Icons.person_rounded,
                                          size: SizeConfig.scale(50),
                                          color: Colors.white,
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
                                    color: AppColors.green,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
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
                                    size: SizeConfig.scale(20),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.heightPercent(1)),
                      Center(
                        child: Text(
                          _uploadedImageKey != null
                              ? 'Image uploaded successfully'
                              : 'Tap camera icon to add profile photo',
                          style: TextStyle(
                            color: _uploadedImageKey != null
                                ? AppColors.green
                                : AppColors.grey,
                            fontSize: SizeConfig.scaledFontSize(12),
                            fontWeight: _uploadedImageKey != null
                                ? FontWeight.w600
                                : FontWeight.normal,
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
                        hint: '+977 9800000000',
                        icon: Icons.phone_android_rounded,
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
                            return 'Phone number is required';
                          }
                          if (value.trim().length != 10) {
                            return 'Phone number must be exactly 10 digits';
                          }
                          return _phoneServerError;
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
                            color: AppColors.grey,
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
                      SizedBox(height: SizeConfig.heightPercent(2)),

                      // Manager Field — ADMIN only.
                      if (!_isManagerUser) ...[
                        _buildLabel('Manager (Optional)'),
                        _buildManagerDropdown(),
                        SizedBox(height: SizeConfig.heightPercent(1)),
                        Text(
                          'Choose a manager, or leave as "No manager" (ADMIN only)',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: SizeConfig.scaledFontSize(11),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: SizeConfig.heightPercent(4)),
                      ] else
                        SizedBox(height: SizeConfig.heightPercent(2)),

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
          color: AppColors.black,
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
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
        border: Border.all(color: AppColors.grey3),
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
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.grey2,
            fontSize: SizeConfig.scaledFontSize(14),
          ),
          prefixIcon: Icon(icon, color: AppColors.green),
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

  Widget _buildManagerDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.scale(16),
        vertical: SizeConfig.scale(6),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
        border: Border.all(color: AppColors.grey3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.supervisor_account_outlined,
              color: AppColors.green),
          SizedBox(width: SizeConfig.scale(12)),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedManagerId,
                isExpanded: true,
                borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                icon: _loadingManagers
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.green,
                        ),
                      )
                    : const Icon(Icons.arrow_drop_down_rounded,
                        color: AppColors.green),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'No manager',
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(14),
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                  ..._managers.map(
                    (m) => DropdownMenuItem<String?>(
                      value: m.id,
                      child: Text(
                        m.managerCode.isEmpty
                            ? m.fullName
                            : '${m.fullName} · ${m.managerCode}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: SizeConfig.scaledFontSize(14),
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedManagerId = v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: SizeConfig.scale(56),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.green, AppColors.gradientStart],
        ),
        borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.4),
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
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                      ),
                      SizedBox(width: SizeConfig.scale(8)),
                      Text(
                        'Create Employee',
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
