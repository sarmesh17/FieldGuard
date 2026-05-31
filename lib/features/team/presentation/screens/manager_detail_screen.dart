import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/core/services/session.dart';
import 'package:fieldguard/core/utils/phone_format.dart';
import 'package:fieldguard/features/manager/data/datasource/manager_datasource_impl.dart';
import 'package:fieldguard/features/manager/presentation/screens/edit_manager_screen.dart';
import 'package:fieldguard/features/team/data/datasource/team_datasource_impl.dart';
import 'package:fieldguard/features/team/data/dto/manager_detail_response.dart';
import 'package:fieldguard/widgets/app_skeletons.dart';
import 'package:flutter/material.dart';

class ManagerDetailScreen extends StatefulWidget {
  final String managerId;
  final String managerName;

  const ManagerDetailScreen({
    super.key,
    required this.managerId,
    required this.managerName,
  });

  @override
  State<ManagerDetailScreen> createState() => _ManagerDetailScreenState();
}

class _ManagerDetailScreenState extends State<ManagerDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  ManagerDetail? _manager;
  String? _errorMessage;
  bool _isAdmin = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadManagerDetail();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final r = await Session.role();
    if (mounted) setState(() => _isAdmin = r?.toUpperCase() == 'ADMIN');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadManagerDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = DioClient.createDio();
      final dataSource = TeamDataSourceImpl(dio);
      final response = await dataSource.getManagerDetail(widget.managerId);

      setState(() {
        _manager = response.manager;
        _isLoading = false;
      });
      _animationController.forward();
    } on DioException catch (e) {
      setState(() {
        _errorMessage = _extractErrorMessage(e);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load manager details';
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
    return 'Failed to load manager details';
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Manager'),
          content: Text(
            'Are you sure you want to delete ${_manager?.fullName ?? 'this manager'}?\n\n'
            'This is permanent. Once deleted, the manager cannot be recovered '
            'or restored — this action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteManager();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteManager() async {
    try {
      final dio = DioClient.createDio();
      final dataSource = ManagerDataSourceImpl(dio);
      
      await dataSource.deleteManager(widget.managerId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manager deleted successfully'),
            backgroundColor: Color(0xff0E5A3B),
          ),
        );
        Navigator.pop(context, true); // Return to previous screen
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
            content: Text('Failed to delete manager'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          body: _isLoading
              ? const SkeletonDetail()
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
            onPressed: _loadManagerDetail,
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
    if (_manager == null) return const SizedBox();

    return CustomScrollView(
      slivers: [
        // App Bar with Hero Image
        SliverAppBar(
          expandedHeight: SizeConfig.heightPercent(30),
          pinned: true,
          backgroundColor: const Color(0xff0E5A3B),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditManagerScreen(
                      managerId: int.parse(widget.managerId),
                      currentFullName: _manager!.fullName,
                      currentPhoneNumber: _manager!.phoneNumber,
                      currentEmail: _manager!.email,
                      currentIsActive: _manager!.isActive,
                      currentProfileImage: _manager!.profileImage,
                    ),
                  ),
                );
                
                // Reload data if update was successful
                if (result == true) {
                  _loadManagerDetail();
                }
              },
            ),
            // Soft-delete is ADMIN only — hidden for managers (who can still edit).
            if (_isAdmin)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () => _showDeleteConfirmation(),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff0E5A3B), Color(0xff1D7A51)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: SizeConfig.heightPercent(8)),
                  // Profile Image
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: SizeConfig.scale(100),
                      height: SizeConfig.scale(100),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _manager!.profileImage != null
                          ? ClipOval(
                              child: Image.network(
                                _manager!.profileImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.white,
                                  child: Icon(
                                    Icons.person,
                                    size: SizeConfig.scale(50),
                                    color: const Color(0xff0E5A3B),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: SizeConfig.scale(50),
                                color: const Color(0xff0E5A3B),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.scale(12)),
                  // Name
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      _manager!.fullName,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(24),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.scale(4)),
                  // Manager Code
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      _manager!.managerCode,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(14),
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.scale(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.scale(16),
                          vertical: SizeConfig.scale(8),
                        ),
                        decoration: BoxDecoration(
                          color: _manager!.isActive
                              ? const Color(0xffDDF5E0)
                              : const Color(0xffFFE3E6),
                          borderRadius:
                              BorderRadius.circular(SizeConfig.scale(20)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: SizeConfig.scale(8),
                              height: SizeConfig.scale(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _manager!.isActive
                                    ? const Color(0xff0E5A3B)
                                    : const Color(0xffFF3B3B),
                              ),
                            ),
                            SizedBox(width: SizeConfig.scale(8)),
                            Text(
                              _manager!.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: SizeConfig.scaledFontSize(14),
                                color: _manager!.isActive
                                    ? const Color(0xff0E5A3B)
                                    : const Color(0xffFF3B3B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: SizeConfig.heightPercent(3)),

                    // Statistics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Assigned',
                            _manager!.assignedCount.toString(),
                            Icons.people,
                            const Color(0xff0E5A3B),
                          ),
                        ),
                        SizedBox(width: SizeConfig.scale(12)),
                        Expanded(
                          child: _buildStatCard(
                            'Created',
                            _manager!.createdCount.toString(),
                            Icons.person_add,
                            const Color(0xff1D7A51),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.heightPercent(3)),

                    // Contact Information
                    _buildSectionTitle('Contact Information'),
                    SizedBox(height: SizeConfig.scale(12)),
                    _buildInfoCard(
                      icon: Icons.phone,
                      label: 'Phone Number',
                      value: formatNepaliPhone(_manager!.phoneNumber),
                      iconColor: const Color(0xff0E5A3B),
                    ),
                    if (_manager!.email != null) ...[
                      SizedBox(height: SizeConfig.scale(12)),
                      _buildInfoCard(
                        icon: Icons.email,
                        label: 'Email',
                        value: _manager!.email!,
                        iconColor: const Color(0xff0E5A3B),
                      ),
                    ],
                    SizedBox(height: SizeConfig.heightPercent(3)),

                    // Employment Details
                    _buildSectionTitle('Employment Details'),
                    SizedBox(height: SizeConfig.scale(12)),
                    _buildInfoCard(
                      icon: Icons.badge,
                      label: 'Role',
                      value: _manager!.role,
                      iconColor: const Color(0xff1D7A51),
                    ),
                    SizedBox(height: SizeConfig.scale(12)),
                    _buildInfoCard(
                      icon: Icons.business,
                      label: 'Company ID',
                      value: _manager!.companyId,
                      iconColor: const Color(0xff1D7A51),
                    ),
                    SizedBox(height: SizeConfig.scale(12)),
                    _buildInfoCard(
                      icon: Icons.calendar_today,
                      label: 'Joined Date',
                      value: _formatDate(_manager!.createdAt),
                      iconColor: const Color(0xff1D7A51),
                    ),
                    SizedBox(height: SizeConfig.heightPercent(3)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.scale(16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: SizeConfig.scale(32),
          ),
          SizedBox(height: SizeConfig.scale(8)),
          Text(
            value,
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(24),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: SizeConfig.scale(4)),
          Text(
            label,
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(12),
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
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
    required Color iconColor,
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
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
            ),
            child: Icon(
              icon,
              color: iconColor,
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
}
