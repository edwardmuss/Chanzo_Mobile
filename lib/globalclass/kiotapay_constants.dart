import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'AppEnv.dart';

class KiotaPayConstants {
  static const _secure = FlutterSecureStorage();

  static final String currency = "KES ";
  static final bool isLive = true;

  /// Mutable baseUrl (changes when country changes)
  static String baseUrl = isLive
      ? 'https://app.chanzo.co.ke/api/v1/'
      : 'https://diamonds-item-motivation-gdp.trycloudflare.com/api/v1/';

  /// Always derived from baseUrl
  static String get webUrl => baseUrl.replaceAll(RegExp(r'api/v1/$'), '');
  static String get fileBaseUrl => '${webUrl}storage/';

  /// AI base (if also country-based later, make it dynamic too)
  static String aiUrl = 'https://ai.chanzo.co.ke/api/v1/';

  // ---------------- AI Endpoints (GETTERS) ----------------
  static String get fetchSessions => '${aiUrl}users';
  static String get loadMessagesFromSession => '${aiUrl}sessions';
  static String get sendMessage => '${aiUrl}chat';

  // ---------------- Authentication (GETTERS) ----------------
  static String get login => '${baseUrl}auth/login';
  static String get getUserProfile => '${baseUrl}auth/profile';
  static String get logout => '${baseUrl}auth/logout';
  static String get forgotPassword => '${baseUrl}auth/forgot-password';
  static String get changePassword => '${baseUrl}auth/change-password';
  static String get changePasswordNewUser => '${baseUrl}auth/change-password/new-user';
  static String get verifyUserPassword => '${baseUrl}auth/verify-user-password';
  static String get contextGet => '${baseUrl}auth/context';
  static String get contextSwitch => '${baseUrl}auth/context/switch';

  // ---------------- Finance and Fee Management (GETTERS) ----------------
  static String get getStudentFee => '${baseUrl}fees/student';
  static String get getStudentFeePdf => '${baseUrl}fees/structure/generate';
  static String get getStudentFeeReceiptPdf => '${baseUrl}fees/structure/generate/receipt';
  static String get getRecentPayments => '${baseUrl}fees/student-payments/{student_id}';
  static String get getRecentYearlyPayments => '${baseUrl}fees/student-payments/monthly/{student_id}';
  static String get getPaymentsMethods => '${baseUrl}fees/payment-settings';
  static String get kcbStkPush => '${baseUrl}fees/payments/buni-stk-push-initiate';
  static String get mpesaPaybillStkPush => '${baseUrl}fees/payments/top-up/mpesa';
  static String get stkPushStatus => '${baseUrl}fees/payments/check-transaction-status';

  // ---------------- Timetable (GETTERS) ----------------
  static String get getStudentTimetable => '${baseUrl}timetable/student';
  static String get getTeacherTimetable => '${baseUrl}timetable/teacher';

  // ---------------- Attendance (GETTERS) ----------------
  static String get getStudentAttendance => '${baseUrl}attendance/student';

  // ---------------- Resource Center (GETTERS) ----------------
  static String get getResourceCenter => '${baseUrl}resource-center';

  // ---------------- Homework (GETTERS) ----------------
  static String get getStudentHomeWork => '${baseUrl}homework';
  static String get getStudentHomeWorkSubmissions => '${baseUrl}homework-submissions/:homeworkId';
  static String get submitStudentHomeWork => '${baseUrl}homeworks/submit/:homeworkId';

  // ---------------- Notice Board (GETTERS) ----------------
  static String get getNotices => '${baseUrl}notice-board';

  // ---------------- Calendar (GETTERS) ----------------
  static String get getCalendar => '${baseUrl}calendar';

  // ---------------- Notifications (GETTERS) ----------------
  static String get getNotifications => '${baseUrl}notifications';
  static String get sendNotificationTokens => '${baseUrl}notifications/device-tokens/send';

  // ---------------- Examination (GETTERS) ----------------
  static String get getStudentPerformance => '${baseUrl}exams/student-exam-performance';
  static String get getStudentExamTrend => '${baseUrl}exams/student-exam-trend';
  static String get getStudentExamReport => '${baseUrl}exams/reports/:student_id';

