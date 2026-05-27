import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldguard/core/utils/phone_format.dart';
import 'edit_profile_screen.dart';
import '../providers/profile_provider.dart';
import '../providers/profile_state.dart';

class PersonalInformationScreen extends ConsumerStatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  ConsumerState<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends ConsumerState<PersonalInformationScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch profile when screen loads
    Future.microtask(
      () => ref.read(profileNotifierProvider.notifier).fetchProfile(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xff0E5A3B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Personal Information',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: profileState is ProfileLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xff0E5A3B),
              ),
            )
          : profileState is ProfileFailure
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: w * 0.15,
                        color: Colors.red.shade400,
                      ),
                      SizedBox(height: h * 0.02),
                      Text(
                        'Failed to load profile',
                        style: TextStyle(
                          fontSize: w * 0.045,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: h * 0.01),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
                        child: Text(
                          profileState.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: w * 0.035,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      SizedBox(height: h * 0.03),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref
                              .read(profileNotifierProvider.notifier)
                              .fetchProfile();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0E5A3B),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.08,
                            vertical: h * 0.015,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(w * 0.03),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : profileState is ProfileSuccess
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.all(w * 0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Image Section
                            Center(
                              child: Stack(
                                children: [
                                  Container(
                                    width: w * 0.35,
                                    height: w * 0.35,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xff0E5A3B),
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xff0E5A3B)
                                              .withValues(alpha: 0.2),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: profileState
                                                  .profile.profileImage !=
                                              null
                                          ? Image.network(
                                              profileState.profile.profileImage!.startsWith('http')
                                                  ? profileState.profile.profileImage!
                                                  : 'https://fieldguard-be.onrender.com/${profileState.profile.profileImage}',
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color:
                                                      const Color(0xffE5E7EB),
                                                  child: Icon(
                                                    Icons.person_rounded,
                                                    size: w * 0.15,
                                                    color:
                                                        const Color(0xff9CA3AF),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: const Color(0xffE5E7EB),
                                              child: Icon(
                                                Icons.person_rounded,
                                                size: w * 0.15,
                                                color: const Color(0xff9CA3AF),
                                              ),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: w * 0.1,
                                      height: w * 0.1,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xff0E5A3B),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.5,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.verified_rounded,
                                        color: Colors.white,
                                        size: w * 0.05,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: h * 0.04),

                            // Basic Information Card
                            _buildInfoCard(
                              w,
                              h,
                              'Basic Information',
                              [
                                _buildInfoRow(
                                  w,
                                  Icons.badge_rounded,
                                  'User ID',
                                  profileState.profile.id.toString(),
                                ),
                                _buildDivider(w),
                                _buildInfoRow(
                                  w,
                                  Icons.person_outline_rounded,
                                  'Full Name',
                                  profileState.profile.fullName,
                                ),
                                _buildDivider(w),
                                _buildInfoRow(
                                  w,
                                  Icons.phone_outlined,
                                  'Phone Number',
                                  formatNepaliPhone(profileState.profile.phoneNumber),
                                ),
                                _buildDivider(w),
                                _buildInfoRow(
                                  w,
                                  Icons.email_outlined,
                                  'Email',
                                  profileState.profile.email ?? 'N/A',
                                ),
                                _buildDivider(w),
                                _buildInfoRow(
                                  w,
                                  Icons.admin_panel_settings_rounded,
                                  'Role',
                                  profileState.profile.role.toUpperCase(),
                                ),
                                _buildDivider(w),
                                _buildInfoRow(
                                  w,
                                  Icons.qr_code_rounded,
                                  'Employee Code',
                                  profileState.profile.employeeCode,
                                ),
                                _buildDivider(w),
                                _buildInfoRow(
                                  w,
                                  profileState.profile.isActive
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.cancel_outlined,
                                  'Status',
                                  profileState.profile.isActive
                                      ? 'Active'
                                      : 'Inactive',
                                  valueColor: profileState.profile.isActive
                                      ? const Color(0xff0E5A3B)
                                      : Colors.red.shade600,
                                ),
                              ],
                            ),

                            SizedBox(height: h * 0.02),

                            // Company Information Card
                            if (profileState.profile.company != null)
                              _buildInfoCard(
                                w,
                                h,
                                'Company Information',
                                [
                                  _buildInfoRow(
                                    w,
                                    Icons.business_rounded,
                                    'Company Name',
                                    profileState.profile.company!.companyName,
                                  ),
                                  _buildDivider(w),
                                  _buildInfoRow(
                                    w,
                                    Icons.email_outlined,
                                    'Company Email',
                                    profileState.profile.company!.email ?? 'N/A',
                                  ),
                                  _buildDivider(w),
                                  _buildInfoRow(
                                    w,
                                    Icons.phone_in_talk_rounded,
                                    'Company Phone',
                                    profileState.profile.company!.phoneNumber == null
                                        ? 'N/A'
                                        : formatNepaliPhone(
                                            profileState.profile.company!.phoneNumber),
                                  ),
                                  _buildDivider(w),
                                  _buildInfoRow(
                                    w,
                                    Icons.fingerprint_rounded,
                                    'Company ID',
                                    profileState.profile.company!.companyUniqueId,
                                  ),
                                ],
                              ),

                            SizedBox(height: h * 0.02),

                            // Activity Information Card
                            _buildInfoCard(
                              w,
                              h,
                              'Activity Information',
                              [
                                _buildInfoRow(
                                  w,
                                  Icons.calendar_today_rounded,
                                  'Account Created',
                                  _formatDate(profileState.profile.createdAt),
                                ),
                                if (profileState.profile.lastLoginAt != null) ...[
                                  _buildDivider(w),
                                  _buildInfoRow(
                                    w,
                                    Icons.login_rounded,
                                    'Last Login',
                                    _formatDate(profileState.profile.lastLoginAt!),
                                  ),
                                ],
                              ],
                            ),

                            SizedBox(height: h * 0.03),

                            // Edit Profile Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProfileScreen(
                                        profile: profileState.profile,
                                      ),
                                    ),
                                  );
                                  
                                  // Refresh profile if update was successful
                                  if (result == true && mounted) {
                                    ref
                                        .read(profileNotifierProvider.notifier)
                                        .fetchProfile();
                                  }
                                },
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text('Edit Profile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff0E5A3B),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    vertical: h * 0.018,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(w * 0.03),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildInfoCard(
    double w,
    double h,
    String title,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(w * 0.045),
            child: Row(
              children: [
                Container(
                  width: w * 0.01,
                  height: w * 0.05,
                  decoration: BoxDecoration(
                    color: const Color(0xff0E5A3B),
                    borderRadius: BorderRadius.circular(w * 0.01),
                  ),
                ),
                SizedBox(width: w * 0.03),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: w * 0.045,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff111827),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    double w,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.045,
        vertical: w * 0.035,
      ),
      child: Row(
        children: [
          Container(
            width: w * 0.11,
            height: w * 0.11,
            decoration: BoxDecoration(
              color: const Color(0xff0E5A3B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(w * 0.03),
            ),
            child: Icon(
              icon,
              color: const Color(0xff0E5A3B),
              size: w * 0.055,
            ),
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: w * 0.032,
                    color: const Color(0xff6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: w * 0.01),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: w * 0.04,
                    color: valueColor ?? const Color(0xff111827),
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

  Widget _buildDivider(double w) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.045),
      child: Divider(
        color: const Color(0xffE5E7EB),
        thickness: 1,
        height: 1,
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
