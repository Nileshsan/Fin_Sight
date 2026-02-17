import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/index.dart';
import '../../../providers/index.dart';
import '../../../providers/user_profile_provider.dart';

/// Profile Screen - Comprehensive User Profile & Account Management
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    // Initialize with empty values - will be populated from provider
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    
    // Fetch profile data after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  void _loadProfileData() async {
    try {
      final profile = await ref.read(userProfileProvider.future);
      if (mounted) {
        setState(() {
          _nameController.text = '${profile.firstName} ${profile.lastName}';
          _emailController.text = profile.email;
          _phoneController.text = profile.phone ?? '+91 98765 43210';
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      // Keep default values on error
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: colors.surface,
          title: const Text('My Profile'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: TabBar(
              labelColor: colors.primary,
              unselectedLabelColor: colors.outline,
              indicatorColor: colors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: const [
                Tab(
                  text: 'Profile',
                  icon: Icon(Icons.person_rounded),
                ),
                Tab(
                  text: 'Preferences',
                  icon: Icon(Icons.tune_rounded),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildProfileTab(context, colors, textTheme),
            _buildPreferencesTab(context, colors, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(
      BuildContext context, ColorScheme colors, TextTheme textTheme) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.error),
            const SizedBox(height: 12),
            Text('Error loading profile', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(err.toString(), style: textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
      data: (profile) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Avatar Section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [colors.primary, colors.secondary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${profile.firstName[0]}${profile.lastName[0]}',
                        style: textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${profile.firstName} ${profile.lastName}',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🟢 Active Member',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Company Card
            _buildCompanyCard(colors, textTheme, profile),
            const SizedBox(height: 24),

            // Account Information
            Text(
              'Account Information',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (!_isEditing) ...[
              _buildDetailCard(
                label: 'Email Address',
                value: profile.email,
                icon: Icons.email_rounded,
                colors: colors,
                textTheme: textTheme,
              ),
              const SizedBox(height: 12),
              _buildDetailCard(
                label: 'Phone Number',
                value: profile.phone ?? 'Not provided',
                icon: Icons.phone_rounded,
                colors: colors,
                textTheme: textTheme,
              ),
              const SizedBox(height: 12),
              _buildDetailCard(
                label: 'Account Type',
                value: profile.role,
                icon: Icons.verified_rounded,
                colors: colors,
                textTheme: textTheme,
              ),
              const SizedBox(height: 12),
              _buildDetailCard(
                label: 'Company',
                value: profile.company ?? 'Not assigned',
                icon: Icons.business_rounded,
                colors: colors,
                textTheme: textTheme,
              ),
            ] else ...[
              _buildEditableField(
                label: 'Full Name',
                controller: _nameController,
                colors: colors,
                textTheme: textTheme,
              ),
              const SizedBox(height: 16),
            _buildEditableField(
              label: 'Email Address',
              controller: _emailController,
              colors: colors,
              textTheme: textTheme,
            ),
            const SizedBox(height: 16),
            _buildEditableField(
              label: 'Phone Number',
              controller: _phoneController,
              colors: colors,
              textTheme: textTheme,
            ),
          ],
          const SizedBox(height: 24),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() => _isEditing = !_isEditing);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isEditing ? Icons.check_rounded : Icons.edit_rounded),
                  const SizedBox(width: 8),
                  Text(
                    _isEditing ? 'Save Changes' : 'Edit Profile',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.transparent,
                side: BorderSide(color: colors.outline.withOpacity(0.5)),
              ),
              onPressed: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded),
                  const SizedBox(width: 8),
                  Text(
                    'Change Password',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab(
      BuildContext context, ColorScheme colors, TextTheme textTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notifications
          Text(
            'Notifications',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildToggleTile(
            'Payment Alerts',
            'Get notified about upcoming payments',
            true,
            colors,
            textTheme,
          ),
          const SizedBox(height: 12),
          _buildToggleTile(
            'Discount Opportunities',
            'Receive alerts for potential discounts',
            true,
            colors,
            textTheme,
          ),
          const SizedBox(height: 12),
          _buildToggleTile(
            'Cashflow Updates',
            'Get alerts for cashflow changes',
            true,
            colors,
            textTheme,
          ),
          const SizedBox(height: 24),

          // Display
          Text(
            'Display Preferences',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildToggleTile(
            'Dark Mode',
            'Use dark theme for the application',
            false,
            colors,
            textTheme,
          ),
          const SizedBox(height: 12),
          _buildToggleTile(
            'Compact View',
            'Use compact layout for dashboards',
            false,
            colors,
            textTheme,
          ),
          const SizedBox(height: 24),

          // Data & Security
          Text(
            'Data & Security',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            'Export My Data',
            'Download all your data in CSV format',
            Icons.download_rounded,
            colors,
            textTheme,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            'Privacy Policy',
            'View our privacy policy and terms',
            Icons.privacy_tip_rounded,
            colors,
            textTheme,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(ColorScheme colors, TextTheme textTheme, UserProfileData profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withOpacity(0.1),
            colors.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.business_rounded,
                  color: colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prophetic Business Solutions',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'CFO Services | FinSight',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String label,
    required String value,
    required IconData icon,
    required ColorScheme colors,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outline.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: textTheme.titleSmall?.copyWith(
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

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required ColorScheme colors,
    required TextTheme textTheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.outline,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.outline.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.outline.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleTile(
    String title,
    String subtitle,
    bool initialValue,
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool value = initialValue;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: value,
                onChanged: (newValue) {
                  setState(() => value = newValue);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    ColorScheme colors,
    TextTheme textTheme, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outline.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: colors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: colors.outline),
          ],
        ),
      ),
    );
  }
}
              ),
              const SizedBox(height: 24),

              // Name
              _buildEditableField(
                label: 'Name',
                controller: _nameController,
                isEditing: _isEditing,
              ),
              const SizedBox(height: 16),

              // Email
              _buildEditableField(
                label: 'Email',
                controller: _emailController,
                isEditing: _isEditing,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Phone
              _buildEditableField(
                label: 'Phone',
                controller: _phoneController,
                isEditing: _isEditing,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),

              // Account Settings
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Account Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Change Password
              _buildSettingsTile(
                title: 'Change Password',
                icon: Icons.lock,
                onTap: () {
                  // Show change password dialog
                },
              ),
              const SizedBox(height: 8),

              // Two Factor Auth
              _buildSettingsTile(
                title: 'Two Factor Authentication',
                icon: Icons.security,
                onTap: () {},
              ),
              const SizedBox(height: 8),

              // Connected Devices
              _buildSettingsTile(
                title: 'Connected Devices',
                icon: Icons.devices,
                onTap: () {},
              ),
              const SizedBox(height: 32),

              // Danger Zone
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Danger Zone',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Delete Account
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.error),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: () {
                    // Show delete confirmation
                  },
                  child: const Center(
                    child: Text(
                      'Delete Account',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: isEditing,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: !isEditing,
            fillColor: !isEditing ? AppColors.gray100 : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}
