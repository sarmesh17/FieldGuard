import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/features/manager/data/datasource/manager_datasource_impl.dart';
import 'package:fieldguard/features/manager/data/dto/update_manager_request.dart';
import 'package:flutter/material.dart';

class EditManagerScreen extends StatefulWidget {
  final String managerId;
  final String currentFullName;
  final String currentPhoneNumber;
  final String? currentEmail;
  final bool currentIsActive;

  const EditManagerScreen({
    super.key,
    required this.managerId,
    required this.currentFullName,
    required this.currentPhoneNumber,
    this.currentEmail,
    required this.currentIsActive,
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
      );

      await dataSource.updateManager(widget.managerId, request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manager updated successfully'),
            backgroundColor: Color(0xff6558FF),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_extractErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      
      // Check for errors array
      if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        final firstError = (data['errors'] as List).first;
        if (firstError is Map<String, dynamic> && firstError['message'] is String) {
          return firstError['message'] as String;
        }
      }
      
      // Check for message field
      if (data['message'] is String) {
        return data['message'] as String;
      }
    }
    return 'Failed to update manager';
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          appBar: AppBar(
            backgroundColor: const Color(0xff6558FF),
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter phone number';
                      }
                      if (value.trim().length < 10) {
                        return 'Phone number must be at least 10 digits';
                      }
                      return null;
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
                            color: const Color(0xff6558FF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                          ),
                          child: Icon(
                            Icons.toggle_on,
                            color: const Color(0xff6558FF),
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
                                _isActive ? 'Manager is active' : 'Manager is inactive',
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
                          activeColor: const Color(0xff6558FF),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.heightPercent(4)),

                  // Update Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateManager,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff6558FF),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xff6558FF)),
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
          borderSide: const BorderSide(color: Color(0xff6558FF), width: 2),
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
