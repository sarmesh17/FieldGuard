import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/core/router/app_routes.dart';
import 'package:fieldguard/features/shops/domain/models/shop_with_creator.dart';
import 'package:fieldguard/features/shops/presentation/providers/shops_provider.dart';
import 'package:fieldguard/features/shops/presentation/providers/shops_state.dart';
import 'package:fieldguard/features/shops/presentation/screens/shop_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ShopsScreen extends ConsumerStatefulWidget {
  const ShopsScreen({super.key});

  @override
  ConsumerState<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends ConsumerState<ShopsScreen> {
  List<ShopWithCreator> _filteredShops = [];
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load shops when screen initializes
    Future.microtask(() => ref.read(shopsNotifierProvider.notifier).loadShops());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter(List<ShopWithCreator> allShops, String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'All') {
        _filteredShops = allShops;
      } else {
        _filteredShops = allShops
            .where((shop) => shop.creatorRole == filter)
            .toList();
      }
      _applySearch(_searchController.text);
    });
  }

  void _applySearch(String query) {
    final shopsState = ref.read(shopsNotifierProvider);
    if (shopsState is! ShopsSuccess) return;

    final allShops = shopsState.shops;

    if (query.isEmpty) {
      setState(() {
        if (_selectedFilter == 'All') {
          _filteredShops = allShops;
        } else {
          _filteredShops = allShops
              .where((shop) => shop.creatorRole == _selectedFilter)
              .toList();
        }
      });
    } else {
      setState(() {
        final baseList = _selectedFilter == 'All'
            ? allShops
            : allShops.where((shop) => shop.creatorRole == _selectedFilter).toList();
        
        _filteredShops = baseList
            .where((shop) =>
                shop.shop.name.toLowerCase().contains(query.toLowerCase()) ||
                shop.shop.address.toLowerCase().contains(query.toLowerCase()) ||
                shop.creatorName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopsState = ref.watch(shopsNotifierProvider);

    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shops',
                  style: TextStyle(
                    color: const Color(0xff111111),
                    fontWeight: FontWeight.w700,
                    fontSize: SizeConfig.scaledFontSize(20),
                  ),
                ),
                Text(
                  '${_filteredShops.length} Total',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(12),
                    color: const Color(0xff667085),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          body: switch (shopsState) {
            ShopsInitial() => const Center(child: Text('Press button to load shops')),
            ShopsLoading() => const Center(child: CircularProgressIndicator()),
            ShopsFailure(:final message) => _buildErrorView(message),
            ShopsSuccess(:final shops) => _buildContent(shops),
          },
        );
      },
    );
  }

  Widget _buildErrorView(String message) {
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
            message,
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(16),
              color: const Color(0xff667085),
            ),
          ),
          SizedBox(height: SizeConfig.heightPercent(3)),
          ElevatedButton(
            onPressed: () => ref.read(shopsNotifierProvider.notifier).loadShops(),
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

  Widget _buildContent(List<ShopWithCreator> shops) {
    // Initialize filtered shops if empty
    if (_filteredShops.isEmpty && shops.isNotEmpty) {
      _filteredShops = shops;
    }

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: EdgeInsets.all(SizeConfig.scale(16)),
          child: TextField(
            controller: _searchController,
            onChanged: _applySearch,
            decoration: InputDecoration(
              hintText: 'Search shops...',
              prefixIcon: const Icon(Icons.search, color: Color(0xff667085)),
              filled: true,
              fillColor: Colors.white,
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
        ),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.scale(16)),
          child: Row(
            children: [
              _buildFilterChip('All', shops),
              SizedBox(width: SizeConfig.scale(8)),
              _buildFilterChip('Admin', shops),
              SizedBox(width: SizeConfig.scale(8)),
              _buildFilterChip('Manager', shops),
              SizedBox(width: SizeConfig.scale(8)),
              _buildFilterChip('Employee', shops),
            ],
          ),
        ),

        SizedBox(height: SizeConfig.scale(16)),

        // Shops List
        Expanded(
          child: _filteredShops.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(shopsNotifierProvider.notifier).loadShops();
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: SizeConfig.scale(16)),
                    itemCount: _filteredShops.length,
                    itemBuilder: (context, index) {
                      return _buildShopCard(_filteredShops[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, List<ShopWithCreator> shops) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => _applyFilter(shops, label),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.scale(16),
          vertical: SizeConfig.scale(8),
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff0E5A3B) : Colors.white,
          borderRadius: BorderRadius.circular(SizeConfig.scale(20)),
          border: Border.all(
            color: isSelected ? const Color(0xff0E5A3B) : const Color(0xffE8E3DD),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: SizeConfig.scaledFontSize(14),
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xff667085),
          ),
        ),
      ),
    );
  }

  Widget _buildShopCard(ShopWithCreator shopData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopDetailScreen(
              shopId: shopData.shop.id.toString(),
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.scale(12)),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Shop image banner
          if (shopData.shop.shopImage != null &&
              shopData.shop.shopImage!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: SizeConfig.scale(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(SizeConfig.scale(8)),
                child: Image.network(
                  shopData.shop.shopImage!,
                  width: double.infinity,
                  height: SizeConfig.scale(120),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  shopData.shop.name,
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(16),
                    fontWeight: FontWeight.w700,
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
                  color: shopData.shop.isActive
                      ? const Color(0xffDDF5E0)
                      : const Color(0xffFFE3E6),
                  borderRadius: BorderRadius.circular(SizeConfig.scale(4)),
                ),
                child: Text(
                  shopData.shop.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(11),
                    color: shopData.shop.isActive
                        ? const Color(0xff0E5A3B)
                        : const Color(0xffFF3B3B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.scale(4)),
              GestureDetector(
                onTap: () async {
                  final updated = await context.push<bool>(
                    '${AppRoutes.updateShop}/${shopData.shop.id}',
                    extra: shopData.shop,
                  );
                  if (updated == true && mounted) {
                    ref.read(shopsNotifierProvider.notifier).loadShops();
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(SizeConfig.scale(6)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(SizeConfig.scale(6)),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: SizeConfig.scale(16),
                    color: const Color(0xff0E5A3B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.scale(8)),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: SizeConfig.scale(16),
                color: const Color(0xff667085),
              ),
              SizedBox(width: SizeConfig.scale(4)),
              Expanded(
                child: Text(
                  shopData.shop.address,
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(13),
                    color: const Color(0xff667085),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.scale(8)),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: SizeConfig.scale(16),
                color: const Color(0xff667085),
              ),
              SizedBox(width: SizeConfig.scale(4)),
              Text(
                'Created by: ',
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(13),
                  color: const Color(0xff667085),
                ),
              ),
              Text(
                '${shopData.creatorName} ',
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(13),
                  color: const Color(0xff111111),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.scale(6),
                  vertical: SizeConfig.scale(2),
                ),
                decoration: BoxDecoration(
                  color: _getRoleColor(shopData.creatorRole).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(SizeConfig.scale(4)),
                ),
                child: Text(
                  shopData.creatorRole,
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(10),
                    color: _getRoleColor(shopData.creatorRole),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return const Color(0xffFF6B6B);
      case 'Manager':
        return const Color(0xff6558FF);
      case 'Employee':
        return const Color(0xff0E5A3B);
      default:
        return const Color(0xff667085);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: SizeConfig.scale(80),
            color: const Color(0xffE8E3DD),
          ),
          SizedBox(height: SizeConfig.heightPercent(2)),
          Text(
            'No shops found',
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(16),
              color: const Color(0xff667085),
            ),
          ),
        ],
      ),
    );
  }
}
