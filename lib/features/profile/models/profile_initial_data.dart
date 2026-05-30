/// Lightweight data passed when navigating to a user's profile
/// from the feed, chat, or search. Enables instant header rendering
/// before the full profile loads from the server.
class ProfileInitialData {
  final String userId;
  final String? userName;
  final String? displayName;
  final String? avatar;
  final bool? isVerified;

  const ProfileInitialData({
    required this.userId,
    this.userName,
    this.displayName,
    this.avatar,
    this.isVerified,
  });
}