class ReservationDto {
  final String id;
  final String reservationCode;
  final String userId;
  final String userFullName;
  final String courseScheduleId;
  final String courseName;
  final String? courseImageUrl;
  final String instructorName;
  final String scheduleDay;
  final String scheduleTime;
  final String status;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final double totalAmount;
  final String? stripePaymentIntentId;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final double? refundAmount;
  final DateTime? refundedAt;

  ReservationDto({
    required this.id,
    required this.reservationCode,
    required this.userId,
    required this.userFullName,
    required this.courseScheduleId,
    required this.courseName,
    this.courseImageUrl,
    required this.instructorName,
    required this.scheduleDay,
    required this.scheduleTime,
    required this.status,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.totalAmount,
    this.stripePaymentIntentId,
    required this.createdAt,
    this.cancelledAt,
    this.cancellationReason,
    this.refundAmount,
    this.refundedAt,
  });

  bool get isCancelled => status == 'Cancelled';

  bool get isConfirmed => status == 'Confirmed';

  factory ReservationDto.fromJson(Map<String, dynamic> json) {
    return ReservationDto(
      id: json['id'] as String? ?? '',
      reservationCode: json['reservationCode'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userFullName: json['userFullName'] as String? ?? '',
      courseScheduleId: json['courseScheduleId'] as String? ?? '',
      courseName: json['courseName'] as String? ?? '',
      courseImageUrl: json['courseImageUrl'] as String?,
      instructorName: json['instructorName'] as String? ?? '',
      scheduleDay: json['scheduleDay'] as String? ?? '',
      scheduleTime: json['scheduleTime'] as String? ?? '',
      status: json['status'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      stripePaymentIntentId: json['stripePaymentIntentId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      refundedAt: json['refundedAt'] != null
          ? DateTime.parse(json['refundedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reservationCode': reservationCode,
        'userId': userId,
        'userFullName': userFullName,
        'courseScheduleId': courseScheduleId,
        'courseName': courseName,
        'courseImageUrl': courseImageUrl,
        'instructorName': instructorName,
        'scheduleDay': scheduleDay,
        'scheduleTime': scheduleTime,
        'status': status,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'totalAmount': totalAmount,
        'stripePaymentIntentId': stripePaymentIntentId,
        'createdAt': createdAt.toIso8601String(),
        'cancelledAt': cancelledAt?.toIso8601String(),
        'cancellationReason': cancellationReason,
        'refundAmount': refundAmount,
        'refundedAt': refundedAt?.toIso8601String(),
      };
}
