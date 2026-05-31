import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/core/services/session.dart';
import 'package:fieldguard/core/utils/phone_format.dart';
import 'package:fieldguard/features/team/data/datasource/team_datasource_impl.dart';
import 'package:fieldguard/features/team/data/dto/employees_list_response.dart';
import 'package:fieldguard/features/live_tracking/presentation/screens/live_map_screen.dart';
import 'package:fieldguard/features/team/data/dto/live_employees_response.dart';
import 'package:fieldguard/features/team/data/dto/managers_list_response.dart';
import 'package:fieldguard/features/team/presentation/screens/employee_detail_screen.dart';
import 'package:fieldguard/features/team/presentation/screens/manager_detail_screen.dart';
import 'package:fieldguard/widgets/app_skeletons.dart';
import 'package:flutter/material.dart';

// ─── Brand palette (consistent with Profile / Login) ────────────────────────
const _kDark = Color(0xff072A1C);
const _kPrimary = Color(0xff0E5A3B);
const _kMid = Color(0xff1D7A51);
const _kSurface = Color(0xFFF8FAF9);
const _kBorder = Color(0xffE8E3DD);
const _kMuted = Color(0xff667085);

// Cap content to a comfortable phone width so it stays centred (instead of
// stretching edge-to-edge) on wide / landscape screens.
const double _kContentMaxWidth = 600;

/// Centres [child] and caps it to [_kContentMaxWidth] on wide screens.
Widget _centered(Widget child) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
    child: child,
  ),
);

// _s() is width-based (value * w/375). On a *landscape phone*
// the width doubles, so paddings/fonts double too — search bar + filter chips
// then no longer fit in the remaining tab body height. These helpers scale
// off the SHORTER side (so portrait phone behaves exactly like before, but
// landscape phone doesn't balloon).
double _s(double v) {
  final w = SizeConfig.screenWidth;
  final h = SizeConfig.screenHeight;
  final shorter = w < h ? w : h;
  return v * (shorter / 375);
}

