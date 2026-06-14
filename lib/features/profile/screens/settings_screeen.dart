// lib/screens/settings_screen.dart - NEW

import 'package:everywhere/features/profile/screens/edit_profile.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../components/formatters.dart';
import '../../../components/swicht.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../models/notification_model.dart';
import '../../../providers/profile_provider.dart';
import '../../../screens/community_screen.dart';
import '../../../screens/pages/notification_screen.dart';
import '../../../screens/privacy_policy.dart';
import '../../../screens/welcome_screen.dart';
import '../../../services/brain.dart';
import '../../../services/session_service.dart';
import '../../../shared/functions/shared_functions.dart';
import '../../../shared/widgets/home_country_sheet.dart';
import '../../social/providers/reward_provider.dart';
import '../../support/help_center.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {



    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          const _SectionHeader(title: 'Account'),
          _SettingsTile(
            icon: Icons.person,
            title: 'Edit Profile',
            onTap: ()  async {
               final result = await Navigator.push(context,
                   MaterialPageRoute(builder: (context) => EditProfilePage()));

               if (result == true && context.mounted) {
                 final profileProvider = context.read<ProfileProvider>();
                 profileProvider.loadUserProfile(profileProvider.profile!.userId);
               }
            },
          ),
          _SettingsTile(
            icon: Icons.verified_user,
            title: 'KYC Verification',
            subtitle: 'Verify your identity',
            onTap: () {
              // Navigate to KYC
            },
          ),

          const SizedBox(height: 24),

          // Privacy Section
          const _SectionHeader(title: 'Privacy & Security'),
          _SettingsTile(
            icon: Icons.lock,
            title: 'Privacy Settings',
            subtitle: 'Control who can see your content',
            onTap: () {
              _showPrivacySettings(context, context.read<ProfileProvider>());
            },
          ),
          _SettingsTile(
            icon: Icons.block,
            title: 'Blocked Accounts',
            onTap: () {
              // Navigate to blocked accounts
            },
          ),

          const SizedBox(height: 24),

          // Preferences Section
          const _SectionHeader(title: 'Preferences'),
          _SettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder:
                  (context) => NotificationScreen()));
            },
          ),
          _SettingsTile(
            icon: Icons.public,
            title: 'Home Country',
            subtitle: 'Set the region Amril tailors services to',
            onTap: () => HomeCountrySheet.show(context),
          ),
          ListTile(
            title: const Text('Hide me from Spotlight', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Don’t show me on public creator/supporter boards',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            leading:
            TinySwitch(value: false,
                onChanged: (_) async {

                  showDialog(context: context,
                      barrierDismissible: false, builder: (_) => const Dialog(
                        backgroundColor: VendorTheme.background,
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: VendorTheme.circularProgressColor,),
                              SizedBox(width: 16),
                              Text("Toggling user privacy..."),
                            ],
                          ),
                        ),
                      ));
                  await context.read<RewardProvider>().toggleLeaderboardVisibility(true);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }

                }),

          ),
          _SettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            onTap: () {
              // Show language picker
            },
          ),

          const SizedBox(height: 24),

          // Support Section
          const _SectionHeader(title: 'Support'),
          _SettingsTile(
            icon: Icons.help,
            title: 'Help Center',
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => HelpCenter()));
            },
          ),
          _SettingsTile(
            icon: Icons.email,
            title: 'Contact Us',
            subtitle: 'support@everywhere.app',
            onTap: () {

              SharedFunctions.launchEmail('Nex Pay Support Center');
            },
          ),
          _SettingsTile(
            icon: Icons.feedback,
            title: 'Feed Back',
            onTap: () {

              SharedFunctions.launchEmail('Nex Pay Support Center');
            },
          ),

          _SettingsTile(
            icon: Icons.share,
            title: 'Share App',
            onTap: () async{
              await AppLinkHandler.shareAppLink();
            },
          ),
          _SettingsTile(
            icon: Icons.rate_review,
            title: 'Rate Us',
            onTap: () {
              AppLinkHandler.openInPlayStore();
            },
          ),
          _SettingsTile(
            icon: Icons.group,
            title: 'Join our Community',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder:
                  (context) => CommunityScreen()));
            },
          ),

          const SizedBox(height: 24),

          // About Section
          const _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.info,
            title: 'App Version',
            subtitle: _appVersion,
            onTap: null,
          ),
          _SettingsTile(
            icon: Icons.article,
            title: 'Terms of Service',
            onTap: () {
              // Open terms
            },
          ),
          _SettingsTile(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            onTap: () {
              // Open privacy policy
              Navigator.push(context, MaterialPageRoute(builder: (context)=>
                  PrivacyPolicyPage()));
            },
          ),

          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.red
                  )
                ),

              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showPrivacySettings(BuildContext context, ProfileProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>  _PrivacySettingsSheet(provider),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white),),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      Navigator.pop(context);
      // context.read<MyProfileProvider>().invalidate();
      final prefs = await SharedPreferences.getInstance();
      await FirebaseAuth.instance.signOut();

      await prefs.setBool('isSetupDone', false);
      await prefs.remove('isGuest');
      await Hive.box<AppNotification>('notifications').clear();
      Provider.of<Brain>(context, listen: false).reset();
      Provider.of<SessionProvider>(context, listen: false).logout();
      Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => WelcomeScreen()),
            (route) => false,);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF177E85),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF177E85)),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
            subtitle!,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          )
              : null,
          trailing: onTap != null
              ? const Icon(Icons.chevron_right, color: Colors.grey)
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _PrivacySettingsSheet extends StatefulWidget {

  final ProfileProvider provider;
  const _PrivacySettingsSheet(this.provider);

  @override
  State<_PrivacySettingsSheet> createState() => _PrivacySettingsSheetState();
}

class _PrivacySettingsSheetState extends State<_PrivacySettingsSheet> {


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            ListTile(

              title: const Text(
                'Private Account',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Only approved followers can see your posts',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              leading:
              TinySwitch(value:
              provider.profile?.isPrivate ?? false,
                  onChanged: (_) async {

                showDialog(context: context,
                    barrierDismissible: false, builder: (_) => const Dialog(
                      backgroundColor: VendorTheme.background,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: VendorTheme.circularProgressColor,),
                            SizedBox(width: 16),
                            Text("Toggling user privacy..."),
                          ],
                        ),
                      ),
                    ));
                await widget.provider.togglePrivateAccount();
                if (context.mounted) {
                  Navigator.pop(context);
                }

              }),
            ),


            const SizedBox(height: 16),

            ListTile(

              title: const Text(
                'Allow Followers to Message',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Let your followers send you messages',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              leading: TinySwitch(value: provider.profile?.allowFollowersToMessage ?? true, onChanged: (_) async {

                showDialog(context: context,
                    barrierDismissible: false, builder: (_) => const Dialog(
                      backgroundColor: VendorTheme.background,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: VendorTheme.circularProgressColor,),
                            SizedBox(width: 16),
                            Text("Toggling user privacy..."),
                          ],
                        ),
                      ),
                    ));
                await widget.provider.toggleAllowFollowersToMessage();
                if (context.mounted) {
                  Navigator.pop(context);
                }

              }),
            ),
          ],
        ),
      ),
    );
  }
}