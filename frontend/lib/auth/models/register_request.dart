class RegisterRequest {
  final String email;
  final String password;
  final String? inviteCode;
  final String verificationCode;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.verificationCode,
    this.inviteCode,
  });

  Map<String, dynamic> toJson() {
    final code = inviteCode;
    return {
      'email': email,
      'password': password,
      'verification_code': verificationCode,
      if (code != null && code.isNotEmpty) 'invite_code': code,
    };
  }
}