  // ---------------- Academic Sessions (GETTERS) ----------------
  static String get getAllAcademicSessionsByBranch => '${baseUrl}academic-sessions/:branch_id/branch';
  static String get getStudentAcademicSessions => '${baseUrl}academic-sessions/:student_id/student';

static final String getHash = baseUrl + 'auth/mobile/global/hash/login';
  static final String faceIdLogin = baseUrl + 'auth/mobile/global/login';
  static final String multiAccountLogin =
      baseUrl + 'auth/multi-account/mobile/login';
  static final String getUserAccounts = baseUrl + 'auth/multi-account/accounts';
  static final String switchUserAccounts =
      baseUrl + 'auth/multi-account/switch/mobile';
  static final String updateProfile = baseUrl + 'subusers/single/update';
  static final String verifyCode = baseUrl + 'subusers/verify/code';
  static final String selfOnboard = baseUrl + 'subusers/self/onboard';
  static final String refreshToken = baseUrl + 'auth/token/refresh';
  static final String checkUserHasPin = baseUrl + 'auth/pin-present';
  static final String createUserPin = baseUrl + 'auth/create-mobile/pin';
  static final String forgotUserPin = baseUrl + 'auth/forgot-pin';
  static final String verifyUserPin = baseUrl + 'auth/verify/pin';
  static final String resetUserPin = baseUrl + 'auth/reset-mobile/pin';
  static final String generateForgotPasswordOtp =
      baseUrl + 'user/forgot-password/mobile';
  static final String confirmPasswordOtp =
      baseUrl + 'user/confirm/forgot-password/mobile';
  static final String userWallet = baseUrl + 'user/wallet';
  static final String resetPassword =
      baseUrl + 'user/forgot-password-reset/new';
  static final String orgWallet = baseUrl + 'organisation/wallet/balance';
  static final String orgWalletStats = baseUrl + 'organisation/wallet/balance';
  static final String getTransactionCost =
      baseUrl + 'allocations/verify-spending-amount';
  static final String initiatePayout = baseUrl + 'payouts/initiate/mobile';
  static final String getRecentTransactions = baseUrl + 'payouts/transactions';
  static final String pinVerifyTransactions =
      baseUrl + 'payouts/transaction/mobile-pin/verify';
  static final String pinVerifyAirtime =
      baseUrl + 'airtime/transaction/mobile-pin/verify';
  static final String biometricVerifyTransactions =
      baseUrl + 'payouts/transaction/mobile-fingerprint/verify';
  static final String biometricVerifyAirtime =
      baseUrl + 'airtime/transaction/mobile-fingerprint/verify';
  static final String reVerifyTransactions =
      baseUrl + 'payouts/transaction/reverify/mobile';
  static final String reverseTransactions =
      baseUrl + 'payouts/transaction/single/reverse';
  static final String uploadReceipt = baseUrl + 'payouts/receipt/upload';
  static final String updateReceipt = baseUrl + 'payouts/receipt/update/upload';
  static final String initiateTransactionRequest = baseUrl + 'transaction-request/new/request/mobile';
  static final String verifyTransactionRequestPin = baseUrl + 'transaction-request/new/request/verify';
  static final String transactionRequestAll = baseUrl + 'transaction-request/all';
  static final String transactionRequestSingle = baseUrl + 'transaction-request/single';
  static final String approveTransactionRequestSingle = baseUrl + 'transaction-request/approve/single';
  static final String disApproveTransactionRequestSingle = baseUrl + 'transaction-request/disapprove/single';
  static final String viewReceipt =
      baseUrl + 'payouts/receipt/transaction/single';
  static final String allocationRequestAll = baseUrl + 'allocations/request/type/all';
  static final String getAllCurrentUserTransactions =
      baseUrl + 'payouts/transactions/current-user/all/mobile';
  static final String getSingleTransaction =
      baseUrl + 'payouts/transaction/single';
  static final String Airtime = baseUrl + 'airtime/at/request';
  static final String getAllBanks = baseUrl + 'transactions/banks';
  static final String requestMyAllocation = baseUrl + 'allocations/request/new';
  static final String requestAllocationForOther = baseUrl + 'allocations/request/another-individual';
  static final String getSingleAllocation = baseUrl + 'allocations/request/single';
  static final String getAllTeams = baseUrl + 'team/all';
  static final String getApprover = baseUrl + 'transaction-request/approvers/all';
  static final String getAllocationApprover = baseUrl + 'api/v1/allocations/request/approvers/all';
  static final String approveSingleAllocation = baseUrl + 'allocations/request/approve';
  static final String disapproveSingleAllocation = baseUrl + 'allocations/request/disapprove';
  static final String getCurrentUser2TeamProjects =
      baseUrl + 'team/projects/all';
  static final String addTeam = baseUrl + 'team/add';
  static final String updateTeam = baseUrl + 'team/update';
  static final String updateTeamLimit = baseUrl + 'team/update-limit';
  static final String allocateMemberMoney = baseUrl + 'allocations/new';
  static final String deAllocateMemberMoney =
      baseUrl + 'allocations/de-allocate';
  static final String deleteTeam = baseUrl + 'team/delete';
  static final String getProjects = baseUrl + 'projects/all';
  static final String addProject = baseUrl + 'projects/add';
  static final String updateProject = baseUrl + 'projects/update';
  static final String updateStatusProject = baseUrl + 'projects/update/status';
  static final String deleteProject = baseUrl + 'projects/delete';
  static final String getAllCategories = baseUrl + 'category/all';
  static final String getSingleCategories = baseUrl + 'category/single';
  static final String addCategories = baseUrl + 'category/new';
  static final String updateCategories = baseUrl + 'category/update';
  static final String addSubCategories = baseUrl + 'category/subcategory/new';
  static final String updateSubCategories =
      baseUrl + 'category/subcategory/update';
  static final String deleteCategories = baseUrl + 'category/delete';
  static final String deleteSubCategories =
      baseUrl + 'category/subcategory/delete';
  static final String getFavorites = baseUrl + 'favourites/type/all';
  static final String getAllFavorites = baseUrl + 'favourites/all';
  static final String addFavorites = baseUrl + 'favourites/add';
  static final String updateFavorites = baseUrl + 'favourites/update';
  static final String deleteFavorites = baseUrl + 'favourites/delete';
  static final String loadDetails =
      baseUrl + 'organisation/company/load-details';

  // ---------------- Country helpers ----------------
  static Future<void> setCountry(String code) async {
    final url = AppEnv.baseUrls[code] ?? AppEnv.baseUrls[AppEnv.defaultCountry]!;
    baseUrl = url;
    await _secure.write(key: AppEnv.storageKeyCountry, value: code);
  }

  static Future<void> ensureCountryLoaded() async {
    final saved = await _secure.read(key: AppEnv.storageKeyCountry);
    final code = saved ?? AppEnv.defaultCountry;
    baseUrl = AppEnv.baseUrls[code] ?? AppEnv.baseUrls[AppEnv.defaultCountry]!;
  }
}
