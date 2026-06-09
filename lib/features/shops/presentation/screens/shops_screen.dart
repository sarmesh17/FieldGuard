import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/core/router/app_routes.dart';
import 'package:fieldguard/core/services/session.dart';
import 'package:fieldguard/features/shops/domain/models/shop_with_creator.dart';
import 'package:fieldguard/features/shops/presentation/providers/shops_provider.dart';
import 'package:fieldguard/features/shops/presentation/providers/shops_state.dart';
import 'package:fieldguard/features/shops/presentation/screens/create_shop_map_screen.dart';
import 'package:fieldguard/features/shops/presentation/screens/shop_detail_screen.dart';
import 'package:fieldguard/widgets/app_skeletons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

// ─── Brand palette (consistent with Team / Routes / Profile) ────────────────
const _kDark = AppColors.green;
const _kPrimary = AppColors.green;
const _kMid = AppColors.green;
const _kSurface = AppColors.white;
const _kBorder = AppColors.grey3;
const _kMuted = AppColors.grey;

// Cap content to a comfortable phone width so cards don't stretch on
// wide / landscape screens.
const double _kContentMaxWidth = 600;

Widget _centered(Widget child) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
    child: child,
  ),
);

// Shorter-side scaling so paddings/fonts don't balloon on landscape phones
// (mirrors the helper in Team Management / Routes).
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

class ShopsScreen extends ConsumerStatefulWidget {
  const ShopsScreen({super.key});

  @override
  ConsumerState<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends ConsumerState<ShopsScreen> {
  String _selectedSource = '';
  String _searchQuery = '';
  List<String> _availableSources = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeRole();
  }

  Future<void> _initializeRole() async {
    final role = await Session.role();
    if (!mounted) return;

    final normalized = role?.toLowerCase() ?? '';
    final sources = _getAvailableSourcesForRole(normalized);
    // For manager, default to empty string (Self/My Shops - no query parameter)
    final firstSource = sources.isNotEmpty ? sources.first : '';

    setState(() {
      _availableSources = sources;
      _selectedSource = firstSource;
    });

    await _loadShopsForSource(firstSource);
  }

  List<String> _getAvailableSourcesForRole(String role) {
    switch (role) {
      case 'admin':
        // No 'admin' chip for an admin — "Self" (no param) already returns the
        // admin's own (admin-created) shops, so an "Admin" filter is a
        // confusing duplicate.
        return ['', 'manager', 'employee'];
      case 'manager':
        // For manager: Self (no param), Admin (shared), Employee (team)
        // Note: source=manager is INVALID for MANAGER role per API docs
        return ['', 'admin', 'employee'];
      case 'employee':
        return ['', 'admin', 'manager', 'employee'];
      default:
        return [];
    }
  }

  String _getSourceLabel(String source) {
    switch (source) {
      case '':
        return 'Self';
      case 'admin':
        return 'Admin';
      case 'manager':
        return 'Manager';
      case 'employee':
        return 'Employee';
      default:
        return source[0].toUpperCase() + source.substring(1);
    }
  }

