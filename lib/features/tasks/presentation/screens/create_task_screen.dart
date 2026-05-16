import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/features/shops/data/datasource/shops_datasource_impl.dart';
import 'package:fieldguard/features/shops/data/dto/shops_hierarchy_response.dart';
import 'package:fieldguard/features/tasks/data/datasource/task_datasource_impl.dart';
import 'package:fieldguard/features/tasks/data/dto/create_task_request.dart';
import 'package:fieldguard/features/team/data/datasource/team_datasource_impl.dart';
import 'package:fieldguard/features/team/data/dto/employees_list_response.dart';
import 'package:fieldguard/features/team/data/dto/managers_list_response.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateTaskScreen extends StatefulWidget {
  final int? shopId;
  final double? shopLatitude;
  final double? shopLongitude;

  const CreateTaskScreen({
    super.key,
    this.shopId,
    this.shopLatitude,
    this.shopLongitude,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _itemController = TextEditingController();

  String _selectedRole = 'EMPLOYEE';
  int? _selectedPersonId;
  String? _selectedPersonName;
  int? _selectedManagerId;
  String? _selectedManagerName;
  String _priority = 'MEDIUM';
  DateTime? _dueDate;
  final List<String> _items = [];
  bool _isLoading = false;
  bool _isLoadingPeople = false;

  List<EmployeeItem> _employees = [];
  List<ManagerItem> _managers = [];

  // Shop selection. When the screen is opened from shop management a shop is
  // already supplied via the widget; otherwise the user must pick one here.
  List<Shop> _shops = [];
  Shop? _selectedShop;
  bool _isLoadingShops = false;

  late final TaskDataSourceImpl _taskDataSource;
  late final TeamDataSourceImpl _teamDataSource;
  late final ShopsDataSourceImpl _shopsDataSource;

  /// Shop coordinates are required by the API. They come either from the
  /// caller or from the chosen shop (its lat/lng arrive as strings).
  double? get _effectiveShopLat =>
      widget.shopLatitude ??
      (_selectedShop != null ? double.tryParse(_selectedShop!.latitude) : null);

  double? get _effectiveShopLng =>
      widget.shopLongitude ??
      (_selectedShop != null ? double.tryParse(_selectedShop!.longitude) : null);

  @override
  void initState() {
    super.initState();
    _taskDataSource = TaskDataSourceImpl(DioClient.createDio());
    _teamDataSource = TeamDataSourceImpl(DioClient.createDio());
    _shopsDataSource = ShopsDataSourceImpl(DioClient.createDio());
    _loadPeople();
    // Only need the shop list when the caller didn't already pick one.
    if (widget.shopId == null) _loadShops();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  Future<void> _loadPeople() async {
    setState(() => _isLoadingPeople = true);

    try {
      final employeesResponse = await _teamDataSource.getEmployees();
      final managersResponse = await _teamDataSource.getManagers();

      if (mounted) {
        setState(() {
          _employees = employeesResponse.employees;
          _managers = managersResponse.managers;
          _isLoadingPeople = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPeople = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load employees/managers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadShops() async {
    setState(() => _isLoadingShops = true);
    try {
      final hierarchy = await _shopsDataSource.getShopsHierarchy();

      // The endpoint returns shops nested under managers / employees and a
      // pool of unassigned ones. Flatten everything and dedupe by id.
      final byId = <int, Shop>{};
      void add(Iterable<Shop> shops) {
        for (final s in shops) {
          byId[s.id] = s;
        }
      }

      add(hierarchy.unassignedShops);
      for (final m in hierarchy.managers) {
        add(m.shops);
        for (final e in m.employees) {
          add(e.shops);
        }
      }
      for (final e in hierarchy.directEmployees) {
        add(e.shops);
      }

      final shops = byId.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (mounted) {
        setState(() {
          _shops = shops;
          _isLoadingShops = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingShops = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load shops: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showShopSelector() {
    if (_shops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No shops available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShopSelectorBottomSheet(
        shops: _shops,
        selectedShopId: _selectedShop?.id,
        onShopSelected: (shop) {
          setState(() => _selectedShop = shop);
        },
      ),
    );
  }

  void _showManagerSelector() {
    if (_managers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No managers available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PersonSelectorBottomSheet(
        role: 'MANAGER',
        employees: _employees,
        managers: _managers,
        selectedPersonId: _selectedManagerId,
        onPersonSelected: (id, name) {
          setState(() {
            _selectedManagerId = id;
            _selectedManagerName = name;
          });
        },
      ),
    );
  }

  void _showPersonSelector() {
    final people = _selectedRole == 'EMPLOYEE' ? _employees : _managers;

    if (people.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No ${_selectedRole.toLowerCase()}s available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PersonSelectorBottomSheet(
        role: _selectedRole,
        employees: _employees,
        managers: _managers,
        selectedPersonId: _selectedPersonId,
        onPersonSelected: (id, name) {
          setState(() {
            _selectedPersonId = id;
            _selectedPersonName = name;
          });
        },
      ),
    );
  }

  Widget _buildPersonTile({
    required int id,
    required String name,
    required String code,
    String? profileImage,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPersonId = id;
          _selectedPersonName = name;
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.scale(12)),
        padding: EdgeInsets.all(SizeConfig.scale(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
          border: Border.all(
            color: _selectedPersonId == id
                ? const Color(0xff0E5A3B)
                : const Color(0xffE8E3DD),
            width: _selectedPersonId == id ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: SizeConfig.scale(24),
              backgroundColor: const Color(0xff0E5A3B).withValues(alpha: 0.1),
              backgroundImage: profileImage != null && profileImage.isNotEmpty
                  ? NetworkImage(profileImage)
                  : null,
              child: profileImage == null || profileImage.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(18),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xff0E5A3B),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: SizeConfig.scale(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(15),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff111111),
                    ),
                  ),
                  SizedBox(height: SizeConfig.scale(2)),
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(13),
                      color: const Color(0xff667085),
                    ),
                  ),
                ],
              ),
            ),
            if (!isActive)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.scale(8),
                  vertical: SizeConfig.scale(4),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffFFE3E6),
                  borderRadius: BorderRadius.circular(SizeConfig.scale(4)),
                ),
                child: Text(
                  'Inactive',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(11),
                    color: const Color(0xffFF3B3B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (_selectedPersonId == id)
              Icon(
                Icons.check_circle,
                color: const Color(0xff0E5A3B),
                size: SizeConfig.scale(24),
              ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    final item = _itemController.text.trim();
    if (item.isNotEmpty) {
      setState(() {
        _items.add(item);
        _itemController.clear();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff0E5A3B),
              onPrimary: Colors.white,
              onSurface: Color(0xff111111),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPersonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an employee or manager'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a due date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Shop location is required by the API — block submission without it.
    if (_effectiveShopLat == null || _effectiveShopLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a shop'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dueDateStr = '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}T00:00:00Z';

      await _taskDataSource.createTask(
        CreateTaskRequest(
          assignedTo: _selectedPersonId!,
          managerId: _selectedRole == 'EMPLOYEE' ? _selectedManagerId : null,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          items: _items,
          priority: _priority,
          dueDate: dueDateStr,
          // Guaranteed non-null by the shop-location check above.
          shopLatitude: _effectiveShopLat!,
          shopLongitude: _effectiveShopLng!,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task created successfully'),
            backgroundColor: Color(0xff0E5A3B),
          ),
        );
        context.pop(true);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final message = _extractErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
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

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        final firstError = (data['errors'] as List).first;
        if (firstError is Map && firstError['message'] is String) {
          return firstError['message'] as String;
        }
      }
      if (data['message'] is String) {
        return data['message'] as String;
      }
    }
    return 'Failed to create task. Please try again.';
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
              'Create Task',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Role Selection
                  _buildSectionTitle('Select Role'),
                  SizedBox(height: SizeConfig.scale(8)),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoleChip('EMPLOYEE'),
                      ),
                      SizedBox(width: SizeConfig.scale(12)),
                      Expanded(
                        child: _buildRoleChip('MANAGER'),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.scale(16)),

                  // Person Selection
                  _buildSectionTitle('Assign To'),
                  SizedBox(height: SizeConfig.scale(8)),
                  GestureDetector(
                    onTap: _isLoadingPeople ? null : _showPersonSelector,
                    child: Container(
                      padding: EdgeInsets.all(SizeConfig.scale(16)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                        border: Border.all(
                          color: _selectedPersonId != null
                              ? const Color(0xff0E5A3B)
                              : const Color(0xffE8E3DD),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            color: const Color(0xff667085),
                            size: SizeConfig.scale(20),
                          ),
                          SizedBox(width: SizeConfig.scale(12)),
                          Expanded(
                            child: _isLoadingPeople
                                ? Text(
                                    'Loading...',
                                    style: TextStyle(
                                      fontSize: SizeConfig.scaledFontSize(14),
                                      color: const Color(0xff667085),
                                    ),
                                  )
                                : Text(
                                    _selectedPersonName ?? 'Select ${_selectedRole.toLowerCase()}',
                                    style: TextStyle(
                                      fontSize: SizeConfig.scaledFontSize(14),
                                      color: _selectedPersonName != null
                                          ? const Color(0xff111111)
                                          : const Color(0xff667085),
                                      fontWeight: _selectedPersonName != null
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: const Color(0xff667085),
                            size: SizeConfig.scale(16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.scale(16)),

                  // Optional manager selector (only when assigning to an employee)
                  if (_selectedRole == 'EMPLOYEE') ...[
                    _buildSectionTitle('Under Manager (optional)'),
                    SizedBox(height: SizeConfig.scale(8)),
                    GestureDetector(
                      onTap: _isLoadingPeople ? null : _showManagerSelector,
                      child: Container(
                        padding: EdgeInsets.all(SizeConfig.scale(16)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                          border: Border.all(
                            color: _selectedManagerId != null
                                ? const Color(0xff0E5A3B)
                                : const Color(0xffE8E3DD),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.supervisor_account_outlined,
                              color: _selectedManagerId != null
                                  ? const Color(0xff0E5A3B)
                                  : const Color(0xff667085),
                              size: SizeConfig.scale(20),
                            ),
                            SizedBox(width: SizeConfig.scale(12)),
                            Expanded(
                              child: Text(
                                _selectedManagerName ?? 'Select manager (optional)',
                                style: TextStyle(
                                  fontSize: SizeConfig.scaledFontSize(14),
                                  color: _selectedManagerName != null
                                      ? const Color(0xff111111)
                                      : const Color(0xff667085),
                                  fontWeight: _selectedManagerName != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (_selectedManagerId != null)
                              GestureDetector(
                                onTap: () => setState(() {
                                  _selectedManagerId = null;
                                  _selectedManagerName = null;
                                }),
                                child: Icon(
                                  Icons.close,
                                  color: const Color(0xff667085),
                                  size: SizeConfig.scale(18),
                                ),
                              )
                            else
                              Icon(
                                Icons.arrow_forward_ios,
                                color: const Color(0xff667085),
                                size: SizeConfig.scale(16),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: SizeConfig.scale(16)),
                  ],

                  // Title
                  _buildSectionTitle('Task Title'),
                  SizedBox(height: SizeConfig.scale(8)),
                  _buildTextField(
                    controller: _titleController,
                    hint: 'e.g. Visit 5 shops in Kathmandu',
                    icon: Icons.title,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Title is required'
                        : null,
                  ),
                  SizedBox(height: SizeConfig.scale(16)),

                  // Priority
                  _buildSectionTitle('Priority'),
                  SizedBox(height: SizeConfig.scale(8)),
                  _buildPrioritySelector(),
                  SizedBox(height: SizeConfig.scale(16)),

                  // Due Date
                  _buildSectionTitle('Due Date'),
                  SizedBox(height: SizeConfig.scale(8)),
                  _buildDateSelector(),
                  SizedBox(height: SizeConfig.scale(16)),

                  // Description
                  _buildSectionTitle('Description'),
                  SizedBox(height: SizeConfig.scale(8)),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
                      border: Border.all(color: const Color(0xffE8E3DD)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with icon
                        Container(
                          padding: EdgeInsets.all(SizeConfig.scale(12)),
                          decoration: BoxDecoration(
                            color: const Color(0xff0E5A3B).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(SizeConfig.scale(16)),
                              topRight: Radius.circular(SizeConfig.scale(16)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(SizeConfig.scale(8)),
                                decoration: BoxDecoration(
                                  color: const Color(0xff0E5A3B).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(SizeConfig.scale(8)),
                                ),
                                child: Icon(
                                  Icons.description_outlined,
                                  color: const Color(0xff0E5A3B),
                                  size: SizeConfig.scale(20),
                                ),
                              ),
                              SizedBox(width: SizeConfig.scale(12)),
                              Expanded(
                                child: Text(
                                  'Task Description',
                                  style: TextStyle(
                                    fontSize: SizeConfig.scaledFontSize(15),
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xff111111),
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.scale(8),
                                  vertical: SizeConfig.scale(4),
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xff0E5A3B).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                                ),
                                child: Text(
                                  'Required',
                                  style: TextStyle(
                                    fontSize: SizeConfig.scaledFontSize(11),
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xff0E5A3B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Text field
                        Padding(
                          padding: EdgeInsets.all(SizeConfig.scale(16)),
                          child: TextFormField(
                            controller: _descriptionController,
                            maxLines: 5,
                            maxLength: 500,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Description is required'
                                : null,
                            style: TextStyle(
                              fontSize: SizeConfig.scaledFontSize(14),
                              color: const Color(0xff111111),
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Describe the task in detail...\n\nExample:\n• What needs to be done\n• Expected outcomes\n• Any special instructions',
                              hintStyle: TextStyle(
                                color: const Color(0xff9CA3AF),
                                fontSize: SizeConfig.scaledFontSize(13),
                                height: 1.5,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              counterStyle: TextStyle(
                                fontSize: SizeConfig.scaledFontSize(11),
                                color: const Color(0xff667085),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.scale(16)),

                  // Items
                  _buildSectionTitle('Task Items'),
                  SizedBox(height: SizeConfig.scale(8)),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _itemController,
                          hint: 'e.g. Verify product display',
                          icon: Icons.checklist,
                        ),
                      ),
                      SizedBox(width: SizeConfig.scale(8)),
                      ElevatedButton(
                        onPressed: _addItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0E5A3B),
                          padding: EdgeInsets.all(SizeConfig.scale(16)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: SizeConfig.scale(20),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.scale(12)),

                  // Items List
                  if (_items.isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.all(SizeConfig.scale(12)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                        border: Border.all(color: const Color(0xffE8E3DD)),
                      ),
                      child: Column(
                        children: _items.asMap().entries.map((entry) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: SizeConfig.scale(8)),
                            child: Row(
                              children: [
                                Container(
                                  width: SizeConfig.scale(24),
                                  height: SizeConfig.scale(24),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff0E5A3B).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: TextStyle(
                                        fontSize: SizeConfig.scaledFontSize(12),
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xff0E5A3B),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: SizeConfig.scale(12)),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: SizeConfig.scaledFontSize(14),
                                      color: const Color(0xff111111),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeItem(entry.key),
                                  icon: Icon(
                                    Icons.close,
                                    size: SizeConfig.scale(18),
                                    color: Colors.red,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: SizeConfig.scale(16)),
                  ],

                  // Shop — location is required by the API
                  Row(
                    children: [
                      _buildSectionTitle('Shop'),
                      SizedBox(width: SizeConfig.scale(8)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.scale(8),
                          vertical: SizeConfig.scale(3),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff0E5A3B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                        ),
                        child: Text(
                          'Required',
                          style: TextStyle(
                            fontSize: SizeConfig.scaledFontSize(11),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff0E5A3B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.scale(8)),
                  _buildShopSelector(),
                  SizedBox(height: SizeConfig.scale(16)),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0E5A3B),
                        padding: EdgeInsets.symmetric(
                          vertical: SizeConfig.scale(16),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: SizeConfig.scale(20),
                              width: SizeConfig.scale(20),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Create Task',
                              style: TextStyle(
                                fontSize: SizeConfig.scaledFontSize(16),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.scale(16)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: SizeConfig.scaledFontSize(14),
        fontWeight: FontWeight.w600,
        color: const Color(0xff111111),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
          _selectedPersonId = null;
          _selectedPersonName = null;
          _selectedManagerId = null;
          _selectedManagerName = null;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.scale(12)),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xff0E5A3B).withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
          border: Border.all(
            color: isSelected ? const Color(0xff0E5A3B) : const Color(0xffE8E3DD),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            role,
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(14),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xff0E5A3B) : const Color(0xff667085),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: [
        _buildPriorityChip('LOW', Colors.blue),
        SizedBox(width: SizeConfig.scale(8)),
        _buildPriorityChip('MEDIUM', Colors.orange),
        SizedBox(width: SizeConfig.scale(8)),
        _buildPriorityChip('HIGH', Colors.red),
      ],
    );
  }

  Widget _buildPriorityChip(String priority, Color color) {
    final isSelected = _priority == priority;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = priority),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.scale(12)),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
            border: Border.all(
              color: isSelected ? color : const Color(0xffE8E3DD),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              priority,
              style: TextStyle(
                fontSize: SizeConfig.scaledFontSize(14),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : const Color(0xff667085),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDueDate,
      child: Container(
        padding: EdgeInsets.all(SizeConfig.scale(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
          border: Border.all(color: const Color(0xffE8E3DD)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: const Color(0xff667085),
              size: SizeConfig.scale(20),
            ),
            SizedBox(width: SizeConfig.scale(12)),
            Expanded(
              child: Text(
                _dueDate == null
                    ? 'Select due date'
                    : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(14),
                  color: _dueDate == null
                      ? const Color(0xff667085)
                      : const Color(0xff111111),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: const Color(0xff667085),
              size: SizeConfig.scale(16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopSelector() {
    // Shop already supplied by the caller (e.g. opened from shop management).
    if (widget.shopId != null) {
      return Container(
        padding: EdgeInsets.all(SizeConfig.scale(12)),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
          border: Border.all(color: const Color(0xFFD1FADF)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.store,
              color: const Color(0xff0E5A3B),
              size: SizeConfig.scale(20),
            ),
            SizedBox(width: SizeConfig.scale(12)),
            Expanded(
              child: Text(
                'Task will be assigned to Shop #${widget.shopId}',
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(13),
                  color: const Color(0xff0E5A3B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final hasSelection = _selectedShop != null;
    return GestureDetector(
      onTap: _isLoadingShops ? null : _showShopSelector,
      child: Container(
        padding: EdgeInsets.all(SizeConfig.scale(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
          border: Border.all(
            color: hasSelection
                ? const Color(0xff0E5A3B)
                : const Color(0xffE8E3DD),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.store_outlined,
              color: hasSelection
                  ? const Color(0xff0E5A3B)
                  : const Color(0xff667085),
              size: SizeConfig.scale(20),
            ),
            SizedBox(width: SizeConfig.scale(12)),
            Expanded(
              child: _isLoadingShops
                  ? Text(
                      'Loading shops...',
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(14),
                        color: const Color(0xff667085),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasSelection
                              ? _selectedShop!.name
                              : 'Select shop',
                          style: TextStyle(
                            fontSize: SizeConfig.scaledFontSize(14),
                            color: hasSelection
                                ? const Color(0xff111111)
                                : const Color(0xff667085),
                            fontWeight: hasSelection
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        if (hasSelection &&
                            _selectedShop!.address.isNotEmpty) ...[
                          SizedBox(height: SizeConfig.scale(2)),
                          Text(
                            _selectedShop!.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: SizeConfig.scaledFontSize(12),
                              color: const Color(0xff667085),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: const Color(0xff667085),
              size: SizeConfig.scale(16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: const Color(0xff667085),
          fontSize: SizeConfig.scaledFontSize(14),
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xff667085),
          size: SizeConfig.scale(20),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: SizeConfig.scale(16),
          vertical: SizeConfig.scale(14),
        ),
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
          borderSide: const BorderSide(color: Color(0xff0E5A3B), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}

// Bottom Sheet Widget for Person Selection with Search
class _PersonSelectorBottomSheet extends StatefulWidget {
  final String role;
  final List<EmployeeItem> employees;
  final List<ManagerItem> managers;
  final int? selectedPersonId;
  final Function(int id, String name) onPersonSelected;

  const _PersonSelectorBottomSheet({
    required this.role,
    required this.employees,
    required this.managers,
    required this.selectedPersonId,
    required this.onPersonSelected,
  });

  @override
  State<_PersonSelectorBottomSheet> createState() => _PersonSelectorBottomSheetState();
}

class _PersonSelectorBottomSheetState extends State<_PersonSelectorBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredPeople = [];

  @override
  void initState() {
    super.initState();
    _filteredPeople = widget.role == 'EMPLOYEE' ? widget.employees : widget.managers;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPeople(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPeople = widget.role == 'EMPLOYEE' ? widget.employees : widget.managers;
      } else {
        if (widget.role == 'EMPLOYEE') {
          _filteredPeople = widget.employees.where((employee) {
            return employee.fullName.toLowerCase().contains(query.toLowerCase()) ||
                employee.employeeCode.toLowerCase().contains(query.toLowerCase());
          }).toList();
        } else {
          _filteredPeople = widget.managers.where((manager) {
            return manager.fullName.toLowerCase().contains(query.toLowerCase()) ||
                manager.managerCode.toLowerCase().contains(query.toLowerCase());
          }).toList();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(SizeConfig.scale(16)),
            child: Column(
              children: [
                Container(
                  width: SizeConfig.scale(40),
                  height: SizeConfig.scale(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(SizeConfig.scale(2)),
                  ),
                ),
                SizedBox(height: SizeConfig.scale(16)),
                Text(
                  'Select ${widget.role == 'EMPLOYEE' ? 'Employee' : 'Manager'}',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(18),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff111111),
                  ),
                ),
                SizedBox(height: SizeConfig.scale(16)),
                
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: _filterPeople,
                  decoration: InputDecoration(
                    hintText: 'Search by name or code...',
                    hintStyle: TextStyle(
                      color: const Color(0xff667085),
                      fontSize: SizeConfig.scaledFontSize(14),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: const Color(0xff667085),
                      size: SizeConfig.scale(20),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: const Color(0xff667085),
                              size: SizeConfig.scale(20),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterPeople('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.scale(16),
                      vertical: SizeConfig.scale(12),
                    ),
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
                      borderSide: const BorderSide(color: Color(0xff0E5A3B), width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Results Count
          if (_filteredPeople.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.scale(16)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filteredPeople.length} ${_filteredPeople.length == 1 ? 'result' : 'results'}',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(13),
                    color: const Color(0xff667085),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          SizedBox(height: SizeConfig.scale(8)),

          // People List
          Expanded(
            child: _filteredPeople.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: SizeConfig.scale(64),
                          color: const Color(0xffE8E3DD),
                        ),
                        SizedBox(height: SizeConfig.scale(16)),
                        Text(
                          'No results found',
                          style: TextStyle(
                            fontSize: SizeConfig.scaledFontSize(16),
                            color: const Color(0xff667085),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: SizeConfig.scale(8)),
                        Text(
                          'Try a different search term',
                          style: TextStyle(
                            fontSize: SizeConfig.scaledFontSize(13),
                            color: const Color(0xff667085),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: SizeConfig.scale(16)),
                    itemCount: _filteredPeople.length,
                    itemBuilder: (context, index) {
                      if (widget.role == 'EMPLOYEE') {
                        final employee = _filteredPeople[index] as EmployeeItem;
                        return _buildPersonTile(
                          id: int.parse(employee.id),
                          name: employee.fullName,
                          code: employee.employeeCode,
                          profileImage: employee.profileImage,
                          isActive: employee.isActive,
                        );
                      } else {
                        final manager = _filteredPeople[index] as ManagerItem;
                        return _buildPersonTile(
                          id: int.parse(manager.id),
                          name: manager.fullName,
                          code: manager.managerCode,
                          profileImage: manager.profileImage,
                          isActive: manager.isActive,
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonTile({
    required int id,
    required String name,
    required String code,
    String? profileImage,
    required bool isActive,
  }) {
    final isSelected = widget.selectedPersonId == id;
    return GestureDetector(
      onTap: () {
        widget.onPersonSelected(id, name);
        Navigator.pop(context);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.scale(12)),
        padding: EdgeInsets.all(SizeConfig.scale(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
          border: Border.all(
            color: isSelected ? const Color(0xff0E5A3B) : const Color(0xffE8E3DD),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xff0E5A3B).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: SizeConfig.scale(24),
              backgroundColor: const Color(0xff0E5A3B).withValues(alpha: 0.1),
              backgroundImage: profileImage != null && profileImage.isNotEmpty
                  ? NetworkImage(profileImage)
                  : null,
              child: profileImage == null || profileImage.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(18),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xff0E5A3B),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: SizeConfig.scale(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(15),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff111111),
                    ),
                  ),
                  SizedBox(height: SizeConfig.scale(2)),
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(13),
                      color: const Color(0xff667085),
                    ),
                  ),
                ],
              ),
            ),
            if (!isActive)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.scale(8),
                  vertical: SizeConfig.scale(4),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffFFE3E6),
                  borderRadius: BorderRadius.circular(SizeConfig.scale(4)),
                ),
                child: Text(
                  'Inactive',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(11),
                    color: const Color(0xffFF3B3B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(width: SizeConfig.scale(8)),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xff0E5A3B),
                size: SizeConfig.scale(24),
              ),
          ],
        ),
      ),
    );
  }
}

// Bottom Sheet Widget for Shop Selection with Search
class _ShopSelectorBottomSheet extends StatefulWidget {
  final List<Shop> shops;
  final int? selectedShopId;
  final ValueChanged<Shop> onShopSelected;

  const _ShopSelectorBottomSheet({
    required this.shops,
    required this.selectedShopId,
    required this.onShopSelected,
  });

  @override
  State<_ShopSelectorBottomSheet> createState() =>
      _ShopSelectorBottomSheetState();
}

class _ShopSelectorBottomSheetState extends State<_ShopSelectorBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<Shop> _filteredShops;

  @override
  void initState() {
    super.initState();
    _filteredShops = widget.shops;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterShops(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredShops = widget.shops;
      } else {
        final q = query.toLowerCase();
        _filteredShops = widget.shops.where((shop) {
          return shop.name.toLowerCase().contains(q) ||
              shop.address.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(SizeConfig.scale(16)),
            child: Column(
              children: [
                Container(
                  width: SizeConfig.scale(40),
                  height: SizeConfig.scale(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(SizeConfig.scale(2)),
                  ),
                ),
                SizedBox(height: SizeConfig.scale(16)),
                Text(
                  'Select Shop',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(18),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff111111),
                  ),
                ),
                SizedBox(height: SizeConfig.scale(16)),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: _filterShops,
                  decoration: InputDecoration(
                    hintText: 'Search by name or address...',
                    hintStyle: TextStyle(
                      color: const Color(0xff667085),
                      fontSize: SizeConfig.scaledFontSize(14),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: const Color(0xff667085),
                      size: SizeConfig.scale(20),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: const Color(0xff667085),
                              size: SizeConfig.scale(20),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterShops('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.scale(16),
                      vertical: SizeConfig.scale(12),
                    ),
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
                      borderSide:
                          const BorderSide(color: Color(0xff0E5A3B), width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Results Count
          if (_filteredShops.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.scale(16)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filteredShops.length} ${_filteredShops.length == 1 ? 'result' : 'results'}',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(13),
                    color: const Color(0xff667085),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          SizedBox(height: SizeConfig.scale(8)),

          // Shop List
          Expanded(
            child: _filteredShops.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: SizeConfig.scale(64),
                          color: const Color(0xffE8E3DD),
                        ),
                        SizedBox(height: SizeConfig.scale(16)),
                        Text(
                          'No shops found',
                          style: TextStyle(
                            fontSize: SizeConfig.scaledFontSize(16),
                            color: const Color(0xff667085),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: SizeConfig.scale(8)),
                        Text(
                          'Try a different search term',
                          style: TextStyle(
                            fontSize: SizeConfig.scaledFontSize(13),
                            color: const Color(0xff667085),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        EdgeInsets.symmetric(horizontal: SizeConfig.scale(16)),
                    itemCount: _filteredShops.length,
                    itemBuilder: (context, index) {
                      final shop = _filteredShops[index];
                      return _buildShopTile(shop);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopTile(Shop shop) {
    final isSelected = widget.selectedShopId == shop.id;
    return GestureDetector(
      onTap: () {
        widget.onShopSelected(shop);
        Navigator.pop(context);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.scale(12)),
        padding: EdgeInsets.all(SizeConfig.scale(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
          border: Border.all(
            color:
                isSelected ? const Color(0xff0E5A3B) : const Color(0xffE8E3DD),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xff0E5A3B).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
              child: Container(
                width: SizeConfig.scale(48),
                height: SizeConfig.scale(48),
                color: const Color(0xff0E5A3B).withValues(alpha: 0.1),
                child: (shop.shopImage != null && shop.shopImage!.isNotEmpty)
                    ? Image.network(
                        shop.shopImage!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: SizeConfig.scale(18),
                              height: SizeConfig.scale(18),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xff0E5A3B),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, _, _) => Icon(
                          Icons.store,
                          color: const Color(0xff0E5A3B),
                          size: SizeConfig.scale(24),
                        ),
                      )
                    : Icon(
                        Icons.store,
                        color: const Color(0xff0E5A3B),
                        size: SizeConfig.scale(24),
                      ),
              ),
            ),
            SizedBox(width: SizeConfig.scale(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(15),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff111111),
                    ),
                  ),
                  SizedBox(height: SizeConfig.scale(2)),
                  Text(
                    shop.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(13),
                      color: const Color(0xff667085),
                    ),
                  ),
                ],
              ),
            ),
            if (!shop.isActive)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.scale(8),
                  vertical: SizeConfig.scale(4),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffFFE3E6),
                  borderRadius: BorderRadius.circular(SizeConfig.scale(4)),
                ),
                child: Text(
                  'Inactive',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(11),
                    color: const Color(0xffFF3B3B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(width: SizeConfig.scale(8)),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xff0E5A3B),
                size: SizeConfig.scale(24),
              ),
          ],
        ),
      ),
    );
  }
}
