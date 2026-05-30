import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/core/utils/phone_format.dart';
import 'package:fieldguard/features/employee/data/datasource/employee_datasource_impl.dart';
import 'package:fieldguard/features/employee/presentation/screens/edit_employee_screen.dart';
import 'package:fieldguard/features/live_tracking/presentation/screens/live_map_screen.dart';
import 'package:fieldguard/features/live_tracking/presentation/screens/tracking_history_screen.dart';
import 'package:fieldguard/features/team/data/datasource/team_datasource_impl.dart';
import 'package:fieldguard/features/team/data/dto/employee_detail_response.dart';
import 'package:fieldguard/widgets/app_skeletons.dart';
import 'package:flutter/material.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeDetailScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  EmployeeDetail? _employee;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _avatarScale;

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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _avatarScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _loadEmployeeDetail();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployeeDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = DioClient.createDio();
      final dataSource = TeamDataSourceImpl(dio);
      final response = await dataSource.getEmployeeDetail(widget.employeeId);

      setState(() {
        _employee = response.employee;
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
        _errorMessage = 'Failed to load employee details';
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
    return 'Failed to load employee details';
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _openEditScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEmployeeScreen(
          employeeId: int.parse(widget.employeeId),
          currentFullName: _employee!.fullName,
          currentPhoneNumber: _employee!.phoneNumber,
          currentEmail: _employee!.email,
          currentIsActive: _employee!.isActive,
          currentProfileImage: _employee!.profileImage,
        ),
      ),
    );
    // Reload data if update was successful
    if (result == true) {
      _loadEmployeeDetail();
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Employee'),
          content: Text(
            'Are you sure you want to delete ${_employee?.fullName ?? 'this employee'}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteEmployee();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEmployee() async {
    try {
      final dio = DioClient.createDio();
      final dataSource = EmployeeDataSourceImpl(dio);

      await dataSource.deleteEmployee(widget.employeeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee deleted successfully'),
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
            content: Text('Failed to delete employee'),
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
            onPressed: _loadEmployeeDetail,
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
    if (_employee == null) return const SizedBox();

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
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _openEditScreen();
                } else if (value == 'delete') {
                  _showDeleteConfirmation();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: Color(0xff0E5A3B),
                      ),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xff0B4A30),
                    Color(0xff0E5A3B),
                    Color(0xff2E8B57),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: SizeConfig.heightPercent(8)),
                  // Profile Image
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildAvatar(),
                  ),
                  SizedBox(height: SizeConfig.scale(12)),
                  // Name
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      _employee!.fullName,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(24),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.scale(4)),
                  // Employee Code
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.scale(14),
                        vertical: SizeConfig.scale(5),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(
                          SizeConfig.scale(20),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: SizeConfig.scale(13),
                            color: Colors.white,
                          ),
                          SizedBox(width: SizeConfig.scale(6)),
                          Text(
                            _employee!.employeeCode,
                            style: TextStyle(
                              fontSize: SizeConfig.scaledFontSize(13),
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
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
                          color: _employee!.isActive
                              ? const Color(0xffDDF5E0)
                              : const Color(0xffFFE3E6),
                          borderRadius: BorderRadius.circular(
                            SizeConfig.scale(20),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: SizeConfig.scale(8),
                              height: SizeConfig.scale(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _employee!.isActive
                                    ? const Color(0xff0E5A3B)
                                    : const Color(0xffFF3B3B),
                              ),
                            ),
                            SizedBox(width: SizeConfig.scale(8)),
                            Text(
                              _employee!.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: SizeConfig.scaledFontSize(14),
                                color: _employee!.isActive
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

                    // Contact Information
                    _buildSectionTitle('Contact Information'),
                    SizedBox(height: SizeConfig.scale(12)),
                    _sectionCard([
                      _detailRow(
                        icon: Icons.phone_rounded,
                        iconColor: const Color(0xff0E5A3B),
                        label: 'Phone Number',
                        value: formatNepaliPhone(_employee!.phoneNumber),
                      ),
                      if (_employee!.email != null)
                        _detailRow(
                          icon: Icons.email_rounded,
                          iconColor: const Color(0xff0E5A3B),
                          label: 'Email',
                          value: _employee!.email!,
                        ),
                    ]),
                    SizedBox(height: SizeConfig.heightPercent(3)),

                    // Employment Details
                    _buildSectionTitle('Employment Details'),
                    SizedBox(height: SizeConfig.scale(12)),
                    _sectionCard([
                      _detailRow(
                        icon: Icons.badge_rounded,
                        iconColor: const Color(0xff6558FF),
                        label: 'Role',
                        value: _employee!.role,
                      ),
                      _detailRow(
                        icon: Icons.business_rounded,
                        iconColor: const Color(0xff6558FF),
                        label: 'Company ID',
                        value: _employee!.companyId,
                      ),
                      if (_employee!.managerId != null)
                        _detailRow(
                          icon: Icons.supervisor_account_rounded,
                          iconColor: const Color(0xff6558FF),
                          label: 'Manager ID',
                          value: _employee!.managerId!,
                        ),
                      _detailRow(
                        icon: Icons.calendar_today_rounded,
                        iconColor: const Color(0xff6558FF),
                        label: 'Joined Date',
                        value: _formatDate(_employee!.createdAt),
                      ),
                    ]),
                    SizedBox(height: SizeConfig.heightPercent(3)),

                    // ── Quick Actions ──────────────────────────
                    _buildSectionTitle('Quick Actions'),
                    SizedBox(height: SizeConfig.scale(12)),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.timeline_rounded,
                            label: 'Tracking\nHistory',
                            color: const Color(0xff0E5A3B),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TrackingHistoryScreen(
                                  employeeId: int.parse(widget.employeeId),
                                  employeeName: _employee!.fullName,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: SizeConfig.scale(12)),
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.location_on_rounded,
                            label: 'Live\nLocation',
                            color: const Color(0xff2980B9),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LiveMapScreen(
                                  focusEmployeeId: widget.employeeId,
                                  title: _employee!.fullName,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  /// Circular avatar with a white ring, soft shadow, an initials fallback
  /// and a live status dot (green when active, grey otherwise).
  Widget _buildAvatar() {
    final size = SizeConfig.scale(108);
    final img = _employee!.profileImage;

    final fallback = Container(
      color: const Color(0xffEAF4EF),
      alignment: Alignment.center,
      child: Text(
        _initials(),
        style: TextStyle(
          fontSize: SizeConfig.scaledFontSize(38),
          fontWeight: FontWeight.w800,
          color: const Color(0xff0E5A3B),
        ),
      ),
    );

    return ScaleTransition(
      scale: _avatarScale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: img != null
              ? Image.network(
                  img,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                )
              : fallback,
        ),
      ),
    );
  }

  String _initials() {
    final name = _employee!.fullName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// A white card that groups several [_detailRow]s, separated by thin
  /// dividers — cleaner than one card per field.
  Widget _sectionCard(List<Widget> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(
          Padding(
            padding: EdgeInsets.only(left: SizeConfig.scale(72)),
            child: const Divider(height: 1, color: Color(0xffF0ECE6)),
          ),
        );
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
        border: Border.all(color: const Color(0xffE8E3DD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.scale(16)),
      child: Row(
        children: [
          Container(
            width: SizeConfig.scale(44),
            height: SizeConfig.scale(44),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
            ),
            child: Icon(icon, color: iconColor, size: SizeConfig.scale(22)),
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
                SizedBox(height: SizeConfig.scale(3)),
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

  /// Bold gradient action tile (Tracking History / Live Location).
  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
        child: Container(
          padding: EdgeInsets.all(SizeConfig.scale(16)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, Color.lerp(color, Colors.black, 0.22)!],
            ),
            borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: SizeConfig.scale(44),
                height: SizeConfig.scale(44),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: SizeConfig.scale(24),
                ),
              ),
              SizedBox(height: SizeConfig.scale(14)),
              Text(
                label,
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(14),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),
              SizedBox(height: SizeConfig.scale(8)),
              Row(
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(11.5),
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  SizedBox(width: SizeConfig.scale(4)),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: SizeConfig.scale(15),
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
