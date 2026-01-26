import 'dart:convert';

// import 'package:asn1lib/asn1lib.dart';
import 'package:asn1lib/asn1lib.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../kiotapay_pages/kiotapay_authentication/AuthController.dart';
import '../kiotapay_pages/kiotapay_authentication/BranchContext.dart';
import '../kiotapay_pages/kiotapay_authentication/kiotapay_signin.dart';
import 'dart:typed_data';

// import 'package:pointycastle/export.dart';
import '../utils/pdf_viewer_screen.dart';
import 'kiotapay_constants.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import 'kiotapay_icons.dart';

final storage = FlutterSecureStorage();
final authController = Get.put(AuthController());

Future<bool> checkNetwork() async {
  bool isConnected = false;
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      isConnected = true;
    }
  } on SocketException catch (_) {
    isConnected = false;
  }
  return isConnected;
}

checkConnection() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile) {
// I am connected to a mobile network. }
  } else if (connectivityResult == ConnectivityResult.wifi) {
// I am connected to a wifi network.
  }
}

isLoginedIn() async {
  final token = await storage.read(key: 'token');
  if (token == null) return;

  final response = await http.get(
    Uri.parse(KiotaPayConstants.getUserProfile),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    print("isLoggedIn Success Token is $token");
    return true;
  } else if (response.statusCode == 401) {
    // Token expired or invalid
    print("isLoggedIn False Token is expired or invalid $token");
    await forceLogout();
  }
}

