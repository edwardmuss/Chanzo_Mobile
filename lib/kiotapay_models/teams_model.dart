
class Team {
  final int id;
  final String uuid;
  final String name;
  final String description;
  final String linkProject;
  final String createdBy;
  final String linkOrganisation;
  final bool isAdmin;
  final bool isActive;
  final int teamLimit;
  final int teamSpentAmount;
  final String createdAt;
  final String updatedAt;
  final List<User> users;
  final List<Project> projects;
  final int teamAmount;

  Team({
    required this.id,
    required this.uuid,
    required this.name,
    required this.description,
    required this.linkProject,
    required this.createdBy,
    required this.linkOrganisation,
    required this.isAdmin,
    required this.isActive,
    required this.teamLimit,
    required this.teamSpentAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.users,
    required this.projects,
    required this.teamAmount,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: _parseInt(json['id']),
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      linkProject: json['link_project'] ?? '',
      createdBy: json['created_by'] ?? '',
      linkOrganisation: json['link_organisation'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      isActive: json['isActive'] ?? false,
      teamLimit: _parseInt(json['team_limit']),
      teamSpentAmount: _parseInt(json['team_spent_amount']),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      users: (json['users'] as List? ?? []).map((user) => User.fromJson(user)).toList(),
      projects: (json['projects'] as List? ?? []).map((project) => Project.fromJson(project)).toList(),
      teamAmount: _parseInt(json['team_amount']),
    );
  }
}

class User {
  final int id;
  final String uuid;
  final String tsid;
  final String linkCompany;
  final String linkUser;
  final String revoked;
  final String role;
  final String totpSecret;
  final String primaryPhone;
  final String primaryEmail;
  final bool smsToken;
  final bool isAuthyApp;
  final bool is2faEnabled;
  final bool emailToken;
  final String createdAt;
  final String updatedAt;
  final String createdBy;
  final String linkOrganisation;
  final bool emailVerified;
  final bool smsVerified;
  final bool temporaryPassword;
  final String linkTeam;
  final String joinedAt;
  final String userIdentification;
  final String userIdNumber;
  final String userComplianceCertificate;
  final String userComplianceCertificateNumber;
  final bool active;
  final bool spendingActive;
  final int walletAmount;
  final ClientData clientData;

  User({
    required this.id,
    required this.uuid,
    required this.tsid,
    required this.linkCompany,
    required this.linkUser,
    required this.revoked,
    required this.role,
    required this.totpSecret,
    required this.primaryPhone,
    required this.primaryEmail,
    required this.smsToken,
    required this.isAuthyApp,
    required this.is2faEnabled,
    required this.emailToken,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.linkOrganisation,
    required this.emailVerified,
    required this.smsVerified,
    required this.temporaryPassword,
    required this.linkTeam,
    required this.joinedAt,
    required this.userIdentification,
    required this.userIdNumber,
    required this.userComplianceCertificate,
    required this.userComplianceCertificateNumber,
    required this.active,
    required this.spendingActive,
    required this.walletAmount,
    required this.clientData,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseInt(json['id']),
      uuid: json['uuid'] ?? '',
      tsid: json['tsid'] ?? '',
      linkCompany: json['link_company'] ?? '',
      linkUser: json['link_user'] ?? '',
      revoked: json['revoked'] ?? '',
      role: json['role'] ?? '',
      totpSecret: json['totpSecret'] ?? '',
      primaryPhone: json['primary_phone'] ?? '',
      primaryEmail: json['primary_email'] ?? '',
      smsToken: json['sms_token'] ?? false,
      isAuthyApp: json['is_authy_app'] ?? false,
      is2faEnabled: json['is_2fa_enabled'] ?? false,
      emailToken: json['email_token'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      createdBy: json['created_by'] ?? '',
      linkOrganisation: json['link_organisation'] ?? '',
      emailVerified: json['email_verified'] ?? false,
      smsVerified: json['sms_verified'] ?? false,
      temporaryPassword: json['temporary_password'] ?? false,
      linkTeam: json['link_team'] ?? '',
      joinedAt: json['joined_at'] ?? '',
      userIdentification: json['user_identification'] ?? '',
      userIdNumber: json['user_id_number'] ?? '',
      userComplianceCertificate: json['user_compliance_certificate'] ?? '',
      userComplianceCertificateNumber: json['user_compliance_certificate_number'] ?? '',
      active: json['active'] ?? false,
      spendingActive: json['spending_active'] ?? false,
      walletAmount: _parseInt(json['wallet_details']?['wallet_amount']),
      clientData: ClientData.fromJson(json['client_data'] ?? {}),
    );
  }
}

class Project {
  final int id;
  final String uuid;
  final String projectName;
  final String linkOrganisation;
  final String description;
  final String createdBy;
  final bool isActive;
  final int projectEstAmount;
  final int projectAmount;
  final String status;
  final String createdAt;
  final String updatedAt;

  Project({
    required this.id,
    required this.uuid,
    required this.projectName,
    required this.linkOrganisation,
    required this.description,
    required this.createdBy,
    required this.isActive,
    required this.projectEstAmount,
    required this.projectAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: _parseInt(json['id']),
      uuid: json['uuid'] ?? '',
      projectName: json['project_name'] ?? '',
      linkOrganisation: json['link_organisation'] ?? '',
      description: json['description'] ?? '',
      createdBy: json['created_by'] ?? '',
      isActive: json['isActive'] ?? false,
      projectEstAmount: _parseInt(json['project_est_amount']),
      projectAmount: _parseInt(json['project_amount']),
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class ClientData {
  final String username;
  final String fullName;
  final String phone;
  final String nationalId;
  final String email;

  ClientData({
    required this.username,
    required this.fullName,
    required this.phone,
    required this.nationalId,
    required this.email,
  });

  factory ClientData.fromJson(Map<String, dynamic> json) {
    return ClientData(
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      nationalId: json['national_id'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  } else if (value is double) {
    return value.toInt();
  } else if (value is String) {
    return int.tryParse(value) ?? 0;
  } else {
    return 0;
  }
}
