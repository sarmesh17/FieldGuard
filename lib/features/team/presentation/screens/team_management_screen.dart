import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/features/team/data/datasource/team_datasource_impl.dart';
import 'package:fieldguard/features/team/data/dto/employees_list_response.dart';
import 'package:fieldguard/features/live_tracking/presentation/screens/live_map_screen.dart';
import 'package:fieldguard/features/team/data/dto/live_employees_response.dart';
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

  // The "Online" tab loads independently so a live-endpoint failure never
  // blocks the main team lists.
  List<LiveEmployeeItem> _onlineEmployees = [];
  bool _onlineLoading = true;
  bool _onlineError = false;
  final TextEditingController _onlineSearchController = TextEditingController();
  String _onlineQuery = '';
  String _liveFilter = 'all'; // 'all' | 'managers' | 'employees'

  // "My Team" tab uses the same search + filter pattern as Live Team.
  final TextEditingController _myTeamSearchController = TextEditingController();
  String _myTeamQuery = '';
  String _myTeamFilter = 'all'; // 'all' | 'managers' | 'employees'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _myTeamSearchController.dispose();
    _onlineSearchController.dispose();
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
      _loadOnlineEmployees();
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

  Future<void> _loadOnlineEmployees() async {
    setState(() {
      _onlineLoading = true;
      _onlineError = false;
    });

    try {
      final dio = DioClient.createDio();
      final dataSource = TeamDataSourceImpl(dio);
      final response = await dataSource.getLiveEmployees();

      if (!mounted) return;
      setState(() {
        _onlineEmployees =
            response.employees.where((e) => e.online).toList();
        _onlineLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _onlineError = true;
        _onlineLoading = false;
      });
    }
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
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _buildErrorView()
                  : Column(
                      children: [
                        _buildTabBarSection(),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildMyTeamTab(),
                              _buildLiveTeamTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildTabBarSection() {
    return Container(
      color: Colors.white,
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
              const Tab(text: 'My Team'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: SizeConfig.scale(8),
                      height: SizeConfig.scale(8),
                      decoration: const BoxDecoration(
                        color: Color(0xff22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: SizeConfig.scale(6)),
                    Text(
                      _onlineLoading
                          ? 'Live Team'
                          : 'Live Team (${_onlineEmployees.length})',
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(height: 1, color: const Color(0xffE8E3DD)),
        ],
      ),
    );
  }

  // ─── My Team: search + filter + full directory ────────────────────────────
  Widget _buildMyTeamTab() {
    return Column(
      children: [
        _searchBar(
          controller: _myTeamSearchController,
          query: _myTeamQuery,
          hint: 'Search by name or code',
          onChanged: (value) => setState(() => _myTeamQuery = value),
          onClear: () {
            _myTeamSearchController.clear();
            setState(() => _myTeamQuery = '');
            FocusScope.of(context).unfocus();
          },
        ),
        _filterBar(
          selected: _myTeamFilter,
          onSelect: (value) => setState(() => _myTeamFilter = value),
        ),
        Expanded(child: _buildMyTeamContent()),
      ],
    );
  }

  List<ManagerItem> get _filteredManagers {
    final q = _myTeamQuery.trim().toLowerCase();
    if (q.isEmpty) return _managers;
    return _managers
        .where((m) =>
            m.fullName.toLowerCase().contains(q) ||
            m.managerCode.toLowerCase().contains(q))
        .toList();
  }

  List<EmployeeItem> get _filteredTeamEmployees {
    final q = _myTeamQuery.trim().toLowerCase();
    if (q.isEmpty) return _employees;
    return _employees
        .where((e) =>
            e.fullName.toLowerCase().contains(q) ||
            e.employeeCode.toLowerCase().contains(q))
        .toList();
  }

  Widget _buildMyTeamContent() {
    final showManagers = _myTeamFilter == 'all' || _myTeamFilter == 'managers';
    final showEmployees =
        _myTeamFilter == 'all' || _myTeamFilter == 'employees';
    final managers = showManagers ? _filteredManagers : const <ManagerItem>[];
    final employees =
        showEmployees ? _filteredTeamEmployees : const <EmployeeItem>[];

    if (managers.isEmpty && employees.isEmpty) {
      final searching = _myTeamQuery.trim().isNotEmpty;
      return _buildMessageState(
        icon: searching ? Icons.search_off : Icons.groups_outlined,
        message: searching
            ? 'No team member matches "${_myTeamQuery.trim()}"'
            : 'No team members found',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(SizeConfig.scale(16)),
        itemCount: managers.length + employees.length,
        itemBuilder: (context, index) {
          if (index < managers.length) {
            return _buildManagerCard(managers[index]);
          }
          return _buildEmployeeCard(employees[index - managers.length]);
        },
      ),
    );
  }

  // ─── Live Team: search + filter + live list ───────────────────────────────
  Widget _buildLiveTeamTab() {
    return Column(
      children: [
        _searchBar(
          controller: _onlineSearchController,
          query: _onlineQuery,
          hint: 'Search by name or code',
          onChanged: (value) => setState(() => _onlineQuery = value),
          onClear: () {
            _onlineSearchController.clear();
            setState(() => _onlineQuery = '');
            FocusScope.of(context).unfocus();
          },
        ),
        _filterBar(
          selected: _liveFilter,
          onSelect: (value) => setState(() => _liveFilter = value),
        ),
        Expanded(child: _buildLiveTeamContent()),
      ],
    );
  }

  // Shared search field — used by both the My Team and Live Team tabs.
  Widget _searchBar({
    required TextEditingController controller,
    required String query,
    required String hint,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        SizeConfig.scale(16),
        SizeConfig.scale(12),
        SizeConfig.scale(16),
        SizeConfig.scale(8),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(fontSize: SizeConfig.scaledFontSize(14)),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: SizeConfig.scaledFontSize(14),
            color: const Color(0xff667085),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: SizeConfig.scale(20),
            color: const Color(0xff667085),
          ),
          suffixIcon: query.isEmpty
              ? null
              : GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.close,
                    size: SizeConfig.scale(18),
                    color: const Color(0xff667085),
                  ),
                ),
          filled: true,
          fillColor: const Color(0xffF8FAF9),
          contentPadding:
              EdgeInsets.symmetric(vertical: SizeConfig.scale(12)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SizeConfig.scale(10)),
            borderSide: const BorderSide(color: Color(0xffE8E3DD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SizeConfig.scale(10)),
            borderSide: const BorderSide(color: Color(0xffE8E3DD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SizeConfig.scale(10)),
            borderSide: const BorderSide(color: Color(0xff0E5A3B)),
          ),
        ),
      ),
    );
  }

  // Shared All / Managers / Employees filter chips.
  Widget _filterBar({
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        SizeConfig.scale(16),
        SizeConfig.scale(4),
        SizeConfig.scale(16),
        SizeConfig.scale(12),
      ),
      child: Row(
        children: [
          _filterChip('All', 'all', selected, onSelect),
          SizedBox(width: SizeConfig.scale(8)),
          _filterChip('Managers', 'managers', selected, onSelect),
          SizedBox(width: SizeConfig.scale(8)),
          _filterChip('Employees', 'employees', selected, onSelect),
        ],
      ),
    );
  }

  Widget _filterChip(
    String label,
    String value,
    String selectedValue,
    ValueChanged<String> onSelect,
  ) {
    final selected = selectedValue == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.scale(16),
          vertical: SizeConfig.scale(8),
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff0E5A3B) : const Color(0xffF1F4F2),
          borderRadius: BorderRadius.circular(SizeConfig.scale(20)),
          border: Border.all(
            color:
                selected ? const Color(0xff0E5A3B) : const Color(0xffE8E3DD),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: SizeConfig.scaledFontSize(13),
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xff667085),
          ),
        ),
      ),
    );
  }

  /// Online employees after applying the filter chip + search query.
  ///
  /// The "Managers" filter has no data yet — live tracking for managers
  /// will be added when `/api/v1/managers/live` lands (see TeamDataSource).
  List<LiveEmployeeItem> get _filteredLiveEmployees {
    if (_liveFilter == 'managers') return const [];
    final q = _onlineQuery.trim().toLowerCase();
    if (q.isEmpty) return _onlineEmployees;
    return _onlineEmployees.where((e) {
      final name = e.employee.fullName.toLowerCase();
      final code = e.employee.employeeCode.toLowerCase();
      return name.contains(q) || code.contains(q);
    }).toList();
  }

  Widget _buildLiveTeamContent() {
    if (_onlineLoading) {
      return ListView.builder(
        padding: EdgeInsets.all(SizeConfig.scale(16)),
        itemCount: 6,
        itemBuilder: (_, _) => _buildLiveSkeletonCard(),
      );
    }

    if (_onlineError) {
      return _buildMessageState(
        icon: Icons.wifi_off,
        message: "Couldn't load the live team",
        onRetry: _loadOnlineEmployees,
      );
    }

    if (_liveFilter == 'managers') {
      return _buildMessageState(
        icon: Icons.supervisor_account_outlined,
        message:
            'Live tracking for managers is coming soon.\nSwitch to All or Employees.',
      );
    }

    if (_onlineEmployees.isEmpty) {
      return _buildMessageState(
        icon: Icons.cloud_off,
        message: 'No one is online right now',
      );
    }

    final list = _filteredLiveEmployees;
    if (list.isEmpty) {
      return _buildMessageState(
        icon: Icons.search_off,
        message: 'No live member matches "${_onlineQuery.trim()}"',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOnlineEmployees,
      child: ListView.builder(
        padding: EdgeInsets.all(SizeConfig.scale(16)),
        itemCount: list.length,
        itemBuilder: (context, index) => _buildLiveCard(list[index]),
      ),
    );
  }

  // Shared empty / error placeholder used across both tabs.
  Widget _buildMessageState({
    required IconData icon,
    required String message,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: SizeConfig.scale(64),
            color: const Color(0xffE8E3DD),
          ),
          SizedBox(height: SizeConfig.heightPercent(2)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.scale(32)),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: SizeConfig.scaledFontSize(15),
                color: const Color(0xff667085),
              ),
            ),
          ),
          if (onRetry != null) ...[
            SizedBox(height: SizeConfig.heightPercent(2)),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0E5A3B),
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.scale(28),
                  vertical: SizeConfig.scale(10),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveCard(LiveEmployeeItem item) {
    final name = item.employee.fullName;
    final code = item.employee.employeeCode;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveMapScreen(
              focusEmployeeId: item.employee.id,
              title: name,
            ),
          ),
        );
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
              Stack(
                children: [
                  Container(
                    width: SizeConfig.scale(56),
                    height: SizeConfig.scale(56),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xff0E5A3B), Color(0xff2E6F4F)],
                      ),
                    ),
                    child: Text(
                      _initials(name),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: SizeConfig.scaledFontSize(20),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: SizeConfig.scale(16),
                      height: SizeConfig.scale(16),
                      decoration: BoxDecoration(
                        color: const Color(0xff22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: SizeConfig.scale(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(16),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xff111111),
                      ),
                    ),
                    SizedBox(height: SizeConfig.scale(4)),
                    Text(
                      code,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(13),
                        color: const Color(0xff0E5A3B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.scale(8),
                      vertical: SizeConfig.scale(4),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffDDF5E0),
                      borderRadius: BorderRadius.circular(SizeConfig.scale(4)),
                    ),
                    child: Text(
                      'Live',
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(11),
                        color: const Color(0xff0E5A3B),
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

  Widget _buildLiveSkeletonCard() {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.scale(12)),
      padding: EdgeInsets.all(SizeConfig.scale(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
        border: Border.all(color: const Color(0xffE8E3DD)),
      ),
      child: Row(
        children: [
          Container(
            width: SizeConfig.scale(56),
            height: SizeConfig.scale(56),
            decoration: const BoxDecoration(
              color: Color(0xffE8E3DD),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: SizeConfig.scale(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: SizeConfig.scale(140),
                  height: SizeConfig.scale(12),
                  decoration: BoxDecoration(
                    color: const Color(0xffE8E3DD),
                    borderRadius: BorderRadius.circular(SizeConfig.scale(4)),
                  ),
                ),
                SizedBox(height: SizeConfig.scale(8)),
                Container(
                  width: SizeConfig.scale(80),
                  height: SizeConfig.scale(10),
                  decoration: BoxDecoration(
                    color: const Color(0xffE8E3DD),
                    borderRadius: BorderRadius.circular(SizeConfig.scale(4)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
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