Future<void> refreshUserProfile(BuildContext context) async {
  final token = await storage.read(key: 'token');
  if (token == null || token.isEmpty) return;

  // --- safe helpers ---
  Map<String, dynamic> asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  List<String> asStringList(dynamic v) {
    if (v is List) return v.whereType<String>().toList();
    return <String>[];
  }

  List<Map<String, dynamic>> asListOfMap(dynamic v) {
    if (v is List) {
      return v
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  final response = await http.get(
    Uri.parse(KiotaPayConstants.getUserProfile),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  print("Refreshed profile: ${response.body}");

  if (response.statusCode == 200) {
    final root = asMap(jsonDecode(response.body));
    final data = asMap(root['data']);

    // Extract safely
    final user = asMap(data['user']); // {} if null
    final school = asMap(data['school']);
    final currentAcademicSession = asMap(data['current_academic_session']);

    // current_academic_term can be null -> treat as {}
    final termRaw = data['current_academic_term'];
    final currentAcademicTerm = termRaw == null ? <String, dynamic>{} : asMap(termRaw);

    final roles = asStringList(data['roles']);
    final permissions = asStringList(data['permissions']);
    final students = asListOfMap(data['students']);

    // Cache safely (store {} instead of null to avoid later decode-map crashes)
    await storage.write(key: 'user', value: jsonEncode(user));
    await storage.write(key: 'school', value: jsonEncode(school));
    await storage.write(key: 'current_academic_session', value: jsonEncode(currentAcademicSession));
    await storage.write(key: 'current_academic_term', value: jsonEncode(currentAcademicTerm));
    await storage.write(key: 'roles', value: jsonEncode(roles));
    await storage.write(key: 'permissions', value: jsonEncode(permissions));
    await storage.write(key: 'students', value: jsonEncode(students));

    // Update controller (only call setUser if you actually got an id/name etc)
    if (user.isNotEmpty) authController.setUser(user);
    authController.setSchool(school);
    authController.setCurrentAcademicSession(currentAcademicSession);
    authController.setCurrentAcademicTerm(currentAcademicTerm);
    authController.setRoles(roles);
    authController.setPermissions(permissions);
    authController.setStudents(students);

    // Preserve selected student (also fix: use students list, not allStudents)
    if ((authController.userRole == 'parent') && students.isNotEmpty) {
      final savedStudentJson = await storage.read(key: 'selectedStudent');

      Map<String, dynamic>? matchingStudent;

      if (savedStudentJson != null) {
        final savedStudent = asMap(jsonDecode(savedStudentJson));
        try {
          matchingStudent = students.firstWhere(
                (s) => s['id'].toString() == (savedStudent['id'] ?? '').toString(),
          );
        } catch (_) {
          matchingStudent = null;
        }
      }

      if (matchingStudent != null) {
        authController.setSelectedStudent(matchingStudent, fetchBalance: false);
      } else {
        // pick first active else first
        final activeStudent = students.firstWhere(
              (s) => s['active'] == 1,
          orElse: () => students.first,
        );
        authController.setSelectedStudent(activeStudent, fetchBalance: false);
      }

      // Important with your multi-branch logic:
      authController.ensureSelectedStudentInActiveBranch();
    }
    return;
  }

  if (response.statusCode == 401) {
    print("Token expired or invalid. Forcing logout...");
    throw TokenExpiredException();
  }

  print("Failed to refresh profile: ${response.statusCode}");
}

Future<void> forceLogout() async {
  await storage.deleteAll();

  // Clear AuthController
  authController.setUser({});
  authController.setToken('');
  authController.setRoles([]);
  authController.setPermissions([]);
  authController.setSchool({});
  authController.setCurrentAcademicSession({});
  authController.setCurrentAcademicTerm({});
  authController.setStudents([]);
  authController.setSelectedStudent({});

  // Navigate to login screen
  Get.offAll(() => KiotaPaySignIn());
  print('Session expired, logged out');
}

void logout(BuildContext context) {
  AwesomeDialog(
    context: context,
    dialogType: DialogType.warning,
    headerAnimationLoop: false,
    animType: AnimType.bottomSlide,
    title: 'Logout',
    desc: 'Are you sure you want to logout?',
    buttonsTextStyle: const TextStyle(color: Colors.white),
    btnOkColor: ChanzoColors.primary,
    btnCancelColor: ChanzoColors.secondary,
    showCloseIcon: true,
    btnCancelOnPress: () {},
    btnOkOnPress: () async {
      print('User logged out manually');
      forceLogout();
    },
  ).show();
}

getAccessToken() async {
  var token = await storage.read(key: 'token');
  if (token!.isNotEmpty) {
    token = await storage.read(key: 'token');
  } else {
    token = null;
  }
  print("Get access token is $token");
  return token;
}

getTokenExpiryMinutes() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? storedValue = await storage.read(key: 'login_timestamp');

  if (storedValue != null) {
    int? timestamp = int.parse(storedValue);
    // DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp!);
    DateTime before = DateTime.fromMillisecondsSinceEpoch(timestamp!);
    DateTime now = DateTime.now();
    Duration timeDifference = now.difference(before);
    print("Minutes Remaining " + (45 - timeDifference.inMinutes).toString());
    return 20 - timeDifference.inMinutes;
  }
}

refreshToken() async {
  return "Token can't be refreshed";
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString("access_token");
  var headers = {'Authorization': 'Bearer $token'};
  var url = Uri.parse(KiotaPayConstants.refreshToken);
  http.Response response = await http.post(url, headers: headers);
  final json = jsonDecode(response.body);
  if (response.statusCode == 200) {
    if (json['access_token'] != null) {
      final SharedPreferences? prefs = await SharedPreferences.getInstance();
      int timestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs?.setString('access_token', json['access_token']);
      await prefs?.setString('refresh_token', json['refresh_token']);
      await prefs?.setInt('login_timestamp', timestamp);
      await updateTokens(json['access_token'], json['refresh_token']);
    }
  } else {
    forceLogout();
  }
  // print(json);
}

Future<void> updateTokens(String newAccessToken, String newRefreshToken) async {
  // Get the SharedPreferences instance
  SharedPreferences? prefs = await SharedPreferences.getInstance();

  // Retrieve the existing user data
  String? userString = prefs.getString('user');

  if (userString != null) {
    // Decode the user data into a Map
    Map<String, dynamic> user = jsonDecode(userString);

    // Update the tokens
    user['access_token'] = newAccessToken;
    user['refresh_token'] = newRefreshToken;

    // Save the updated user data back to SharedPreferences
    await prefs?.setString('user', jsonEncode(user));
  } else {
    print('User data not found');
  }
}

getUserWallet2() async {
  try {
    isLoginedIn();
    var token = await getAccessToken();
    var headers = {'Authorization': 'Bearer $token'};
    var response = await http.get(Uri.parse(KiotaPayConstants.userWallet),
        headers: headers);
    if (response.statusCode == 200) {
      dynamic res = jsonDecode(response.body);
      print("The User Wallet is ${res['toSpendAmount']}");
      return res['toSpendAmount'].toDouble();
      // setState(() {
      //   _userWallet = res['data'].toDouble();
      // });
    } else {
      print("Not 200 Res" + response.body);
      return;
    }
  } catch (exception) {
    print("Exception $exception");
    return;
  }
}

getOrgWallet() async {
  try {
    isLoginedIn();
    var token = await getAccessToken();
    var headers = {'Authorization': 'Bearer $token'};
    var response = await http.get(Uri.parse(KiotaPayConstants.orgWallet),
        headers: headers);
    if (response.statusCode == 200) {
      dynamic res = jsonDecode(response.body);
      print("The User Org Wallet is ${res['balance']}");
      return res['balance'].toDouble();
    } else {
      print("Not 200 Res" + response.body);
      return;
    }
  } catch (exception) {
    print("Exception $exception");
    return;
  }
}

formatedDate(_date) {
  var inputFormat = DateFormat('yyyy-MM-dd');
  var inputDate = inputFormat.parse(_date);
  var outputFormat = DateFormat('MMMM dd yyyy');
  return outputFormat.format(inputDate);
}

final decimalformatedNumber = new NumberFormat("#,##0.00", "en_US");
final formatedNumber = new NumberFormat("#,##0", "en_US");

String? formatPhoneNumber(String? number) {
  if (number == null) {
    return null;
  }

  // Remove any spaces or non-digit characters (except +)
  number =
      number.replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^0-9+]'), '');

  // Handle cases where the number starts with +254
  if (number.startsWith('+254')) {
    return number.substring(1);
  }

  // Handle cases where the number starts with 07xxx or 01xxx
  if (number.startsWith('07') || number.startsWith('01')) {
    return '254' + number.substring(1);
  }

  // Handle cases where the number starts with 7xxx or 1xxx
  if (number.startsWith('7') || number.startsWith('1')) {
    return '254' + number;
  }

  // If the number is already in the correct format, return it as is
  if (number.startsWith('254')) {
    return number;
  }

  // For any other cases, return the original number unmodified
  return number;
}

Future<String> getInstalledVersion() async {
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}

Future<void> saveAndOpenPdf({
  required Uint8List pdfBytes,
  required String reference,
  required String title,
  required BuildContext context,
}) async {
  Directory? directory;

  if (Platform.isIOS) {
    directory = await getApplicationDocumentsDirectory();
  } else {
    directory = await getDownloadsDirectory();
  }

  if (directory == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document directory not available')),
    );
    return;
  }

  final path = '${directory.path}/CHANZO-$reference.pdf';
  final file = File(path);
  await file.writeAsBytes(pdfBytes);

  // Open in your existing PDF viewer screen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PdfViewerScreen(
        filePath: path,
        title: title,
      ),
    ),
  );
}

