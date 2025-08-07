// To parse this JSON data, do
//
//     final user = userFromJson(jsonString);

import 'dart:convert';

UserModel userFromJson(String str) => UserModel.fromJson(json.decode(str));

String userToJson(UserModel data) => json.encode(data.toJson());

class UserModel {
  String accessToken;
  String refreshToken;
  User user;
  Organisation organisation;

  UserModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.organisation,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        accessToken: json["access_token"],
        refreshToken: json["refresh_token"],
        user: User.fromJson(json["user"]),
        organisation: Organisation.fromJson(json["organisation"]),
      );

  Map<String, dynamic> toJson() => {
        "access_token": accessToken,
        "refresh_token": refreshToken,
        "user": user.toJson(),
        "organisation": organisation.toJson(),
      };
}

class Organisation {
  int id;
  String uuid;
  int amount;
  String organisationName;
  String period;
  String year;
  String accountType;
  bool verified;
  String linkClientId;
  String bankAccountName;
  bool isSubscribed;
  String transactionCurrency;
  String transactionRef;
  DateTime createdAt;
  DateTime updatedAt;
  User user;
  CompanyDetails companyDetails;

  Organisation({
    required this.id,
    required this.uuid,
    required this.amount,
    required this.organisationName,
    required this.period,
    required this.year,
    required this.accountType,
    required this.verified,
    required this.linkClientId,
    required this.bankAccountName,
    required this.isSubscribed,
    required this.transactionCurrency,
    required this.transactionRef,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    required this.companyDetails,
  });

