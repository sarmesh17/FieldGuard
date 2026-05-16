import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/features/shops/data/datasource/shop_detail_datasource_impl.dart';
import 'package:fieldguard/features/shops/data/dto/shop_detail_response.dart';
import 'package:fieldguard/features/tasks/presentation/screens/create_task_screen.dart';
import 'package:flutter/material.dart';

class ShopDetailScreen extends StatefulWidget {
  final String shopId;

  const ShopDetailScreen({super.key, required this.shopId});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  bool _isLoading = true;
  ShopDetailData? _shopDetail;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadShopDetail();
  }

  Future<void> _loadShopDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = DioClient.createDio();
      final dataSource = ShopDetailDataSourceImpl(dio);
      final response = await dataSource.getShopDetail(widget.shopId);

      setState(() {
        _shopDetail = response.shop;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _errorMessage = _extractErrorMessage(e);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load shop details';
        _isLoading = false;
      });
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      if (data['message'] is String) {
        return data['message'] as String;
      }
    }
    return 'Failed to load shop details';
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
              'Shop Details',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _buildErrorView()
                  : _buildContent(),
        );
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: SizeConfig.scale(60),
            color: Colors.red,
          ),
          SizedBox(height: SizeConfig.heightPercent(2)),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(16),
              color: const Color(0xff667085),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.heightPercent(3)),
          ElevatedButton(
            onPressed: _loadShopDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff0E5A3B),
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.scale(32),
                vertical: SizeConfig.scale(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_shopDetail == null) return const SizedBox();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop Image
          if (_shopDetail!.shopImage != null && _shopDetail!.shopImage!.isNotEmpty)
            Image.network(
              _shopDetail!.shopImage!,
              width: double.infinity,
              height: SizeConfig.scale(200),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: SizeConfig.scale(200),
                color: const Color(0xffE8E3DD),
                child: Icon(
                  Icons.store,
                  size: SizeConfig.scale(80),
                  color: const Color(0xff667085),
                ),
              ),
            ),

          Padding(
            padding: EdgeInsets.all(SizeConfig.scale(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Name and Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _shopDetail!.name,
                        style: TextStyle(
                          fontSize: SizeConfig.scaledFontSize(24),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xff111111),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.scale(12),
                        vertical: SizeConfig.scale(6),
                      ),
                      decoration: BoxDecoration(
                        color: _shopDetail!.isActive
                            ? const Color(0xffDDF5E0)
                            : const Color(0xffFFE3E6),
                        borderRadius: BorderRadius.circular(SizeConfig.scale(20)),
                      ),
                      child: Text(
                        _shopDetail!.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: SizeConfig.scaledFontSize(12),
                          color: _shopDetail!.isActive
                              ? const Color(0xff0E5A3B)
                              : const Color(0xffFF3B3B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.heightPercent(3)),

                // Shop Information Section
                _buildSectionTitle('Shop Information'),
                SizedBox(height: SizeConfig.scale(12)),
                _buildInfoCard(
                  icon: Icons.location_on,
                  label: 'Address',
                  value: _shopDetail!.address,
                ),
                SizedBox(height: SizeConfig.scale(12)),
                _buildInfoCard(
                  icon: Icons.my_location,
                  label: 'Coordinates',
                  value: 'Lat: ${_shopDetail!.latitude}, Lng: ${_shopDetail!.longitude}',
                ),
                if (_shopDetail!.panNumber != null) ...[
                  SizedBox(height: SizeConfig.scale(12)),
                  _buildInfoCard(
                    icon: Icons.credit_card,
                    label: 'PAN Number',
                    value: _shopDetail!.panNumber!,
                  ),
                ],
                SizedBox(height: SizeConfig.heightPercent(3)),

                // Contact Information Section
                _buildSectionTitle('Contact Information'),
                SizedBox(height: SizeConfig.scale(12)),
                _buildInfoCard(
                  icon: Icons.person,
                  label: 'Contact Name',
                  value: _shopDetail!.contactName,
                ),
                SizedBox(height: SizeConfig.scale(12)),
                _buildInfoCard(
                  icon: Icons.phone,
                  label: 'Contact Phone',
                  value: _shopDetail!.contactPhone,
                ),
                SizedBox(height: SizeConfig.heightPercent(3)),

                // Created By Section
                _buildSectionTitle('Created By'),
                SizedBox(height: SizeConfig.scale(12)),
                _buildInfoCard(
                  icon: Icons.person_outline,
                  label: 'Creator',
                  value: '${_shopDetail!.creator.fullName} (${_shopDetail!.creator.employeeCode})',
                ),
                SizedBox(height: SizeConfig.scale(12)),
                _buildInfoCard(
                  icon: Icons.calendar_today,
                  label: 'Created At',
                  value: _formatDate(_shopDetail!.createdAt),
                ),
                SizedBox(height: SizeConfig.scale(12)),
                _buildInfoCard(
                  icon: Icons.update,
                  label: 'Last Updated',
                  value: _formatDate(_shopDetail!.updatedAt),
                ),
                SizedBox(height: SizeConfig.heightPercent(4)),

                // Create Task Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateTaskScreen(
                            shopId: _shopDetail!.id,
                            shopLatitude: double.tryParse(_shopDetail!.latitude),
                            shopLongitude: double.tryParse(_shopDetail!.longitude),
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task created successfully'),
                            backgroundColor: Color(0xff0E5A3B),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      Icons.add_task,
                      size: SizeConfig.scale(20),
                    ),
                    label: Text(
                      'Create Task',
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(16),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0E5A3B),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.scale(16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.heightPercent(2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: SizeConfig.scaledFontSize(18),
        fontWeight: FontWeight.w700,
        color: const Color(0xff111111),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.scale(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
        border: Border.all(color: const Color(0xffE8E3DD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
              icon,
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
                  label,
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(12),
                    color: const Color(0xff667085),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: SizeConfig.scale(4)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(15),
                    color: const Color(0xff111111),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
