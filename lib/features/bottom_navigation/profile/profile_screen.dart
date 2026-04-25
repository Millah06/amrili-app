import 'package:everywhere/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<UserProvider>().user?.userId;
    print(currentUserId);
    if (currentUserId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Text(
            'Not logged in',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    // Navigate to UserProfileScreen with current user's ID
    return UserProfileScreen(userId: currentUserId, isOwnProfile: true);
  }
}