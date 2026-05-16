import 'dart:io';

import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/features/shops/data/dto/shops_hierarchy_response.dart';
import 'package:fieldguard/features/shops/data/dto/update_shop_request.dart';
import 'package:fieldguard/features/shops/presentation/providers/update_shop_provider.dart';
import 'package:fieldguard/features/shops/presentation/providers/update_shop_state.dart';
import 'package:fieldguard/features/uploads/image_upload_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateShopScreen extends ConsumerStatefulWidget {
  final Shop shop;

  const UpdateShopScreen({super.key, required this.shop});

  @override
  ConsumerState<UpdateShopScreen> createState() => _UpdateShopScreenState();
}

class _UpdateShopScreenState extends ConsumerState<UpdateShopScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _contactPhoneController;
  final _panNumberController = TextEditingController();

  late bool _isActive;

  // Image — null means keep existing, non-null means replace
  String? _shopImagePath;
  String? _imageKey;
  UploadStatus _uploadStatus = UploadStatus.idle;
  double _uploadProgress = 0.0;

  late final ImageUploadService _uploadService;

  // Map
  MapboxMap? _mapboxMap;
  bool _mapOverlayVisible = true;
  bool _isLocatingGps = false;

  // Coordinates — start with saved values
  late double _lat;
  late double _lng;
  bool _coordsUpdated = false;

  @override
  void initState() {
    super.initState();
    _lat = double.tryParse(widget.shop.latitude) ?? 0.0;
    _lng = double.tryParse(widget.shop.longitude) ?? 0.0;
    _nameController = TextEditingController(text: widget.shop.name);
    _addressController = TextEditingController(text: widget.shop.address);
    _contactNameController =
        TextEditingController(text: widget.shop.contactName);
    _contactPhoneController =
        TextEditingController(text: widget.shop.contactPhone);
    _isActive = widget.shop.isActive;
    _uploadService = ImageUploadService(DioClient.createDio());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _panNumberController.dispose();
    super.dispose();
  }

  // ── Image ────────────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    setState(() {
      _shopImagePath = path;
      _imageKey = null;
      _uploadStatus = UploadStatus.uploading;
      _uploadProgress = 0.0;
    });

    try {
      final uploadResult = await _uploadService.upload(
        filePath: path,
        category: 'shops',
        entityId: widget.shop.id,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      if (mounted) {
        setState(() {
          _imageKey = uploadResult.imageKey;
          _uploadStatus = UploadStatus.done;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _uploadStatus = UploadStatus.error);
    }
  }

  void _removeImage() => setState(() {
        _shopImagePath = null;
        _imageKey = null;
        _uploadStatus = UploadStatus.idle;
        _uploadProgress = 0.0;
      });

  // ── Map ──────────────────────────────────────────────────────────────────────

  void _onMapCreated(MapboxMap map) {
    _mapboxMap = map;
    _initMap();
  }

  Future<void> _initMap() async {
    await _mapboxMap?.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
    await _mapboxMap?.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(_lng, _lat)),
        zoom: 15.0,
      ),
    );
    if (mounted) setState(() => _mapOverlayVisible = false);
  }

  Future<void> _updateGeoCoordinates() async {
    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (!mounted) return;
    setState(() => _isLocatingGps = true);

    try {
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _coordsUpdated = true;
        _isLocatingGps = false;
      });

      await _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(pos.longitude, pos.latitude)),
          zoom: 16.0,
        ),
        MapAnimationOptions(duration: 1000),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isLocatingGps = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to get current location. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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

    await ref.read(updateShopNotifierProvider.notifier).updateShop(
          widget.shop.id,
          UpdateShopRequest(
            name: _nameController.text.trim(),
            panNumber: _panNumberController.text.trim().isEmpty
                ? null
                : _panNumberController.text.trim(),
            address: _addressController.text.trim(),
            latitude: _lat,
            longitude: _lng,
            contactName: _contactNameController.text.trim(),
            contactPhone: _contactPhoneController.text.trim(),
            isActive: _isActive,
            imageKey: _imageKey,
          ),
        );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<UpdateShopState>(updateShopNotifierProvider, (_, next) {
      if (next is UpdateShopSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop updated successfully'),
            backgroundColor: Color(0xff0E5A3B),
          ),
        );
        Navigator.of(context).pop(true);
      } else if (next is UpdateShopFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red),
        );
      }
    });

    final isLoading =
        ref.watch(updateShopNotifierProvider) is UpdateShopLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff111111)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Shop',
              style: TextStyle(
                color: Color(0xff111111),
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            Text(
              widget.shop.name,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff667085),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildMapSection(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCoordinatesCard(),
                    const SizedBox(height: 12),
                    _buildUpdateCoordsButton(),
                    const SizedBox(height: 24),
                    _FieldLabel('Shop Photo'),
                    const SizedBox(height: 8),
                    _buildImageSection(),
                    const SizedBox(height: 20),
                    _FieldLabel('Shop Name'),
                    const SizedBox(height: 6),
                    _buildField(
                      controller: _nameController,
                      hint: 'e.g. Rajan Enterprises',
                      icon: Icons.storefront_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Shop name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('Address'),
                    const SizedBox(height: 6),
                    _buildField(
                      controller: _addressController,
                      hint: 'e.g. Birgunj, Nepal',
                      icon: Icons.location_on_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Address is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('Contact Name'),
                    const SizedBox(height: 6),
                    _buildField(
                      controller: _contactNameController,
                      hint: 'e.g. Bhupendra Prasad',
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
                      hint: 'e.g. 9804208475',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
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
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('PAN Number (Optional)'),
                    const SizedBox(height: 6),
                    _buildField(
                      controller: _panNumberController,
                      hint: 'e.g. ABCDE1234F',
                      icon: Icons.credit_card_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildActiveToggle(),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0E5A3B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          MapWidget(
            key: ValueKey('updateShopMap_${widget.shop.id}'),
            styleUri: MapboxStyles.STANDARD,
            textureView: true,
            onMapCreated: _onMapCreated,
          ),
          if (_isLocatingGps)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: Color(0xff0E5A3B),
                backgroundColor: Color(0xffDDF5E0),
              ),
            ),
          AnimatedOpacity(
            opacity: _mapOverlayVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            child: _mapOverlayVisible
                ? Container(
                    color: const Color(0xFFF5F6FA),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                              color: Color(0xff0E5A3B)),
                          SizedBox(height: 8),
                          Text(
                            'Loading map...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xff667085),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatesCard() {
    if (!_coordsUpdated) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD1FADF)),
        ),
        child: Row(
          children: [
            const Icon(Icons.my_location,
                color: Color(0xff0E5A3B), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Saved Location\n'
                'Lat: ${_lat.toStringAsFixed(6)}   '
                'Lng: ${_lng.toStringAsFixed(6)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xff0E5A3B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_searching,
                  color: Color(0xFFFF8F00), size: 18),
              SizedBox(width: 8),
              Text(
                'New Location Preview',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFFF8F00),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Lat: ${_lat.toStringAsFixed(6)}   '
            'Lng: ${_lng.toStringAsFixed(6)}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xff111111),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCoordsButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLocatingGps ? null : _updateGeoCoordinates,
        icon: _isLocatingGps
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xff0E5A3B),
                ),
              )
            : const Icon(Icons.gps_fixed, size: 20),
        label: Text(
          _isLocatingGps ? 'Getting Location...' : 'Update Geo-Coordinates',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xff0E5A3B),
          side: const BorderSide(color: Color(0xff0E5A3B), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildActiveToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.toggle_on_outlined,
              color: Color(0xFF9CA3AF), size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                Text(
                  'Enable or disable this shop',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeThumbColor: const Color(0xff0E5A3B),
            activeTrackColor: const Color(0xffDDF5E0),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    // Priority: newly picked local file > existing network image > empty picker
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
                      onPressed: _pickImage,
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
                  color: Color(0xff0E5A3B),
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
                onTap: _pickImage,
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
                      Icon(Icons.edit, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Change',
                          style: TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    }

    final existingUrl = widget.shop.shopImage;
    if (existingUrl != null && existingUrl.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              existingUrl,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _emptyImagePicker(),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _pickImage,
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
                    Icon(Icons.edit, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Change',
                        style: TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return _emptyImagePicker();
  }

  Widget _emptyImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 32, color: Color(0xFF9CA3AF)),
            SizedBox(height: 8),
            Text(
              'Tap to add shop photo',
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  TextFormField _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        prefixIcon:
            Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xff0E5A3B), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
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
        color: Color(0xFF374151),
      ),
    );
  }
}
