import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import 'package:http/http.dart' as http;

import '../../globalclass/kiotapay_icons.dart';
import 'BranchContext.dart';

class AuthController extends GetxController {
  final storage = FlutterSecureStorage();

  final isGlobalRole = false.obs;
  final availableContexts = <BranchContext>[].obs;
  final activeContext = Rxn<ActiveContext>();

  bool get needsContextSelection {
    if (isGlobalRole.value) return false;
    if (availableContexts.isEmpty) return false;

    // If we already have an active context saved, skip selection
    if (activeContext.value != null) return false;

    // If exactly 1 branch and 1 role => auto-select
    if (availableContexts.length == 1 &&
        availableContexts.first.roles.length == 1) {
      return false; // we will auto-select in routing
    }

    return true;
  }

  Future<void> applyLoginPayload(Map<String, dynamic> data) async {
    token.value = (data['token'] ?? '').toString();

    isGlobalRole.value = data['is_global_role'] == true;

    // Safe parse available_contexts (works even if it's List<dynamic>)
    final rawContexts = data['available_contexts'];
    if (rawContexts is List) {
      availableContexts.assignAll(
        rawContexts
            .whereType<Map>() // only items that are maps
            .map((m) => Map<String, dynamic>.from(m))
            .map(BranchContext.fromJson)
            .toList(),
      );
    } else {
      availableContexts.clear();
    }

    // Safe parse current_context (can be null)
    final ctx = data['current_context'];
    if (ctx is Map) {
      activeContext.value =
          ActiveContext.fromJson(Map<String, dynamic>.from(ctx));
    } else {
      activeContext.value = null; // important: clear if missing
    }
  }

  // Reactive user details
  var isStudentListExpanded = false.obs; // RxBool
  var user = <String, dynamic>{}.obs;
  var school = <String, dynamic>{}.obs;
  var currentAcademicSession = <String, dynamic>{}.obs;
  var currentAcademicTerm = <String, dynamic>{}.obs;

  // Parent's students
  var allStudents = <Map<String, dynamic>>[].obs;
  var selectedStudent = <String, dynamic>{}.obs;

  // Fees Observable
  var feeBalance = 0.0.obs;
  var totalPayments = 0.0.obs;
  var totalFees = 0.0.obs;

  // Storage keys
  static const _feeBalanceKey = 'feeBalance';
  static const _totalPaymentsKey = 'totalPayments';
  static const _totalFeesKey = 'totalFees'; // New storage key

  // Setter methods
  void setFeeBalance(double balance) => feeBalance.value = balance;

  void setTotalPayments(double amount) => totalPayments.value = amount;

  void setTotalFees(double amount) => totalFees.value = amount;

  // Reactive permissions and roles
  var permissions = <String>[].obs;
  var roles = <String>[].obs;

  // Token (if needed for quick access)
  var token = ''.obs;

  // Set user info
  void setUser(Map<String, dynamic> userData) {
    user.assignAll(userData);
  }

  // Set school info
  void setSchool(Map<String, dynamic> schoolData) {
    school.assignAll(schoolData);
  }

  // Set academic session info
  void setCurrentAcademicSession(dynamic sessionData) {
    if (sessionData is Map<String, dynamic>) {
      currentAcademicSession.assignAll(sessionData);
    } else {
      currentAcademicSession.clear();
    }
  }

  // Set academic term info
  void setCurrentAcademicTerm(dynamic termData) {
    if (termData is Map<String, dynamic>) {
      currentAcademicTerm.assignAll(termData);
    } else {
      currentAcademicTerm.clear();
    }
  }

  // Set students
  void setStudents(List<Map<String, dynamic>> students) {
    allStudents.assignAll(students);
  }

  void setSelectedStudent(Map<String, dynamic> student,
      {bool fetchBalance = true}) {
    selectedStudent.assignAll(student);

    // Persist selected student
    storage.write(
      key: 'selectedStudent',
      value: jsonEncode(student),
    );

    if (fetchBalance) {
      fetchAndCacheFeeBalance(); // Fetch balance on student change
    }
  }

