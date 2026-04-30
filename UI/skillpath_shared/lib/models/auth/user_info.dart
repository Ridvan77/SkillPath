class UserInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final List<String> roles;
  final bool isActive;

  UserInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    required this.roles,
    required this.isActive,
  });

  String get fullName => '$firstName $lastName';

  bool get isAdmin => roles.contains('Admin');

  bool get isInstructor => roles.contains('Instructor');

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Constructs a [UserInfo] from JWT claims decoded from the access token.
  factory UserInfo.fromClaims(Map<String, dynamic> claims) {
    // ASP.NET Identity uses full URI claim keys
    final rolesClaim = claims['role'] ??
        claims['roles'] ??
        claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
    List<String> roles;
    if (rolesClaim is List) {
      roles = rolesClaim.map((e) => e.toString()).toList();
    } else if (rolesClaim is String) {
      roles = [rolesClaim];
    } else {
      roles = [];
    }

    final id = (claims['nameid'] ??
            claims['sub'] ??
            claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
            '')
        .toString();

    // Name may be a single "FirstName LastName" string
    final fullName = (claims['name'] ??
            claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ??
            '')
        .toString();
    final nameParts = fullName.split(' ');
    final firstName = claims['given_name'] ??
        claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname'] ??
        (nameParts.isNotEmpty ? nameParts.first : '');
    final lastName = claims['family_name'] ??
        claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname'] ??
        (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '');

    final email = (claims['email'] ??
            claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'] ??
            '')
        .toString();

    return UserInfo(
      id: id,
      firstName: firstName.toString(),
      lastName: lastName.toString(),
      email: email,
      phoneNumber: claims['phone_number'] as String?,
      profileImageUrl: claims['profile_image'] as String?,
      roles: roles,
      isActive: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'profileImageUrl': profileImageUrl,
        'roles': roles,
        'isActive': isActive,
      };
}
