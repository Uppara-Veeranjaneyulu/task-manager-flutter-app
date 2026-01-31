class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String provider;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool notificationsEnabled;
  final bool taskReminders;
  final bool dailySummary;
  final String theme;
  final String defaultList;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.provider,
    required this.createdAt,
    required this.lastLoginAt,
    required this.notificationsEnabled,
    required this.taskReminders,
    required this.dailySummary,
    required this.theme,
    required this.defaultList,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      provider: data['provider'] ?? '',
      createdAt: data['createdAt'].toDate(),
      lastLoginAt: data['lastLoginAt'].toDate(),
      notificationsEnabled: data['notifications']['enabled'] ?? true,
      taskReminders: data['notifications']['taskReminders'] ?? true,
      dailySummary: data['notifications']['dailySummary'] ?? false,
      theme: data['preferences']['theme'] ?? 'system',
      defaultList: data['preferences']['defaultList'] ?? 'My Tasks',
    );
  }
}
