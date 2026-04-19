class AppAuthUser {
  const AppAuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
  });

  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
}