double _sf(double v) {
  final scaled = _s(v);
  return scaled * SizeConfig.textScaleFactor.clamp(0.8, 1.3);
}

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  // A manager only manages employees — they never see the manager list, and
  // we must not hit the list-managers API for them (it's admin-only).
  bool _isManagerUser = false;
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
      final isManager = await Session.isManager();

      final dio = DioClient.createDio();
      final dataSource = TeamDataSourceImpl(dio);

      final employeesResponse = await dataSource.getEmployees();
      // Managers don't manage other managers — skip the admin-only
      // list-managers API entirely for them.
      final managersResponse = isManager
          ? null
          : await dataSource.getManagers();

      setState(() {
        _isManagerUser = isManager;
        _employees = employeesResponse.employees;
        _managers = managersResponse?.managers ?? const [];
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
        _onlineEmployees = response.employees.where((e) => e.online).toList();
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
        // Landscape phones are short — the header has to give up vertical
        // space (subtitle, padding) so the TabBarView still has room to lay
        // out its search bar + filter chips + list.
        final isLandscape = orientation == Orientation.landscape;
        return Scaffold(
          backgroundColor: _kSurface,
          body: _isLoading
              ? _buildLoadingView(isLandscape: isLandscape)
              : _errorMessage != null
              ? Column(
                  children: [
                    _buildGradientHeader(isLandscape: isLandscape),
                    Expanded(child: _buildErrorView()),
                  ],
                )
              : Column(
                  children: [
                    _buildGradientHeader(isLandscape: isLandscape),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [_buildMyTeamTab(), _buildLiveTeamTab()],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ─── Compact gradient header: title + pill tab bar ────────────────────────
  // (Team counts live on the Profile screen — we don't duplicate them here.)
  // In landscape we drop the subtitle and tighten paddings so the TabBarView
  // below still has room for its search bar, chips and list.
  Widget _buildGradientHeader({required bool isLandscape}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kDark, _kPrimary, _kMid],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative orbs
          Positioned(
            top: -30,
            right: -20,
            child: _orb(_s(isLandscape ? 90 : 130), 0.07),
          ),
          Positioned(
            bottom: 20,
            left: -30,
            child: _orb(_s(isLandscape ? 60 : 80), 0.05),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                _s(16),
                _s(isLandscape ? 2 : 6),
                _s(16),
                _s(isLandscape ? 8 : 14),
              ),
              child: _centered(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _sf(isLandscape ? 17 : 19),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.1,
                      ),
                    ),
                    // Subtitle only fits in portrait.
                    if (!isLandscape)
                      Text(
                        'Managers & employees',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: _sf(11.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    SizedBox(height: _s(isLandscape ? 8 : 16)),
                    _buildPillTabBar(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pill-style segmented tab bar (replaces the underline TabBar).
  Widget _buildPillTabBar() {
    return Container(
      padding: EdgeInsets.all(_s(4)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(_s(14)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_s(11)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: _kPrimary,
        unselectedLabelColor: Colors.white,
        labelStyle: TextStyle(fontSize: _sf(14), fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(
          fontSize: _sf(14),
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          const Tab(text: 'My Team'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: _s(8),
                  height: _s(8),
                  decoration: const BoxDecoration(
                    color: Color(0xff22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: _s(6)),
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
    );
  }

  Widget _orb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  Widget _buildLoadingView({required bool isLandscape}) {
    return Column(
      children: [
        _buildGradientHeader(isLandscape: isLandscape),
        const Expanded(child: SkeletonList()),
      ],
    );
  }

  // ─── My Team: search + filter + full directory ────────────────────────────
  Widget _buildMyTeamTab() {
    return _centered(
      Column(
        children: [
          _searchAndFilterArea(
            searchController: _myTeamSearchController,
            searchQuery: _myTeamQuery,
            onSearchChanged: (value) => setState(() => _myTeamQuery = value),
            onSearchClear: () {
              _myTeamSearchController.clear();
              setState(() => _myTeamQuery = '');
              FocusScope.of(context).unfocus();
            },
            filterSelected: _myTeamFilter,
            onFilterSelect: (value) => setState(() => _myTeamFilter = value),
          ),
          Expanded(child: _buildMyTeamContent()),
        ],
      ),
    );
  }

  // Search bar + filter chips. Stacked vertically in portrait, side-by-side
  // in landscape so the list still gets enough vertical room.
  Widget _searchAndFilterArea({
    required TextEditingController searchController,
    required String searchQuery,
    required ValueChanged<String> onSearchChanged,
    required VoidCallback onSearchClear,
    required String filterSelected,
    required ValueChanged<String> onFilterSelect,
  }) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final search = _searchBar(
      controller: searchController,
      query: searchQuery,
      hint: 'Search by name or code',
      onChanged: onSearchChanged,
      onClear: onSearchClear,
    );
    final filter = _filterBar(
      selected: filterSelected,
      onSelect: onFilterSelect,
    );

    if (!isLandscape) {
      return Column(children: [search, filter]);
    }

    // Landscape: search expands, filter chips scroll horizontally beside it.
    // Manager users don't see filter chips
    if (_isManagerUser) {
      return Padding(
        padding: EdgeInsets.fromLTRB(_s(16), _s(8), _s(16), _s(6)),
        child: _searchFieldInline(
          controller: searchController,
          query: searchQuery,
          onChanged: onSearchChanged,
          onClear: onSearchClear,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(_s(16), _s(8), _s(16), _s(6)),
      child: Row(
        children: [
          Expanded(
            child: _searchFieldInline(
              controller: searchController,
              query: searchQuery,
              onChanged: onSearchChanged,
              onClear: onSearchClear,
            ),
          ),
          SizedBox(width: _s(10)),
          _filterChip('All', 'all', filterSelected, onFilterSelect),
          SizedBox(width: _s(6)),
          _filterChip('Mgr', 'managers', filterSelected, onFilterSelect),
          SizedBox(width: _s(6)),
          _filterChip('Emp', 'employees', filterSelected, onFilterSelect),
        ],
      ),
    );
  }

  // The bare search field used inside the inline landscape row (no outer
  // padding — that's handled by the row itself).
  Widget _searchFieldInline({
    required TextEditingController controller,
    required String query,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_s(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(fontSize: _sf(13.5)),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search by name or code',
          hintStyle: TextStyle(fontSize: _sf(13.5), color: _kMuted),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: _s(20),
            color: _kPrimary,
          ),
          suffixIcon: query.isEmpty
              ? null
              : GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.close_rounded,
                    size: _s(17),
                    color: _kMuted,
                  ),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: _s(10)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_s(12)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_s(12)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_s(12)),
            borderSide: const BorderSide(color: _kPrimary, width: 1.5),
          ),
        ),
      ),
    );
  }

  List<ManagerItem> get _filteredManagers {
    final q = _myTeamQuery.trim().toLowerCase();
    if (q.isEmpty) return _managers;
    return _managers
        .where(
          (m) =>
              m.fullName.toLowerCase().contains(q) ||
              m.managerCode.toLowerCase().contains(q),
        )
        .toList();
  }

  List<EmployeeItem> get _filteredTeamEmployees {
    final q = _myTeamQuery.trim().toLowerCase();
    if (q.isEmpty) return _employees;
    return _employees
        .where(
          (e) =>
              e.fullName.toLowerCase().contains(q) ||
              e.employeeCode.toLowerCase().contains(q),
        )
        .toList();
  }

  Widget _buildMyTeamContent() {
    final showManagers = _myTeamFilter == 'all' || _myTeamFilter == 'managers';
    final showEmployees =
        _myTeamFilter == 'all' || _myTeamFilter == 'employees';
    final managers = showManagers ? _filteredManagers : const <ManagerItem>[];
    final employees = showEmployees
        ? _filteredTeamEmployees
        : const <EmployeeItem>[];

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
        padding: EdgeInsets.all(_s(16)),
        itemCount: managers.length + employees.length,
        itemBuilder: (context, index) {
          final card = index < managers.length
              ? _buildManagerCard(managers[index])
              : _buildEmployeeCard(employees[index - managers.length]);
          return _AnimatedEntry(index: index, child: card);
        },
      ),
    );
  }

  // ─── Live Team: search + filter + live list ───────────────────────────────
  Widget _buildLiveTeamTab() {
    return _centered(
      Column(
        children: [
          _searchAndFilterArea(
            searchController: _onlineSearchController,
            searchQuery: _onlineQuery,
            onSearchChanged: (value) => setState(() => _onlineQuery = value),
            onSearchClear: () {
              _onlineSearchController.clear();
              setState(() => _onlineQuery = '');
              FocusScope.of(context).unfocus();
            },
            filterSelected: _liveFilter,
            onFilterSelect: (value) => setState(() => _liveFilter = value),
          ),
          Expanded(child: _buildLiveTeamContent()),
        ],
      ),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(_s(16), _s(16), _s(16), _s(10)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_s(14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(fontSize: _sf(14)),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(fontSize: _sf(14), color: _kMuted),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: _s(21),
              color: _kPrimary,
            ),
            suffixIcon: query.isEmpty
                ? null
                : GestureDetector(
                    onTap: onClear,
                    child: Icon(
                      Icons.close_rounded,
                      size: _s(18),
                      color: _kMuted,
                    ),
                  ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(vertical: _s(14)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_s(14)),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_s(14)),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_s(14)),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
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
    // Manager users don't see any filter chips
    if (_isManagerUser) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(_s(16), _s(2), _s(16), _s(10)),
      child: Row(
        children: [
          _filterChip('All', 'all', selected, onSelect),
          SizedBox(width: _s(8)),
          _filterChip('Managers', 'managers', selected, onSelect),
          SizedBox(width: _s(8)),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: _s(18), vertical: _s(9)),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [_kPrimary, _kMid])
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(_s(20)),
          border: Border.all(color: selected ? Colors.transparent : _kBorder),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: _sf(13),
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _kMuted,
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
        padding: EdgeInsets.all(_s(16)),
        itemCount: 6,
        itemBuilder: (_, index) =>
            _AnimatedEntry(index: index, child: _buildLiveSkeletonCard()),
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
        padding: EdgeInsets.all(_s(16)),
        itemCount: list.length,
        itemBuilder: (context, index) =>
            _AnimatedEntry(index: index, child: _buildLiveCard(list[index])),
      ),
    );
  }

  // Shared empty / error placeholder used across both tabs.
  Widget _buildMessageState({
    required IconData icon,
    required String message,
    VoidCallback? onRetry,
  }) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Center(
        child: _AnimatedEntry(
          index: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: _s(40)),
              Container(
                width: _s(96),
                height: _s(96),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: _s(46),
                  color: _kPrimary.withValues(alpha: 0.55),
                ),
              ),
              SizedBox(height: SizeConfig.heightPercent(2)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: _s(32)),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _sf(15),
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
                      horizontal: _s(28),
                      vertical: _s(10),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
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
            builder: (_) =>
                LiveMapScreen(focusEmployeeId: item.employee.id, title: name),
          ),
        );
      },
      child: _memberCardShell(
        child: Row(
          children: [
            _avatar(
              imageUrl: null,
              fallbackText: _initials(name),
              gradient: const [_kPrimary, _kMid],
              badge: Container(
                width: _s(16),
                height: _s(16),
                decoration: BoxDecoration(
                  color: const Color(0xff22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
              ),
            ),
            SizedBox(width: _s(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _sf(16),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff111111),
                    ),
                  ),
                  SizedBox(height: _s(6)),
                  Row(
                    children: [
                      _codePill(code, _kPrimary),
                      SizedBox(width: _s(8)),
                      _livePill(),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: _s(8)),
            _chevron(),
          ],
        ),
      ),
    );
  }

  // Animated "Live" pill with a soft pulsing dot.
  Widget _livePill() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _s(9), vertical: _s(4)),
      decoration: BoxDecoration(
        color: const Color(0xff22C55E).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(_s(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _s(6),
            height: _s(6),
            decoration: const BoxDecoration(
              color: Color(0xff16A34A),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: _s(5)),
          Text(
            'Live',
            style: TextStyle(
              fontSize: _sf(11),
              color: const Color(0xff16A34A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveSkeletonCard() {
    return Container(
      margin: EdgeInsets.only(bottom: _s(12)),
      padding: EdgeInsets.all(_s(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_s(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: AppShimmer(
        child: Row(
          children: [
            Container(
              width: _s(54),
              height: _s(54),
              decoration: BoxDecoration(
                color: const Color(0xffE8E3DD),
                borderRadius: BorderRadius.circular(_s(16)),
              ),
            ),
            SizedBox(width: _s(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: _s(140),
                    height: _s(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffE8E3DD),
                      borderRadius: BorderRadius.circular(_s(4)),
                    ),
                  ),
                  SizedBox(height: _s(8)),
                  Container(
                    width: _s(80),
                    height: _s(10),
                    decoration: BoxDecoration(
                      color: const Color(0xffE8E3DD),
                      borderRadius: BorderRadius.circular(_s(4)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          Icon(Icons.error_outline, size: _s(60), color: Colors.red),
          SizedBox(height: SizeConfig.heightPercent(2)),
          Text(
            _errorMessage!,
            style: TextStyle(fontSize: _sf(16), color: const Color(0xff667085)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.heightPercent(3)),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff0E5A3B),
              padding: EdgeInsets.symmetric(
                horizontal: _s(32),
                vertical: _s(12),
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
      child: _memberCardShell(
        child: Row(
          children: [
            _avatar(
              imageUrl: manager.profileImage,
              fallbackText: _initials(manager.fullName),
              gradient: const [Color(0xff6558FF), Color(0xff8B3DFF)],
            ),
            SizedBox(width: _s(14)),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manager.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _sf(16),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff111111),
                    ),
                  ),
                  SizedBox(height: _s(5)),
                  Row(
                    children: [
                      _codePill(manager.managerCode, const Color(0xff6558FF)),
                      SizedBox(width: _s(6)),
                      Flexible(
                        child: Text(
                          formatNepaliPhone(manager.phoneNumber),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: _sf(12.5), color: _kMuted),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _s(8)),
                  Row(
                    children: [
                      _statusPill(manager.isActive),
                      SizedBox(width: _s(8)),
                      Icon(
                        Icons.assignment_ind_outlined,
                        size: _s(14),
                        color: _kMuted,
                      ),
                      SizedBox(width: _s(3)),
                      Flexible(
                        child: Text(
                          '${manager.assignedCount} assigned',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: _sf(12),
                            color: _kMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: _s(8)),
            _chevron(),
          ],
        ),
      ),
    );
  }

  // ─── Shared card building blocks ──────────────────────────────────────────

  Widget _memberCardShell({required Widget child}) {
    return Container(
      margin: EdgeInsets.only(bottom: _s(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_s(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: EdgeInsets.all(_s(14)), child: child),
    );
  }

  Widget _avatar({
    required String? imageUrl,
    required String fallbackText,
    required List<Color> gradient,
    Widget? badge,
  }) {
    final size = _s(54);
    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_s(16)),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(_s(16)),
              child: Image.network(
                imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Text(
                  fallbackText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _sf(19),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          : Text(
              fallbackText,
              style: TextStyle(
                color: Colors.white,
                fontSize: _sf(19),
                fontWeight: FontWeight.w700,
              ),
            ),
    );

    if (badge == null) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(right: -2, bottom: -2, child: badge),
      ],
    );
  }

  Widget _codePill(String code, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _s(7), vertical: _s(2)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_s(6)),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontSize: _sf(11.5),
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statusPill(bool active) {
    final color = active ? _kPrimary : const Color(0xffFF3B3B);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _s(9), vertical: _s(4)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_s(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _s(6),
            height: _s(6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: _s(5)),
          Text(
            active ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: _sf(11),
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chevron() {
    return Container(
      width: _s(30),
      height: _s(30),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_s(10)),
      ),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        size: _s(13),
        color: _kMuted,
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
      child: _memberCardShell(
        child: Row(
          children: [
            _avatar(
              imageUrl: employee.profileImage,
              fallbackText: _initials(employee.fullName),
              gradient: const [_kPrimary, _kMid],
            ),
            SizedBox(width: _s(14)),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _sf(16),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff111111),
                    ),
                  ),
                  SizedBox(height: _s(5)),
                  Row(
                    children: [
                      _codePill(employee.employeeCode, _kPrimary),
                      SizedBox(width: _s(6)),
                      Flexible(
                        child: Text(
                          formatNepaliPhone(employee.phoneNumber),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: _sf(12.5), color: _kMuted),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _s(8)),
                  _statusPill(employee.isActive),
                ],
              ),
            ),
            SizedBox(width: _s(8)),
            _chevron(),
          ],
        ),
      ),
    );
  }
}

/// Fades + slides its child up on first build, with a small per-index delay so
/// list items cascade in one after another instead of all at once.
class _AnimatedEntry extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedEntry({required this.index, required this.child});

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Cap the stagger so long lists don't take forever to finish appearing.
    final delayMs = (widget.index.clamp(0, 8)) * 70;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
