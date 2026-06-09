import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/services/session.dart';
import 'package:fieldguard/core/theme/app_colors.dart';
import 'package:fieldguard/features/team/data/datasource/team_datasource_impl.dart';
import 'package:fieldguard/features/team/data/dto/employees_list_response.dart';
import 'package:fieldguard/features/team/data/dto/managers_list_response.dart';
import 'package:flutter/material.dart';

/// Role-aware "who can see this shop" picker, used by the shop edit form (and
/// reusable by create). Loads the current user's grantable team, lets them
/// multi-select, and reports the result via [onChanged]:
///
///  - `null`         → not applicable (current user is an EMPLOYEE). The caller
///                     should OMIT `visibleTo` from the request (no change).
///  - a list (maybe empty) → ADMIN/MANAGER selection. The caller sends it as
///                     `visibleTo` (full replace within scope; `[]` clears).
///
/// [initialSelected] pre-fills the selection; any id outside the current user's
/// scope is dropped so a save never 400s on an out-of-scope id.
class ShopVisibilityField extends StatefulWidget {
  final Set<int> initialSelected;
  final ValueChanged<List<int>?> onChanged;

  const ShopVisibilityField({
    super.key,
    this.initialSelected = const {},
    required this.onChanged,
  });

  @override
  State<ShopVisibilityField> createState() => _ShopVisibilityFieldState();
}

class _ShopVisibilityFieldState extends State<ShopVisibilityField> {
  String? _role;
  bool _isLoadingTeam = false;
  List<ManagerItem> _managers = const [];
  List<EmployeeItem> _employees = const [];
  final Set<int> _selected = <int>{};

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialSelected);
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    final role = await Session.role();
    final normalized = role?.toLowerCase();
    if (!mounted) return;

    if (normalized == 'employee') {
      setState(() => _role = role);
      widget.onChanged(null); // not applicable -> caller omits visibleTo
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
      final managers =
          normalized == 'admin' ? await dataSource.getManagers() : null;
      if (!mounted) return;
      setState(() {
        _employees = employees.employees;
        _managers = managers?.managers ?? const [];
        _isLoadingTeam = false;
        // Keep only pre-selected ids within this user's scope (else a save
        // would 400 on an out-of-scope id).
        final available = <int>{
          for (final m in _managers) int.tryParse(m.id) ?? -1,
          for (final e in _employees) int.tryParse(e.id) ?? -1,
        };
        _selected.retainWhere(available.contains);
      });
      widget.onChanged(_selected.toList());
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingTeam = false);
      widget.onChanged(_selected.toList());
    }
  }

  Future<void> _openPicker() async {
    final updated = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VisibilityPicker(
        managers: _managers,
        employees: _employees,
        initial: Set.of(_selected),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _selected
          ..clear()
          ..addAll(updated);
      });
      widget.onChanged(_selected.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Employees can't grant visibility — render nothing.
    if (_role == null || _role!.toLowerCase() == 'employee') {
      return const SizedBox.shrink();
    }

    final total = _managers.length + _employees.length;
    final selected = _selected.length;
    final String summary;
    if (_isLoadingTeam) {
      summary = 'Loading team…';
    } else if (total == 0) {
      summary = 'No teammates available';
    } else if (selected == 0) {
      summary = 'Only the default hierarchy can see this shop';
    } else {
      summary = '$selected selected';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Shared With (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _isLoadingTeam || total == 0 ? null : _openPicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
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
                      color: selected > 0 ? AppColors.ink : AppColors.grey,
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
                        strokeWidth: 2, color: AppColors.green),
                  )
                else
                  const Icon(Icons.chevron_right,
                      color: AppColors.grey2, size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Picker bottom sheet ─────────────────────────────────────────────────────

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

  void _toggle(int? id) {
    if (id == null) return;
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
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
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search by name or code',
                    hintStyle:
                        const TextStyle(color: AppColors.grey2, fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.grey2, size: 20),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                  ),
                ),
              ),
              Expanded(
                child: managers.isEmpty && employees.isEmpty
                    ? const Center(
                        child: Text(
                          'No matches found',
                          style: TextStyle(fontSize: 14, color: AppColors.grey),
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
                                  onTap: () => _toggle(int.tryParse(m.id)),
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
                                  onTap: () => _toggle(int.tryParse(e.id)),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.green6 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.green : AppColors.grey4,
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
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppColors.green : AppColors.grey4,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
