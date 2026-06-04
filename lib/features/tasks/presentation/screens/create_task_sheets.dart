part of 'create_task_screen.dart';

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
                    color: AppColors.grey4,
                    borderRadius: BorderRadius.circular(SizeConfig.scale(2)),
                  ),
                ),
                SizedBox(height: SizeConfig.scale(16)),
                Text(
                  'Select ${widget.role == 'EMPLOYEE' ? 'Employee' : 'Manager'}',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
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
                      color: AppColors.grey,
                      fontSize: SizeConfig.scaledFontSize(14),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.grey,
                      size: SizeConfig.scale(20),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: AppColors.grey,
                              size: SizeConfig.scale(20),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterPeople('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.scale(16),
                      vertical: SizeConfig.scale(12),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                      borderSide: const BorderSide(color: AppColors.grey3),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                      borderSide: const BorderSide(color: AppColors.grey3),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                      borderSide: const BorderSide(color: AppColors.green, width: 2),
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
                    color: AppColors.grey,
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
                          color: AppColors.grey3,
                        ),
                        SizedBox(height: SizeConfig.scale(16)),
                        Text(
                          'No results found',
                          style: TextStyle(
                            fontSize: SizeConfig.scaledFontSize(16),
                            color: AppColors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: SizeConfig.scale(8)),
                        Text(
                          'Try a different search term',
                          style: TextStyle(
                            fontSize: SizeConfig.scaledFontSize(13),
                            color: AppColors.grey,
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
            color: isSelected ? AppColors.green : AppColors.grey3,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.1),
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
              backgroundColor: AppColors.green.withValues(alpha: 0.1),
              backgroundImage: profileImage != null && profileImage.isNotEmpty
                  ? NetworkImage(profileImage)
                  : null,
              child: profileImage == null || profileImage.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(18),
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
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
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: SizeConfig.scale(2)),
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(13),
                      color: AppColors.grey,
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
                  color: AppColors.red6,
                  borderRadius: BorderRadius.circular(SizeConfig.scale(4)),
                ),
                child: Text(
                  'Inactive',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(11),
                    color: AppColors.red2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(width: SizeConfig.scale(8)),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.green,
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
                    color: AppColors.grey4,
                    borderRadius: BorderRadius.circular(SizeConfig.scale(2)),
                  ),
                ),
                SizedBox(height: SizeConfig.scale(16)),
                Text(
                  'Select Shop',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
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
                      color: AppColors.grey,
                      fontSize: SizeConfig.scaledFontSize(14),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.grey,
                      size: SizeConfig.scale(20),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: AppColors.grey,
                              size: SizeConfig.scale(20),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterShops('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.scale(16),
                      vertical: SizeConfig.scale(12),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                      borderSide: const BorderSide(color: AppColors.grey3),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                      borderSide: const BorderSide(color: AppColors.grey3),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
                      borderSide:
                          const BorderSide(color: AppColors.green, width: 2),
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
                    color: AppColors.grey,
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
                          color: AppColors.grey3,
                        ),
                        SizedBox(height: SizeConfig.scale(16)),
                        Text(
                          'No shops found',
                          style: TextStyle(
                            fontSize: SizeConfig.scaledFontSize(16),
                            color: AppColors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: SizeConfig.scale(8)),
                        Text(
                          'Try a different search term',
                          style: TextStyle(
                            fontSize: SizeConfig.scaledFontSize(13),
                            color: AppColors.grey,
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
                isSelected ? AppColors.green : AppColors.grey3,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.1),
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
                color: AppColors.green.withValues(alpha: 0.1),
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
                                color: AppColors.green,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, _, _) => Icon(
                          Icons.store,
                          color: AppColors.green,
                          size: SizeConfig.scale(24),
                        ),
                      )
                    : Icon(
                        Icons.store,
                        color: AppColors.green,
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
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: SizeConfig.scale(2)),
                  Text(
                    shop.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(13),
                      color: AppColors.grey,
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
                  color: AppColors.red6,
                  borderRadius: BorderRadius.circular(SizeConfig.scale(4)),
                ),
                child: Text(
                  'Inactive',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(11),
                    color: AppColors.red2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(width: SizeConfig.scale(8)),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.green,
                size: SizeConfig.scale(24),
              ),
          ],
        ),
      ),
    );
  }
}
