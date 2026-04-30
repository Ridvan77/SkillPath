class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? phoneNumber;
  final int? cityId;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.cityId,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
    };
    if (phoneNumber != null) json['phoneNumber'] = phoneNumber;
    if (cityId != null) json['cityId'] = cityId;
    return json;
  }
}