Future<void> openFile(BuildContext context, String fileUrl) async {
  try {
    final fullUrl = "${KiotaPayConstants.fileBaseUrl}/$fileUrl";
    debugPrint("Opening file: $fullUrl");

    final uri = Uri.parse(fullUrl);
    if (!uri.isAbsolute) throw Exception('Invalid URL format');

    // Show loading indicator
    EasyLoading.show(
      status: 'Preparing file...',
      maskType: EasyLoadingMaskType.black,
    );

    // Try direct opening first
    if (await canLaunchUrl(uri)) {
      await EasyLoading.showInfo('Opening in viewer...');
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
        ),
      );
      await EasyLoading.dismiss();
      return;
    }

    // Fallback to download
    final fileExtension = fileUrl.split('.').last.toLowerCase();
    await _downloadAndOpenFile(context, fullUrl, fileExtension);
  } catch (e) {
    debugPrint('File open error: $e');
    await EasyLoading.dismiss();

    if (context.mounted) {
      EasyLoading.showError(
        'Failed to open file',
        duration: const Duration(seconds: 3),
      );
    }
  }
}

Future<void> _downloadAndOpenFile(
    BuildContext context, String url, String extension) async {
  final dio = Dio();
  final dir = await getTemporaryDirectory();
  final savePath =
      '${dir.path}/file_${DateTime.now().millisecondsSinceEpoch}.$extension';

  try {
    EasyLoading.showProgress(0, status: 'Downloading...');

    await dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final progress = (received / total * 100).round();
          EasyLoading.showProgress(
            progress / 100,
            status: '$progress% downloaded',
          );
        }
      },
    );

    EasyLoading.show(status: 'Opening file...');
    final result = await OpenFile.open(savePath);

    if (result.type != ResultType.done) {
      throw Exception('No app available to open this file');
    }
  } catch (e) {
    debugPrint('Download error: $e');
    rethrow;
  } finally {
    await EasyLoading.dismiss();
  }
}

