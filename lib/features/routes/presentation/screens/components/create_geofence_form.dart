import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/services/session.dart';
import 'package:fieldguard/core/utils/network_exception_mapper.dart';
import 'package:fieldguard/features/shops/data/datasource/shop_datasource_impl.dart';
import 'package:fieldguard/features/shops/data/dto/create_shop_request.dart';
import 'package:fieldguard/features/team/data/datasource/team_datasource_impl.dart';
import 'package:fieldguard/features/team/data/dto/employees_list_response.dart';
import 'package:fieldguard/features/team/data/dto/managers_list_response.dart';
import 'package:fieldguard/features/uploads/image_upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

class CreateGeofenceForm extends StatefulWidget {
  final double latitude;
  final double longitude;

  const CreateGeofenceForm({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<CreateGeofenceForm> createState() => _CreateGeofenceFormState();
}

class _CreateGeofenceFormState extends State<CreateGeofenceForm> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _panNumberController = TextEditingController();

  String? _shopImagePath;
  String? _imageKey;
  UploadStatus _uploadStatus = UploadStatus.idle;
  double _uploadProgress = 0.0;

  bool _isLoading = false;
  bool _isFetchingAddress = false;

  // Server-side contactPhone error (400 invalid format / 409 already in use),
  // shown inline on the phone field via its validator; cleared on edit.
  String? _phoneServerError;

  // Role-aware visibility picker. Employees never see this section since the
  // API ignores `visibleTo` for them. Managers can grant visibility only to
  // their direct employees; admins can grant it to any manager or employee.
  String? _role;
  bool _isLoadingTeam = false;
  List<ManagerItem> _managers = const [];
  List<EmployeeItem> _employees = const [];
  final Set<int> _selectedVisibleTo = <int>{};

  late final ShopDataSourceImpl _shopDataSource;
  late final ImageUploadService _uploadService;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _shopDataSource = ShopDataSourceImpl(DioClient.createDio());
    _uploadService = ImageUploadService(DioClient.createDio());
    _fetchAddressFromCoordinates();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    final role = await Session.role();
    final normalized = role?.toLowerCase();
    if (!mounted) return;

    // Employees can't grant visibility — skip the network call entirely.
    if (normalized == 'employee') {
      setState(() => _role = role);
      return;
    }

    setState(() {
      _role = role;
      _isLoadingTeam = true;
    });

    try {
      final dataSource = TeamDataSourceImpl(DioClient.createDio());
      final employees = await dataSource.getEmployees();
      // Only admins can grant visibility to managers.
      final managers = normalized == 'admin'
          ? await dataSource.getManagers()
          : null;

      if (!mounted) return;
      setState(() {
        _employees = employees.employees;
        _managers = managers?.managers ?? const [];
        _isLoadingTeam = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingTeam = false);
    }
  }

  Future<void> _openVisibilityPicker() async {
    final updated = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VisibilityPicker(
        managers: _managers,
        employees: _employees,
        initial: Set.of(_selectedVisibleTo),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _selectedVisibleTo
          ..clear()
          ..addAll(updated);
      });
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _panNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchAddressFromCoordinates() async {
    setState(() => _isFetchingAddress = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        widget.latitude,
        widget.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final addressParts = [
          place.street,
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.country,
        ].where((part) => part != null && part.isNotEmpty).toList();

        final address = addressParts.join(', ');
        
        if (mounted) {
          setState(() {
            _addressController.text = address;
            _isFetchingAddress = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isFetchingAddress = false);
        }
      }
    } catch (e) {
      // Silently fail - user can enter address manually
      if (mounted) {
        setState(() => _isFetchingAddress = false);
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo == null) return;

      final path = photo.path;
      setState(() {
        _shopImagePath = path;
        _imageKey = null;
        _uploadStatus = UploadStatus.uploading;
        _uploadProgress = 0.0;
      });

      try {
        final result = await _uploadService.upload(
          filePath: path,
          category: 'shops',
          entityId: 0,
          onProgress: (p) {
            if (mounted) setState(() => _uploadProgress = p);
          },
        );
        if (mounted) {
          setState(() {
            _imageKey = result.imageKey;
            _uploadStatus = UploadStatus.done;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _uploadStatus = UploadStatus.error);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to access camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() => setState(() {
        _shopImagePath = null;
        _imageKey = null;
        _uploadStatus = UploadStatus.idle;
        _uploadProgress = 0.0;
      });

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_uploadStatus == UploadStatus.uploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please wait for image upload to complete')),
      );
      return;
    }

    if (_uploadStatus == UploadStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Image upload failed. Please remove the image or try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final canSetVisibility =
          _role != null && _role!.toLowerCase() != 'employee';
      await _shopDataSource.createShop(
        CreateShopRequest(
          name: _shopNameController.text.trim(),
          panNumber: _panNumberController.text.trim(),
          address: _addressController.text.trim(),
          latitude: widget.latitude,
          longitude: widget.longitude,
          contactName: _contactNameController.text.trim(),
          contactPhone: _contactPhoneController.text.trim(),
          imageKey: _imageKey,
          visibleTo: canSetVisibility && _selectedVisibleTo.isNotEmpty
              ? _selectedVisibleTo.toList()
              : null,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop created successfully'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      // Prefer the specific field error (e.g. "Invalid PAN number format")
      // over the generic top-level "Validation failed" message.
      final mapped = NetworkExceptionMapper.map(e);
      final phoneError = mapped is ValidationException
          ? mapped.errorFor('contactPhone')
          : null;
      final isPhoneConflict = e.response?.statusCode == 409 &&
          mapped.message.toLowerCase().contains('phone');

      if (phoneError != null || isPhoneConflict) {
        // Surface phone clashes/format errors inline on the field; the 409
        // message is shown verbatim (it names which record holds the number).
        setState(() => _phoneServerError = phoneError ?? mapped.message);
        _formKey.currentState?.validate();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapped.message), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Create Geofence',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Fill in the shop details for this location.',
                  style: TextStyle(fontSize: 13, color: AppColors.grey5),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.green6,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.green11),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location,
                          color: AppColors.green, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Lat: ${widget.latitude.toStringAsFixed(6)}   '
                          'Lng: ${widget.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _FieldLabel('Shop Photo (Optional)'),
                const SizedBox(height: 8),
                _buildImagePicker(),
                const SizedBox(height: 16),
                _FieldLabel('Shop Name'),
                const SizedBox(height: 6),
                _buildField(
                  controller: _shopNameController,
                  hint: 'e.g. ABC Store',
                  icon: Icons.storefront_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Shop name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                _FieldLabel('Address'),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    _buildField(
                      controller: _addressController,
                      hint: 'e.g. Main Road, City',
                      icon: Icons.location_on_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Address is required'
                          : null,
                    ),
                    if (_isFetchingAddress)
                      Positioned(
                        right: 12,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _FieldLabel('Contact Name'),
                const SizedBox(height: 6),
                _buildField(
                  controller: _contactNameController,
                  hint: 'e.g. Full name',
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Contact name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                _FieldLabel('Contact Phone'),
                const SizedBox(height: 6),
                _buildField(
                  controller: _contactPhoneController,
                  hint: 'e.g. 98XXXXXXXX',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  onChanged: (_) {
                    if (_phoneServerError != null) {
                      setState(() => _phoneServerError = null);
                    }
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Contact phone is required';
                    }
                    if (v.trim().length != 10) {
                      return 'Phone number must be exactly 10 digits';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) {
                      return 'Phone number must contain only digits';
                    }
                    return _phoneServerError;
                  },
                ),
                const SizedBox(height: 16),
                _FieldLabel('PAN Number'),
                const SizedBox(height: 6),
                _buildField(
                  controller: _panNumberController,
                  hint: 'e.g. 123456789',
                  icon: Icons.credit_card_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'PAN number is required';
                    if (t.length != 9) return 'PAN number must be 9 digits';
                    return null;
                  },
                ),
                if (_role != null && _role!.toLowerCase() != 'employee') ...[
                  const SizedBox(height: 16),
                  _FieldLabel('Shared With (Optional)'),
                  const SizedBox(height: 6),
                  _buildVisibilitySelector(),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create Geofence',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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

  Widget _buildImagePicker() {
    if (_shopImagePath != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_shopImagePath!),
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
          if (_uploadStatus == UploadStatus.uploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _uploadProgress > 0 ? _uploadProgress : null,
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _uploadProgress > 0
                          ? '${(_uploadProgress * 100).toInt()}%'
                          : 'Uploading...',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          if (_uploadStatus == UploadStatus.error)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload failed',
                      style:
                          TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _takePhoto,
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_uploadStatus == UploadStatus.done)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check,
                    color: Colors.white, size: 16),
              ),
            ),
          if (_uploadStatus != UploadStatus.uploading)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _removeImage,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          if (_uploadStatus == UploadStatus.done)
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Retake',
                          style:
                              TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.white5,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey4),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt,
                size: 32, color: AppColors.grey2),
            SizedBox(height: 8),
            Text(
              'Tap to take shop photo',
              style: TextStyle(fontSize: 13, color: AppColors.grey2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilitySelector() {
    final total = _managers.length + _employees.length;
    final selected = _selectedVisibleTo.length;

    String summary;
    if (_isLoadingTeam) {
      summary = 'Loading team…';
    } else if (total == 0) {
      summary = 'No teammates available';
    } else if (selected == 0) {
      summary = 'Only the default hierarchy can see this shop';
    } else {
      summary = '$selected selected';
    }

    return InkWell(
      onTap: _isLoadingTeam || total == 0 ? null : _openVisibilityPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white5,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey4),
        ),
        child: Row(
          children: [
            const Icon(Icons.visibility_outlined,
                color: AppColors.grey2, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                summary,
                style: TextStyle(
                  fontSize: 14,
                  color: selected > 0
                      ? AppColors.ink
                      : AppColors.grey5,
                  fontWeight:
                      selected > 0 ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (_isLoadingTeam)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.green,
                ),
              )
            else
              const Icon(Icons.chevron_right,
                  color: AppColors.grey2, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.grey2, fontSize: 14),
        prefixIcon:
            Icon(icon, color: AppColors.grey2, size: 20),
        filled: true,
        fillColor: AppColors.white5,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.blue2,
      ),
    );
  }
}

class _VisibilityPicker extends StatefulWidget {
  final List<ManagerItem> managers;
  final List<EmployeeItem> employees;
  final Set<int> initial;

  const _VisibilityPicker({
    required this.managers,
    required this.employees,
    required this.initial,
  });

  @override
  State<_VisibilityPicker> createState() => _VisibilityPickerState();
}

class _VisibilityPickerState extends State<_VisibilityPicker> {
  late final Set<int> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set.of(widget.initial);
  }

  bool _matches(String name, String code) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return name.toLowerCase().contains(q) || code.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final managers = widget.managers
        .where((m) => _matches(m.fullName, m.managerCode))
        .toList();
    final employees = widget.employees
        .where((e) => _matches(e.fullName, e.employeeCode))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Share Visibility',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _selected.isEmpty
                          ? null
                          : () => setState(_selected.clear),
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  '${_selected.length} selected',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.grey5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search by name or code',
                    hintStyle: const TextStyle(
                      color: AppColors.grey2,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.grey2, size: 20),
                    filled: true,
                    fillColor: AppColors.white5,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.grey4),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.grey4),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.green, width: 1.5),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: managers.isEmpty && employees.isEmpty
                    ? const Center(
                        child: Text(
                          'No matches found',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.grey5,
                          ),
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        children: [
                          if (managers.isNotEmpty) ...[
                            const _PickerSectionHeader(label: 'Managers'),
                            ...managers.map((m) => _PickerTile(
                                  name: m.fullName,
                                  code: m.managerCode,
                                  selected:
                                      _selected.contains(int.tryParse(m.id)),
                                  onTap: () =>
                                      _toggle(int.tryParse(m.id)),
                                  gradient: const [
                                    AppColors.blue,
                                    AppColors.purple,
                                  ],
                                )),
                          ],
                          if (employees.isNotEmpty) ...[
                            const _PickerSectionHeader(label: 'Employees'),
                            ...employees.map((e) => _PickerTile(
                                  name: e.fullName,
                                  code: e.employeeCode,
                                  selected:
                                      _selected.contains(int.tryParse(e.id)),
                                  onTap: () =>
                                      _toggle(int.tryParse(e.id)),
                                  gradient: const [
                                    AppColors.green,
                                    AppColors.gradientStart,
                                  ],
                                )),
                          ],
                        ],
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(context).pop(_selected),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggle(int? id) {
    if (id == null) return;
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }
}

class _PickerSectionHeader extends StatelessWidget {
  final String label;
  const _PickerSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.grey2,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String name;
  final String code;
  final bool selected;
  final VoidCallback onTap;
  final List<Color> gradient;

  const _PickerTile({
    required this.name,
    required this.code,
    required this.selected,
    required this.onTap,
    required this.gradient,
  });

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.green6
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.green
                : AppColors.grey4,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: gradient),
              ),
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: selected
                  ? AppColors.green
                  : AppColors.grey29,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
