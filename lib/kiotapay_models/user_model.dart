class User {
  final int id;
  final String uuid;
  final String role;
  final String primaryPhone;
  final String primaryEmail;
  final bool isAuthyApp;
  final bool is2faEnabled;
  final bool emailVerified;
  final bool smsVerified;
  final bool temporaryPassword;
  final String joinedAt;
  final String userIdentification;
  final String userIdNumber;
  final String userComplianceCertificate;
  final String userComplianceCertificateNumber;
  final bool active;
  final bool spendingActive;
  final ClientData clientData;

  User({
    required this.id,
    required this.uuid,
    required this.role,
    required this.primaryPhone,
    required this.primaryEmail,
    required this.isAuthyApp,
    required this.is2faEnabled,
    required this.emailVerified,
    required this.smsVerified,
    required this.temporaryPassword,
    required this.joinedAt,
    required this.userIdentification,
    required this.userIdNumber,
    required this.userComplianceCertificate,
    required this.userComplianceCertificateNumber,
    required this.active,
    required this.spendingActive,
    required this.clientData,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      uuid: json['uuid'],
      role: json['role'],
      primaryPhone: json['primary_phone'],
      primaryEmail: json['primary_email'],
      isAuthyApp: json['is_authy_app'],
      is2faEnabled: json['is_2fa_enabled'],
      emailVerified: json['email_verified'],
      smsVerified: json['sms_verified'],
      temporaryPassword: json['temporary_password'],
      joinedAt: json['joined_at'],
      userIdentification: json['user_identification'],
      userIdNumber: json['user_id_number'],
      userComplianceCertificate: json['user_compliance_certificate'],
      userComplianceCertificateNumber:
          json['user_compliance_certificate_number'],
      active: json['active'],
      spendingActive: json['spending_active'],
      clientData: ClientData.fromJson(json['clientData']),
    );
  }
}

class ClientData {
  final String username;
  final String fullName;
  final String phone;
  final String? email;
  final String nationalId;

  ClientData({
    this.email,
    required this.username,
    required this.fullName,
    required this.phone,
    required this.nationalId,
  });

  factory ClientData.fromJson(Map<String, dynamic> json) {
    return ClientData(
      email: json['email'],
      username: json['username'],
      fullName: json['full_name'],
      phone: json['phone'],
      nationalId: json['national_id'],
    );
  }
}
