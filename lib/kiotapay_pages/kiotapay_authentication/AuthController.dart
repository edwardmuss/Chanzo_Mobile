import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import 'package:http/http.dart' as http;

import '../../globalclass/kiotapay_icons.dart';

class AuthController extends GetxController {
  final storage = FlutterSecureStorage();

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
  void setCurrentAcademicSession(Map<String, dynamic> sessionData) {
    currentAcademicSession.assignAll(sessionData);
  }

  // Set academic term info
  void setCurrentAcademicTerm(Map<String, dynamic> termData) {
    currentAcademicTerm.assignAll(termData);
  }

  // Set students
  void setStudents(List<Map<String, dynamic>> students) {
    allStudents.assignAll(students);
  }

  void setSelectedStudent(Map<String, dynamic> student, {bool fetchBalance = true}) {
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
      final exists = allStudents.any((s) => s['id'].toString() == student['id'].toString());
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
        Uri.parse('${KiotaPayConstants.getStudentFee}/$studentId?academic_session_id=&term_id='),
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
          calculatedTotalFees += (session['session_total_fees'] ?? 0).toDouble();
          calculatedTotalPayments += (session['session_total_payments'] ?? 0).toDouble();
        }

        final calculatedBalance = calculatedTotalFees - calculatedTotalPayments;

        // Update all three values
        setFeeBalance(calculatedBalance);
        setTotalPayments(calculatedTotalPayments);
        setTotalFees(calculatedTotalFees);

        // Cache all values
        await Future.wait([
          storage.write(key: _feeBalanceKey, value: calculatedBalance.toString()),
          storage.write(key: _totalPaymentsKey, value: calculatedTotalPayments.toString()),
          storage.write(key: _totalFeesKey, value: calculatedTotalFees.toString()),
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
      "${user['first_name'] ?? ''} ${user['middle_name'] ?? ''} ${user['last_name'] ?? ''}".trim();

  int get userId => user['id'];
  String get userFirstName => user['first_name'] ?? 'User';
  String get userMiddleName => user['middle_name'] ?? '';
  String get userLastName => user['last_name'] ?? '';
  String get userEmail => user['email'] ?? 'No Email';
  String get userPhone => user['phone'] ?? 'No Phone';
  String get userRole => user['role'] ?? 'No Role';
  String get schoolName => school['name'] ?? 'No School';
  String get currentAcademicSessionName => currentAcademicSession['year'] ?? 'No Session';
  int get currentAcademicSessionID => currentAcademicSession['id'] ?? 0;
  String get currentAcademicTermName => currentAcademicTerm['term_number'] ?? 'No Term';

  // Helper: Get student's Details
  String get selectedStudentFirstName =>
      "${selectedStudent['user']?['first_name'] ?? ''}".trim();

  String get selectedStudentName =>
      "${selectedStudent['user']?['first_name'] ?? ''} ${selectedStudent['user']?['last_name'] ?? ''}".trim();

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
}