// MIME Type Detection
String _getMimeType(String extension) {
  switch (extension) {
    case 'pdf':
      return 'application/pdf';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'zip':
      return 'application/zip';
    case 'xls':
      return 'application/vnd.ms-excel';
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'ppt':
      return 'application/vnd.ms-powerpoint';
    case 'pptx':
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    case 'txt':
      return 'text/plain';
    default:
      return 'application/octet-stream';
  }
}

String formatNoticeDate(String dateString) {
  final date = DateTime.parse(dateString);
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays > 30) {
    return '${date.day}/${date.month}/${date.year}';
  } else if (difference.inDays >= 1) {
    return '${difference.inDays} days ago';
  } else if (difference.inHours >= 1) {
    return '${difference.inHours} hours ago';
  } else if (difference.inMinutes >= 1) {
    return '${difference.inMinutes} minutes ago';
  } else {
    return 'Just now';
  }
}

class TokenExpiredException implements Exception {}

Future<void> openContextSwitcher(
  BuildContext context, {
  Future<void> Function()? onContextChanged,
  Future<void> Function()? onStudentChanged,
}) async {
  final auth = Get.find<AuthController>();
  auth.ensureSelectedStudentInActiveBranch();
  await auth.fetchContextFromServerIfNeeded();

  final isLoading = false.obs;

  Future<void> switchContextAndRefresh({
    required BuildContext sheetCtx,
    required int branchId,
    required String role,
    required String branchName,
  }) async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      final updated =
          await auth.switchContextOnServer(branchId: branchId, role: role);
      final d = Map<String, dynamic>.from(updated['data'] ?? {});

      if (d['current_context'] != null) {
        auth.activeContext.value = ActiveContext.fromJson(
            Map<String, dynamic>.from(d['current_context']));
      } else {
        auth.activeContext.value = ActiveContext(
            branchId: branchId, role: role, branchName: branchName);
      }

      if (d['school'] != null)
        auth.setSchool(Map<String, dynamic>.from(d['school']));
      if (d['current_academic_session'] != null) {
        auth.setCurrentAcademicSession(
            Map<String, dynamic>.from(d['current_academic_session']));
      }
      if (d['current_academic_term'] != null) {
        auth.setCurrentAcademicTerm(
            Map<String, dynamic>.from(d['current_academic_term']));
      }

      if (d['roles'] != null) auth.setRoles(List<String>.from(d['roles']));
      if (d['permissions'] != null)
        auth.setPermissions(List<String>.from(d['permissions']));

      auth.ensureSelectedStudentInActiveBranch();

      if (onContextChanged != null) await onContextChanged();

      // ✅ CLOSE SHEET AFTER SUCCESS
      if (Navigator.canPop(sheetCtx)) Navigator.pop(sheetCtx);

      Get.snackbar('Success', 'Switched to $branchName ($role)',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> switchStudentAndRefresh(Map<String, dynamic> student) async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      auth.setSelectedStudent(student);
      if (onStudentChanged != null) await onStudentChanged();

      final u = student['user'] ?? {};
      Get.snackbar(
        'Success',
        'Switched to ${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) {
      return Obx(() {
        final current = auth.activeContext.value;
        final contexts = auth.availableContexts;

        final isParent = auth.userRole == 'parent';
        final activeBranchId = current?.branchId;

        // Parent: only students in selected branch
        final studentsInBranch = auth.studentsInActiveBranch;

        return SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    /// Title
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isParent
                                ? 'Switch School / Student'
                                : 'Switch Account',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: isLoading.value
                              ? null
                              : () => Navigator.pop(sheetCtx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    /// Current context card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current',
                              style: TextStyle(color: Colors.grey.shade700)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.school, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  current?.branchName ??
                                      auth.school['name'] ??
                                      'No school selected',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.badge, size: 18),
                              const SizedBox(width: 8),
                              Text(current?.role ?? auth.userRole),
                            ],
                          ),
                          if (isParent && auth.selectedStudent.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${auth.selectedStudent['user']?['first_name'] ?? ''} ${auth.selectedStudent['user']?['last_name'] ?? ''}'
                                        .trim(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // -------- Parent View --------
                    if (isParent) ...[
                      // Branch selector (schools)
                      Text('Schools',
                          style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      if (contexts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'No schools found for this account.',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        )
                      else
                        ...contexts.map((b) {
                          final isActive = activeBranchId == b.branchId;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isActive
                                    ? Theme.of(sheetCtx).colorScheme.primary
                                    : Colors.grey.shade300,
                              ),
                              color: Colors.white,
                            ),
                            child: ListTile(
                              title: Text(
                                b.branchName,
                                style: TextStyle(
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w600),
                              ),
                              subtitle: Text(isActive
                                  ? 'Current school'
                                  : 'Tap to switch'),
                              trailing: isActive
                                  ? const Icon(Icons.check)
                                  : const Icon(Icons.chevron_right),
                              onTap: isActive
                                  ? null
                                  : () async {
                                      final roleSlug = (b.roles.isNotEmpty)
                                          ? b.roles.first
                                          : 'parent';
                                      await switchContextAndRefresh(
                                        sheetCtx: sheetCtx,
                                        branchId: b.branchId,
                                        role: roleSlug,
                                        branchName: b.branchName,
                                      );
                                    },
                            ),
                          );
                        }).toList(),

                      const Divider(height: 22),

                      // Student selector (filtered)
                      Text('Students',
                          style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 8),

                      if (studentsInBranch.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No students found in this school.',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        )
                      else
                        ...studentsInBranch.map((student) {
                          final u = student['user'] ?? {};
                          final isSelected =
                              auth.selectedStudent['id'] == student['id'];
                          final isActiveStudent = auth.isStudentActive(student);

                          return Opacity(
                            opacity: isActiveStudent ? 1 : 0.55,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(sheetCtx).colorScheme.primary
                                      : Colors.grey.shade300,
                                ),
                                color: Colors.white,
                              ),
                              child: ListTile(
                                enabled: isActiveStudent,
                                onTap: !isActiveStudent
                                    ? null
                                    : () async {
                                        // close the sheet after selection (optional)
                                        Navigator.pop(sheetCtx);
                                        await switchStudentAndRefresh(student);
                                      },
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    u['avatar'] != null
                                        ? '${KiotaPayConstants.webUrl}storage/${u['avatar']}'
                                        : KiotaPayPngimage.profile,
                                  ),
                                ),
                                title: Text(
                                  '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'
                                      .trim(),
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                    student['class']?['name'] ?? 'No class'),
                                trailing:
                                    isSelected ? const Icon(Icons.check) : null,
                              ),
                            ),
                          );
                        }).toList(),
                    ],

                    // -------- Non-parent View --------
                    if (!isParent) ...[
                      const SizedBox(height: 6),
                      ...contexts.expand((b) => b.roles.map((r) {
                            final isActive = current?.branchId == b.branchId &&
                                current?.role == r;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isActive
                                      ? Theme.of(sheetCtx).colorScheme.primary
                                      : Colors.grey.shade300,
                                ),
                                color: Colors.white,
                              ),
                              child: ListTile(
                                title: Text('${b.branchName}'),
                                subtitle: Text('Role: $r'),
                                trailing: isActive
                                    ? const Icon(Icons.check)
                                    : const Icon(Icons.chevron_right),
                                onTap: isActive
                                    ? null
                                    : () async {
                                        final roleSlug = (b.roles.isNotEmpty)
                                            ? b.roles.first
                                            : 'parent';
                                        await switchContextAndRefresh(
                                          sheetCtx: sheetCtx,
                                          branchId: b.branchId,
                                          role: roleSlug,
                                          branchName: b.branchName,
                                        );
                                      },
                              ),
                            );
                          })),
                    ],
                  ],
                ),
              ),

              // Loading overlay
              if (isLoading.value)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.15),
                    child: const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      });
    },
  );
}
