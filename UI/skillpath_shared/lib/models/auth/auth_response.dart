class AuthResponse {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final List<String> roles;
  final String accessToken;
  final String refreshToken;
  final DateTime tokenExpiration;

  AuthResponse({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.roles,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenExpiration,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['userId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      tokenExpiration: json['tokenExpiration'] != null
          ? DateTime.parse(json['tokenExpiration'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'roles': roles,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'tokenExpiration': tokenExpiration.toIso8601String(),
      };
}
