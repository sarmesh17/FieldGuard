import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/features/team/data/datasource/team_datasource_impl.dart';
import 'package:fieldguard/features/team/data/dto/employees_list_response.dart';
import 'package:fieldguard/features/team/data/dto/managers_list_response.dart';
import 'package:fieldguard/features/team/presentation/screens/employee_detail_screen.dart';
import 'package:fieldguard/features/team/presentation/screens/manager_detail_screen.dart';
import 'package:flutter/material.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<EmployeeItem> _employees = [];
  List<ManagerItem> _managers = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = DioClient.createDio();
      final dataSource = TeamDataSourceImpl(dio);

      final employeesResponse = await dataSource.getEmployees();
      final managersResponse = await dataSource.getManagers();

      setState(() {
        _employees = employeesResponse.employees;
        _managers = managersResponse.managers;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _errorMessage = _extractErrorMessage(e);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load team data';
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
    return 'Failed to load team data';
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
            title: const Text(
              'Team Management',
              style: TextStyle(
                color: Color(0xff111111),
                fontWeight: FontWeight.w700,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xff0E5A3B),
                    unselectedLabelColor: const Color(0xff667085),
                    indicatorColor: const Color(0xff0E5A3B),
                    indicatorWeight: 3,
                    labelStyle: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(15),
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: [
                      Tab(
                        text: 'Managers (${_managers.length})',
                      ),
                      Tab(
                        text: 'Employees (${_employees.length})',
                      ),
                    ],
                  ),
                  Container(
                    height: 1,
                    color: const Color(0xffE8E3DD),
                  ),
                ],
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _buildErrorView()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildManagersList(),
                        _buildEmployeesList(),
                      ],
                    ),
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
            onPressed: _loadData,
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

  Widget _buildManagersList() {
    if (_managers.isEmpty) {
      return _buildEmptyState('No managers found', Icons.supervisor_account);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(SizeConfig.scale(16)),
        itemCount: _managers.length,
        itemBuilder: (context, index) {
          final manager = _managers[index];
          return _buildManagerCard(manager);
        },
      ),
    );
  }

  Widget _buildEmployeesList() {
    if (_employees.isEmpty) {
      return _buildEmptyState('No employees found', Icons.person);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(SizeConfig.scale(16)),
        itemCount: _employees.length,
        itemBuilder: (context, index) {
          final employee = _employees[index];
          return _buildEmployeeCard(employee);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: SizeConfig.scale(80),
            color: const Color(0xffE8E3DD),
          ),
          SizedBox(height: SizeConfig.heightPercent(2)),
          Text(
            message,
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(16),
              color: const Color(0xff667085),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerCard(ManagerItem manager) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManagerDetailScreen(
              managerId: manager.id,
              managerName: manager.fullName,
            ),
          ),
        );
        
        // Reload list if manager was deleted or updated
        if (result == true) {
          _loadData();
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.scale(12)),
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
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.scale(16)),
          child: Row(
            children: [
              // Avatar
              Container(
                width: SizeConfig.scale(56),
                height: SizeConfig.scale(56),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xff6558FF), Color(0xff8B3DFF)],
                  ),
                ),
                child: manager.profileImage != null
                    ? ClipOval(
                        child: Image.network(
                          manager.profileImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            color: Colors.white,
                            size: SizeConfig.scale(28),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: Colors.white,
                        size: SizeConfig.scale(28),
                      ),
              ),
              SizedBox(width: SizeConfig.scale(12)),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manager.fullName,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(16),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xff111111),
                      ),
                    ),
                    SizedBox(height: SizeConfig.scale(4)),
                    Text(
                      manager.managerCode,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(13),
                        color: const Color(0xff6558FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: SizeConfig.scale(4)),
                    Text(
                      manager.phoneNumber,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(13),
                        color: const Color(0xff667085),
                      ),
                    ),
                  ],
                ),
              ),
              // Status and Arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.scale(8),
                      vertical: SizeConfig.scale(4),
                    ),
                    decoration: BoxDecoration(
                      color: manager.isActive
                          ? const Color(0xffDDF5E0)
                          : const Color(0xffFFE3E6),
                      borderRadius: BorderRadius.circular(SizeConfig.scale(4)),
                    ),
                    child: Text(
                      manager.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(11),
                        color: manager.isActive
                            ? const Color(0xff0E5A3B)
                            : const Color(0xffFF3B3B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.scale(4)),
                  Text(
                    '${manager.assignedCount} assigned',
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(12),
                      color: const Color(0xff667085),
                    ),
                  ),
                  SizedBox(height: SizeConfig.scale(4)),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: SizeConfig.scale(16),
                    color: const Color(0xff667085),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeItem employee) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmployeeDetailScreen(
              employeeId: employee.id,
              employeeName: employee.fullName,
            ),
          ),
        );
        
        // Reload list if employee was deleted or updated
        if (result == true) {
          _loadData();
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.scale(12)),
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
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.scale(16)),
          child: Row(
            children: [
              // Avatar
              Container(
                width: SizeConfig.scale(56),
                height: SizeConfig.scale(56),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xff0E5A3B), Color(0xff2E6F4F)],
                  ),
                ),
                child: employee.profileImage != null
                    ? ClipOval(
                        child: Image.network(
                          employee.profileImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            color: Colors.white,
                            size: SizeConfig.scale(28),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: Colors.white,
                        size: SizeConfig.scale(28),
                      ),
              ),
              SizedBox(width: SizeConfig.scale(12)),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(16),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xff111111),
                      ),
                    ),
                    SizedBox(height: SizeConfig.scale(4)),
                    Text(
                      employee.employeeCode,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(13),
                        color: const Color(0xff0E5A3B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: SizeConfig.scale(4)),
                    Text(
                      employee.phoneNumber,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(13),
                        color: const Color(0xff667085),
                      ),
                    ),
                  ],
                ),
              ),
              // Status and Arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.scale(8),
                      vertical: SizeConfig.scale(4),
                    ),
                    decoration: BoxDecoration(
                      color: employee.isActive
                          ? const Color(0xffDDF5E0)
                          : const Color(0xffFFE3E6),
                      borderRadius: BorderRadius.circular(SizeConfig.scale(4)),
                    ),
                    child: Text(
                      employee.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(11),
                        color: employee.isActive
                            ? const Color(0xff0E5A3B)
                            : const Color(0xffFF3B3B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.scale(8)),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: SizeConfig.scale(16),
                    color: const Color(0xff667085),
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
