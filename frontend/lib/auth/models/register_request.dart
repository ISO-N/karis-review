class RegisterRequest {
  final String email;
  final String password;
  final String? inviteCode;

  RegisterRequest({
    required this.email,
    required this.password,
    this.inviteCode,
  });

  Map<String, dynamic> toJson() {
    final code = inviteCode;
    return {
      'email': email,
      'password': password,
      if (code != null && code.isNotEmpty) 'invite_code': code,
    };
  }
}