  Future<void> _loadShopsForSource(String source) async {
    await ref
        .read(shopsNotifierProvider.notifier)
        .loadShops(source: source.isEmpty ? null : source);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateShop() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateShopMapScreen()),
    );
    if (created == true && mounted) {
      _loadShopsForSource(_selectedSource);
    }
  }

  void _applySearch(String query) {
    setState(() => _searchQuery = query);
  }

  List<ShopWithCreator> _filterShops(List<ShopWithCreator> shops) {
    if (_searchQuery.isEmpty) return shops;
    final q = _searchQuery.toLowerCase();
    return shops
        .where(
          (shop) =>
              shop.shop.name.toLowerCase().contains(q) ||
              shop.shop.address.toLowerCase().contains(q) ||
              shop.creatorName.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final shopsState = ref.watch(shopsNotifierProvider);

    // Compute total count from current state (not cached).
    final totalCount = shopsState is ShopsSuccess
        ? _filterShops(shopsState.shops).length
        : 0;

    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        final isLandscape = orientation == Orientation.landscape;
        return Scaffold(
          backgroundColor: _kSurface,
          body: Column(
            children: [
              _buildGradientHeader(
                totalCount: totalCount,
                isLandscape: isLandscape,
              ),
              Expanded(
                child: switch (shopsState) {
                  ShopsInitial() => const SizedBox.shrink(),
                  ShopsLoading() => const SkeletonList(),
                  ShopsFailure(:final message) => _buildErrorView(message),
                  ShopsSuccess(:final shops) => _buildContent(shops),
                },
              ),
            ],
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_s(16)),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: _openCreateShop,
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: Text(
                'Create Shop',
                style: TextStyle(
                  fontSize: _sf(14),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Gradient header (matches Team / Routes / Profile) ────────────────────
  Widget _buildGradientHeader({
    required int totalCount,
    required bool isLandscape,
  }) {
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
          // Decorative orbs for depth.
          Positioned(
            top: -30,
            right: -20,
            child: _orb(_s(isLandscape ? 90 : 130), 0.07),
          ),
          Positioned(
            bottom: -10,
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
                _s(isLandscape ? 10 : 16),
              ),
              child: _centered(
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shops',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _sf(isLandscape ? 17 : 19),
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              height: 1.1,
                            ),
                          ),
                          if (!isLandscape)
                            Text(
                              'Stores in your network',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: _sf(11.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _s(12),
                        vertical: _s(5),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(_s(20)),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storefront_rounded,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: _s(13),
                          ),
                          SizedBox(width: _s(5)),
                          Text(
                            '$totalCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _sf(12.5),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _buildErrorView(String message) {
    return Center(
      child: _AnimatedEntry(
        index: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _s(96),
              height: _s(96),
              decoration: BoxDecoration(
                color: AppColors.red6,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: _s(46),
                color: AppColors.red2,
              ),
            ),
            SizedBox(height: SizeConfig.heightPercent(2)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _s(32)),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: _sf(14), color: _kMuted),
              ),
            ),
            SizedBox(height: SizeConfig.heightPercent(2.5)),
            ElevatedButton.icon(
              onPressed: () => _loadShopsForSource(_selectedSource),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: _s(28),
                  vertical: _s(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_s(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<ShopWithCreator> shops) {
    final filteredShops = _filterShops(shops);

    return _centered(
      Column(
        children: [
          // Modern search bar — floating white card with soft shadow.
          Padding(
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
                controller: _searchController,
                onChanged: _applySearch,
                style: TextStyle(fontSize: _sf(14)),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search shops, address, creator…',
                  hintStyle: TextStyle(fontSize: _sf(14), color: _kMuted),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: _s(21),
                    color: _kPrimary,
                  ),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _applySearch('');
                            FocusScope.of(context).unfocus();
                          },
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
          ),

          // Source chips
          if (_availableSources.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(_s(16), 0, _s(16), _s(10)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _availableSources.map((source) {
                    final label = _getSourceLabel(source);
                    final isSelected = _selectedSource == source;
                    return Padding(
                      padding: EdgeInsets.only(right: _s(8)),
                      child: _sourceChip(label, source, isSelected),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Shops list
          Expanded(
            child: filteredShops.isEmpty
                ? RefreshIndicator(
                    onRefresh: () => _loadShopsForSource(_selectedSource),
                    color: _kPrimary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: SizeConfig.heightPercent(12)),
                        _buildEmptyState(),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadShopsForSource(_selectedSource),
                    color: _kPrimary,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        _s(16),
                        _s(4),
                        _s(16),
                        _s(80), // room for the FAB
                      ),
                      itemCount: filteredShops.length,
                      itemBuilder: (context, index) {
                        return _AnimatedEntry(
                          index: index,
                          child: _buildShopCard(filteredShops[index]),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Animated, gradient-on-select source filter chip.
  Widget _sourceChip(String label, String source, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedSource = source);
        _loadShopsForSource(source);
      },
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

  Widget _buildShopCard(ShopWithCreator shopData) {
    final shop = shopData.shop;
    final hasImage = shop.shopImage != null && shop.shopImage!.isNotEmpty;
    final roleColor = _getRoleColor(shopData.creatorRole);

    return Padding(
      padding: EdgeInsets.only(bottom: _s(14)),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_s(18)),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ShopDetailScreen(shopId: shop.id.toString()),
              ),
            );
          },
          child: Ink(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Shop image banner (or gradient placeholder) ─────────────
                _buildShopBanner(
                  imageUrl: hasImage ? shop.shopImage : null,
                  isActive: shop.isActive,
                ),
                // ── Card body ───────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.all(_s(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shop.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: _sf(16.5),
                                fontWeight: FontWeight.w800,
                                color: AppColors.black,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          SizedBox(width: _s(8)),
                          _editButton(shop),
                        ],
                      ),
                      SizedBox(height: _s(8)),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: _s(15),
                            color: _kMuted,
                          ),
                          SizedBox(width: _s(5)),
                          Expanded(
                            child: Text(
                              shop.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: _sf(13),
                                color: _kMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _s(10)),
                      Row(
                        children: [
                          _avatarInitials(shopData.creatorName, roleColor),
                          SizedBox(width: _s(8)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shopData.creatorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: _sf(13),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.blue2,
                                  ),
                                ),
                                Text(
                                  'Created by',
                                  style: TextStyle(
                                    fontSize: _sf(11),
                                    color: _kMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _rolePill(shopData.creatorRole, roleColor),
                          SizedBox(width: _s(6)),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: _kMuted,
                            size: _s(20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modern image banner with a soft gradient overlay and a floating status
  // pill in the top-right. Falls back to a tinted brand-gradient placeholder
  // when the shop has no photo so cards still feel rich.
  Widget _buildShopBanner({required String? imageUrl, required bool isActive}) {
    final hasImage = imageUrl != null;
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: _s(120),
          child: hasImage
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _bannerFallback(),
                )
              : _bannerFallback(),
        ),
        // Bottom gradient — makes text float nicely if we ever overlay any.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
        ),
        // Floating status pill.
        Positioned(top: _s(10), right: _s(10), child: _statusPill(isActive)),
      ],
    );
  }

  Widget _bannerFallback() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          size: _s(40),
          color: Colors.white.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  Widget _statusPill(bool active) {
    final color = active ? _kPrimary : AppColors.red2;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _s(9), vertical: _s(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_s(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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

  Widget _editButton(dynamic shop) {
    return GestureDetector(
      onTap: () async {
        final updated = await context.push<bool>(
          '${AppRoutes.updateShop}/${shop.id}',
          extra: shop,
        );
        if (updated == true && mounted) {
          _loadShopsForSource(_selectedSource);
        }
      },
      child: Container(
        width: _s(32),
        height: _s(32),
        decoration: BoxDecoration(
          color: AppColors.green6,
          borderRadius: BorderRadius.circular(_s(10)),
        ),
        child: Icon(Icons.edit_outlined, size: _s(16), color: _kPrimary),
      ),
    );
  }

  Widget _avatarInitials(String name, Color color) {
    final initials = _initials(name);
    return Container(
      width: _s(32),
      height: _s(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_s(10)),
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: _sf(11.5),
          fontWeight: FontWeight.w800,
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

  Widget _rolePill(String role, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _s(8), vertical: _s(3)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_s(6)),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: _sf(10.5),
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return AppColors.red2;
      case 'Manager':
        return AppColors.blue;
      case 'Employee':
        return AppColors.green;
      default:
        return AppColors.grey;
    }
  }

  Widget _buildEmptyState() {
    final searching = _searchQuery.trim().isNotEmpty;
    return Center(
      child: _AnimatedEntry(
        index: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _s(96),
              height: _s(96),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                searching ? Icons.search_off_rounded : Icons.storefront_rounded,
                size: _s(46),
                color: _kPrimary.withValues(alpha: 0.55),
              ),
            ),
            SizedBox(height: SizeConfig.heightPercent(2)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _s(32)),
              child: Text(
                searching
                    ? 'No shops match "${_searchQuery.trim()}"'
                    : 'No shops yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _sf(15),
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
            SizedBox(height: _s(6)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _s(40)),
              child: Text(
                searching
                    ? 'Try a different name, address or creator.'
                    : 'Tap "Create Shop" to add your first store.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: _sf(12.5), color: _kMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades + slides its child up on first build, with a small per-index delay
/// so list items cascade in instead of popping in all at once.
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
