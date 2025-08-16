class KiotaPayConstants {
  static final String currency = "KES ";
  static final bool isLive = true;
  static final String apiKey = "DA527730128F5D641283CEE7C36D59";
  static final String apiSecret =
      "a1a9bc3892f6c3f18a1de1f8d6bb1be0e947947e3beac1ef325b08039b89bfcb147f7f81acf93c105380ec0531786df68a39";
  static final String sshKey =
      'AAAAB3NzaC1yc2EAAAADAQABAAACAQD6CFJO3IXVJOFUwqdToHNwtmYTcsc1d9QMzj54LpUg893MfWD3lbBeKJACzmuB9Ubi+VSgPtxdZkQzTR2cxYBig35JHBkD2vYjiElyQQ58H9Hg/bk8bMsLAik2EVcVM9UJ2mvlS4zCV9Gh7KHKHznBZ9YTPe3Y8mWl+NA4i+ZE9G1YvrPYW1llpXzA+EE8uF2UBHLMFJ5qnXjLCiSJLOJHPh923SYqXOgk+cc84JM71yVE8xhxEKF1B3eTAMEVbWUv7kAnZVwXv7KyQrZQpYAsgAtMQ0BY0l2BUqlv3o8HkLiCcgOqNhdnj4vPGFU5kPXa19Zfrxa1BH4I3Pzvky+V8biq3uHzuzOSEipSlIz0+JGnUgKuI5GPu7SM/SnoCKFl5elYMTU84lFQIalqBKmtyNNsgQhQZaMQN4SdlwkkqXYHC/Gg5OMDVaongphma5xUNkYujN5JpfF4oEzaEEQeB7v/qGr2bIsj9+/IbOe2wW+yXOsiokDu5X+mRQ8NhD5RhMB6W0EWdDZmQ1wqhX4LMRLPxClXFU3XY3sEb6cu/FtEGIhSMoQ9zY9XRhKUdjzjwFdhNnbNqPjiU1bZJQFbiI+bQylYXCJof87cwnRN2gOTXFczYtfakkK6rW3uLk70dTSYxhejwJx2To3Ql8eV1kai+MF1eSR19QFnNGXTMQ';
  static final String baseUrl = isLive
      ? 'https://app.chanzo.co.ke/api/v1/'
      : 'https://antelope-refined-nicely.ngrok-free.app/chanzo_v2/public/api/v1/';

  static String webUrl = baseUrl.replaceAll(RegExp(r'api/v1/$'), '');
  static String fileBaseUrl = webUrl + 'storage';

  // Authentication
  static final String login = baseUrl + 'auth/login';
  static final String getUserProfile = baseUrl + 'auth/profile';
  static final String logout = baseUrl + 'auth/logout';
  static final String forgotPassword = baseUrl + 'auth/forgot-password';
  static final String changePassword = baseUrl + 'auth/change-password';
  static final String changePasswordNewUser = baseUrl + 'auth/change-password/new-user';
  static final String verifyUserPassword = baseUrl + 'auth/verify-user-password';

  // Finance and Fee Management
  static final String getStudentFee = baseUrl + 'fees/student';
  static final String getStudentFeePdf = baseUrl + 'fees/structure/generate';
  static final String getStudentFeeReceiptPdf = baseUrl + 'fees/structure/generate/receipt';
  static final String getRecentPayments = baseUrl + 'fees/student-payments/{student_id}';
  static final String getRecentYearlyPayments = baseUrl + 'fees/student-payments/monthly/{student_id}';
  static final String getPaymentsMethods = baseUrl + 'fees/payment-settings';
  static final String kcbStkPush = baseUrl + 'fees/payments/buni-stk-push-initiate';
  static final String stkPushStatus = baseUrl + 'fees/payments/check-transaction-status';

  // Timetable
  static final String getStudentTimetable = baseUrl + 'timetable/student';
  static final String getTeacherTimetable = baseUrl + 'timetable/teacher';

  // Attendance
  static final String getStudentAttendance = baseUrl + 'attendance/student';

  // Resource Center
  static final String getResourceCenter = baseUrl + 'resource-center';

  // Homework
  static final String getStudentHomeWork = baseUrl + 'homework';

  // Notice Board
  static final String getNotices = baseUrl + 'notice-board';

  // Calendar
  static final String getCalendar = baseUrl + 'calendar';

  // Notifications
  static final String getNotifications = baseUrl + 'notifications';
  static final String sendNotificationTokens = baseUrl + 'notifications/device-tokens/send';

  // Examination
  static final String getStudentPerformance = baseUrl + 'exams/student-exam-performance';
  static final String getStudentExamTrend = baseUrl + 'exams/student-exam-trend';
  static final String getStudentExamReport = baseUrl + 'exams/reports/:student_id';

  // Academic Sessions
  static final String getAllAcademicSessionsByBranch = baseUrl + 'academic-sessions/:branch_id/branch';
  static final String getStudentAcademicSessions = baseUrl + 'academic-sessions/:student_id/student';

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
  static final String mpesaStkPush = baseUrl + 'collection/wallet-load/push';
  static final String publicKey = '''
-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEArqIC0DZPS/zPQQ2dH984
D707jnkQrnNEF+Ac4k/BleoNeVdnDVuYMBGCIV2mvENUmy+bpQPmoMmgEAmNXOeY
ntR+QB5rlkkl7+5OMHKb1LmJWDm9U3koEcMCQ7TPqAaQucvjkDSIEGfJIXYbyq2D
BLzJVDcuNqUxzZIyLCqoAFiqhslB/NLpJR0VK32MF+Mwmu1GXjwbT9ZnXzQO4BjW
NX6w3bK6JPBdA8PDi9zf1klNEvMQUVpy8uicMiIZH7/0RlqCIPPberZqvyFDH/i5
Y2I4AYmQRiSsqbMcRvxD1yPkkodVXNTPBm/kpm8xcDUKLXANcDoQgBI0Lc4uXjb1
KzUP4EwGPxSPiiAimpfxTo7Z/KzbQASvkO+YBGQ2vXuC4s23aKGVtA7cV6RRhF12
Ywapjbh+awlGbPpH+sjOkNc0U22whAHZv89qEftMg6Ypv1g4FyW4daKkWUbTrF6O
FKDKJy0scn/0jztnitPOlNS6nbkF8GVtQil/1U5+SK1MXr8OD1S69y0fiQ2O+J8g
bk9QLLks38CGgxq1TQQv+UNpsectVyHnHKeWZW8feg/IrqBmlAQB7ZByLpb5q/ld
s5H1xJMThiqowGt0jY8+zw25X/Ki/8Bq2lxDxMkwB85hRlTdKhcXeWseyWOmZzFp
xDyHoe0bfK9Z9VxuOEqfzEkCAwEAAQ==
-----END PUBLIC KEY-----
  ''';
}
