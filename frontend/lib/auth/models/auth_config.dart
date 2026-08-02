class AuthConfig {
  final bool inviteCodeRequired;

  const AuthConfig({required this.inviteCodeRequired});

  factory AuthConfig.fromJson(Map<String, dynamic> json) {
    return AuthConfig(
      inviteCodeRequired: json['invite_code_required'] as bool? ?? false,
    );
  }
}