  factory Organisation.fromJson(Map<String, dynamic> json) => Organisation(
        id: json["id"],
        uuid: json["uuid"],
        amount: json["amount"],
        organisationName: json["organisation_name"],
        period: json["period"],
        year: json["year"],
        accountType: json["account_type"],
        verified: json["verified"],
        linkClientId: json["link_client_id"],
        bankAccountName: json["bank_account_name"],
        isSubscribed: json["is_subscribed"],
        transactionCurrency: json["transaction_currency"],
        transactionRef: json["transaction_ref"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        user: User.fromJson(json["user"]),
        companyDetails: CompanyDetails.fromJson(json["companyDetails"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "uuid": uuid,
        "amount": amount,
        "organisation_name": organisationName,
        "period": period,
        "year": year,
        "account_type": accountType,
        "verified": verified,
        "link_client_id": linkClientId,
        "bank_account_name": bankAccountName,
        "is_subscribed": isSubscribed,
        "transaction_currency": transactionCurrency,
        "transaction_ref": transactionRef,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "user": user.toJson(),
        "companyDetails": companyDetails.toJson(),
      };
}

class CompanyDetails {
  int id;
  String uuid;
  String companyName;
  String companyRegNumber;
  String kraPinNumber;
  String linkOrganisation;
  DateTime createdAt;
  DateTime updatedAt;
  String createdBy;
  String companyEmail;
  String companyPhoneNumber;
  String companyCertificate;
  String companyCr12Certificate;
  String kraComplianceCertificate;
  String directorsDetails;

  CompanyDetails({
    required this.id,
    required this.uuid,
    required this.companyName,
    required this.companyRegNumber,
    required this.kraPinNumber,
    required this.linkOrganisation,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.companyEmail,
    required this.companyPhoneNumber,
    required this.companyCertificate,
    required this.companyCr12Certificate,
    required this.kraComplianceCertificate,
    required this.directorsDetails,
  });

  factory CompanyDetails.fromJson(Map<String, dynamic> json) => CompanyDetails(
        id: json["id"],
        uuid: json["uuid"],
        companyName: json["companyName"],
        companyRegNumber: json["companyRegNumber"],
        kraPinNumber: json["kraPinNumber"],
        linkOrganisation: json["link_organisation"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        createdBy: json["created_by"],
        companyEmail: json["companyEmail"],
        companyPhoneNumber: json["companyPhoneNumber"],
        companyCertificate: json["company_certificate"],
        companyCr12Certificate: json["company_cr12_certificate"],
        kraComplianceCertificate: json["kra_compliance_certificate"],
        directorsDetails: json["directors_details"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "uuid": uuid,
        "companyName": companyName,
        "companyRegNumber": companyRegNumber,
        "kraPinNumber": kraPinNumber,
        "link_organisation": linkOrganisation,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "created_by": createdBy,
        "companyEmail": companyEmail,
        "companyPhoneNumber": companyPhoneNumber,
        "company_certificate": companyCertificate,
        "company_cr12_certificate": companyCr12Certificate,
        "kra_compliance_certificate": kraComplianceCertificate,
        "directors_details": directorsDetails,
      };
}

class User {
  int id;
  String uuid;
  String linkCompany;
  String linkUser;
  String revoked;
  String role;
  String? totpSecret;
  String primaryPhone;
  int walletAmount;
  String primaryEmail;
  bool smsToken;
  bool isAuthyApp;
  bool is2FaEnabled;
  bool emailToken;
  DateTime createdAt;
  DateTime updatedAt;
  String createdBy;
  String linkOrganisation;
  bool emailVerified;
  bool smsVerified;
  bool temporaryPassword;
  String linkTeam;
  DateTime joinedAt;
  String userIdentification;
  String userIdNumber;
  String userComplianceCertificate;
  String userComplianceCertificateNumber;
  bool active;
  bool spendingActive;
  String? fullName;
  String? username;

  User({
    required this.id,
    required this.uuid,
    required this.linkCompany,
    required this.linkUser,
    required this.revoked,
    required this.role,
    this.totpSecret,
    required this.primaryPhone,
    required this.walletAmount,
    required this.primaryEmail,
    required this.smsToken,
    required this.isAuthyApp,
    required this.is2FaEnabled,
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
    this.fullName,
    this.username,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        uuid: json["uuid"],
        linkCompany: json["link_company"],
        linkUser: json["link_user"],
        revoked: json["revoked"],
        role: json["role"],
        totpSecret: json["totpSecret"],
        primaryPhone: json["primary_phone"],
        walletAmount: json["wallet_amount"],
        primaryEmail: json["primary_email"],
        smsToken: json["sms_token"],
        isAuthyApp: json["is_authy_app"],
        is2FaEnabled: json["is_2fa_enabled"],
        emailToken: json["email_token"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        createdBy: json["created_by"],
        linkOrganisation: json["link_organisation"],
        emailVerified: json["email_verified"],
        smsVerified: json["sms_verified"],
        temporaryPassword: json["temporary_password"],
        linkTeam: json["link_team"],
        joinedAt: DateTime.parse(json["joined_at"]),
        userIdentification: json["user_identification"],
        userIdNumber: json["user_id_number"],
        userComplianceCertificate: json["user_compliance_certificate"],
        userComplianceCertificateNumber:
            json["user_compliance_certificate_number"],
        active: json["active"],
        spendingActive: json["spending_active"],
        fullName: json["full_name"],
        username: json["username"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "uuid": uuid,
        "link_company": linkCompany,
        "link_user": linkUser,
        "revoked": revoked,
        "role": role,
        "totpSecret": totpSecret,
        "primary_phone": primaryPhone,
        "wallet_amount": walletAmount,
        "primary_email": primaryEmail,
        "sms_token": smsToken,
        "is_authy_app": isAuthyApp,
        "is_2fa_enabled": is2FaEnabled,
        "email_token": emailToken,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "created_by": createdBy,
        "link_organisation": linkOrganisation,
        "email_verified": emailVerified,
        "sms_verified": smsVerified,
        "temporary_password": temporaryPassword,
        "link_team": linkTeam,
        "joined_at": joinedAt.toIso8601String(),
        "user_identification": userIdentification,
        "user_id_number": userIdNumber,
        "user_compliance_certificate": userComplianceCertificate,
        "user_compliance_certificate_number": userComplianceCertificateNumber,
        "active": active,
        "spending_active": spendingActive,
        "full_name": fullName,
        "username": username,
      };
}