  Future<void> loadSelectedStudent() async {
    final savedStudent = await storage.read(key: 'selectedStudent');
    if (savedStudent != null) {
      final student = jsonDecode(savedStudent);

      // Check if this student still exists in the current allStudents
      final exists = allStudents
          .any((s) => s['id'].toString() == student['id'].toString());
      if (exists) {
        setSelectedStudent(student, fetchBalance: false);
      } else if (allStudents.isNotEmpty) {
        setSelectedStudent(allStudents.first, fetchBalance: false); // fallback
      }
    } else if (allStudents.isNotEmpty) {
      setSelectedStudent(allStudents.first, fetchBalance: false); // fallback
    }

    // Load cached balance (so UI doesn’t flash 0)
    await loadCachedFeeBalance();
  }

  Future<void> fetchAndCacheFeeBalance() async {
    final studentId = selectedStudent['id'];
    if (studentId == null) return;

    final token = await storage.read(key: 'token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            '${KiotaPayConstants.getStudentFee}/$studentId?academic_session_id=&term_id='),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        final feesList = data['fees'] as List<dynamic>;

        double calculatedTotalFees = 0.0;
        double calculatedTotalPayments = 0.0;

        for (var session in feesList) {
          calculatedTotalFees +=
              (session['session_total_fees'] ?? 0).toDouble();
          calculatedTotalPayments +=
              (session['session_total_payments'] ?? 0).toDouble();
        }

        final calculatedBalance = calculatedTotalFees - calculatedTotalPayments;

        // Update all three values
        setFeeBalance(calculatedBalance);
        setTotalPayments(calculatedTotalPayments);
        setTotalFees(calculatedTotalFees);

        // Cache all values
        await Future.wait([
          storage.write(
              key: _feeBalanceKey, value: calculatedBalance.toString()),
          storage.write(
              key: _totalPaymentsKey,
              value: calculatedTotalPayments.toString()),
          storage.write(
              key: _totalFeesKey, value: calculatedTotalFees.toString()),
        ]);
      }
    } catch (e) {
      print("Error fetching fee balance: $e");
    }
  }

  Future<void> loadCachedFeeBalance() async {
    final results = await Future.wait([
      storage.read(key: _feeBalanceKey),
      storage.read(key: _totalPaymentsKey),
      storage.read(key: _totalFeesKey),
    ]);

    setFeeBalance(double.tryParse(results[0] ?? '0') ?? 0);
    setTotalPayments(double.tryParse(results[1] ?? '0') ?? 0);
    setTotalFees(double.tryParse(results[2] ?? '0') ?? 0);
  }

  // Set permissions
  void setPermissions(List<String> perms) {
    permissions.assignAll(perms);
  }

  // Set roles
  void setRoles(List<String> rolesList) {
    roles.assignAll(rolesList);
  }

  // Set token
  void setToken(String authToken) {
    token.value = authToken;
  }

  // Check permission
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  // Check role
  bool hasRole(String role) {
    return roles.contains(role);
  }

  // Common user getters
  String get userFullName =>
      "${user['first_name'] ?? ''} ${user['middle_name'] ?? ''} ${user['last_name'] ?? ''}"
          .trim();

  int get userId => user['id'];

  String get userFirstName => user['first_name'] ?? 'User';

  String get userMiddleName => user['middle_name'] ?? '';

  String get userLastName => user['last_name'] ?? '';

  String get userEmail => user['email'] ?? 'No Email';

  String get userPhone => user['phone'] ?? 'No Phone';

  String get userRole => user['role'] ?? 'No Role';

  String get schoolName => school['name'] ?? 'No School';

  String get currentAcademicSessionName =>
      currentAcademicSession['year'] ?? 'No Session';

  int get currentAcademicSessionID => currentAcademicSession['id'] ?? 0;

  String get currentAcademicTermName =>
      currentAcademicTerm['term_number'] ?? 'No Term';

  // Helper: Get student's Details
  String get selectedStudentFirstName =>
      "${selectedStudent['user']?['first_name'] ?? ''}".trim();

  String get selectedStudentName =>
      "${selectedStudent['user']?['first_name'] ?? ''} ${selectedStudent['user']?['last_name'] ?? ''}"
          .trim();

  int get selectedStudentId => selectedStudent['id'];

  String get selectedStudentAdmissionNumber =>
      "${selectedStudent['admission_no'] ?? ''}";

  String get selectedStudentClassName =>
      "${selectedStudent['class']?['name'] ?? 'N/A'}";

  String get selectedStudentStreamName =>
      "${selectedStudent['stream']?['name'] ?? 'N/A'}";

  int get selectedStudentClassId => selectedStudent['class_id'];

  int get selectedStudentStreamId => selectedStudent['stream_id'];

  String get selectedStudentAvatar {
    final avatar = selectedStudent['user']?['avatar']?.toString();
    return avatar != null
        ? '${KiotaPayConstants.webUrl}storage/$avatar'
        : KiotaPayPngimage.profile;
  }

  String get selectedStudentCoverImage {
    final coverImage = selectedStudent['user']?['cover_image']?.toString();
    return coverImage != null
        ? '${KiotaPayConstants.webUrl}storage/$coverImage'
        : KiotaPayPngimage.card;
  }

  bool isStudentActive(Map<String, dynamic> student) {
    return student['active'] == 1 && (student['user']?['is_active'] == true);
  }

  Future<Map<String, dynamic>> getContextFromServer() async {
    // final token = await _storage.read(key: 'token');
    // if (token == null || token.isEmpty) {
    //   throw Exception('Missing token');
    // }

    final res = await http.get(
      Uri.parse(KiotaPayConstants.contextGet),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final body = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw Exception(body['message'] ?? 'Failed to fetch context');
    }

    return Map<String, dynamic>.from(body);
  }

  Future<Map<String, dynamic>> switchContextOnServer({
    required int branchId,
    required String role,
  }) async {
    // Ensure token exists
    var t = token.value;
    if (t.isEmpty) {
      final stored = await storage.read(key: 'token');
      if (stored != null && stored.isNotEmpty) {
        t = stored;
        token.value = stored; // keep controller in sync
      }
    }

    if (t.isEmpty) {
      throw Exception('Missing token. Please login again.');
    }

    final res = await http.post(
      Uri.parse(KiotaPayConstants.contextSwitch),
      headers: {
        'Authorization': 'Bearer $t',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'branch_id': branchId,
        'role': role, // slug e.g. "parent"
      }),
    );

    final body = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw Exception(body['message'] ?? 'Failed to switch context');
    }

    return Map<String, dynamic>.from(body);
  }

  int? get activeBranchId => activeContext.value?.branchId;

  /// Parent: only students in currently selected branch
  List<Map<String, dynamic>> get studentsInActiveBranch {
    final bid = activeBranchId;
    if (bid == null) return allStudents;
    return allStudents.where((s) => s['branch_id'] == bid).toList();
  }

  /// show inactive/active filtering
  List<Map<String, dynamic>> get activeStudentsInBranch {
    return studentsInActiveBranch.where(isStudentActive).toList();
  }

  void ensureSelectedStudentInActiveBranch() {
    final bid = activeBranchId;
    if (bid == null) return;

    // If selected student is from another branch, reset to first in-branch
    final selectedId = selectedStudent['id']?.toString();
    final inBranch = allStudents.where((s) => s['branch_id'] == bid).toList();

    final stillValid = inBranch.any((s) => s['id'].toString() == selectedId);
    if (!stillValid && inBranch.isNotEmpty) {
      setSelectedStudent(inBranch.first, fetchBalance: false);
    }
  }

  Future<void> fetchContextFromServerIfNeeded() async {
    // If we already have contexts, don't refetch
    if (availableContexts.isNotEmpty) return;

    final tokenStr = await storage.read(key: 'token');
    if (tokenStr == null || tokenStr.isEmpty) return;

    try {
      final res = await http.get(
        Uri.parse(KiotaPayConstants.contextGet), // /auth/context
        headers: {
          'Authorization': 'Bearer $tokenStr',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final data = Map<String, dynamic>.from(json['data'] ?? {});
        await applyLoginPayload(data); // reuse your mapper
      }
    } catch (_) {}
  }

  bool get hasMultipleContexts {
    // Count (branch, role) pairs
    int count = 0;
    for (final b in availableContexts) {
      count += b.roles.length;
    }
    return count > 1;
  }

  bool get isParentContextActive {
    final r = activeContext.value?.role ??
        userRole; // role slug if set, else fallback
    return r.toLowerCase() == 'parent';
  }

  bool get canSwitchStudentInThisBranch {
    if (!isParentContextActive) return false;
    return studentsInActiveBranch.length > 1;
  }

  bool get shouldShowSwitcherButton {
    return hasMultipleContexts || canSwitchStudentInThisBranch;
  }
}
