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
import '../kiotapay_pages/kiotapay_authentication/kiotapay_signin.dart';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import '../utils/pdf_viewer_screen.dart';
import 'kiotapay_constants.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

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
  if (token == null) return;
  print("Refresh URL: ${KiotaPayConstants.getUserProfile}");
  // return;

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
    final data = jsonDecode(response.body)['data'];

    // Extract data
    final user = data['user'];
    final school = data['school'];
    final currentAcademicSession = data['current_academic_session'];
    final currentAcademicTerm = data['current_academic_term'];
    final roles = List<String>.from(data['roles']);
    final permissions = List<String>.from(data['permissions']);
    final students = List<Map<String, dynamic>>.from(data['students']);

    // Cache data securely
    await storage.write(key: 'user', value: jsonEncode(user));
    await storage.write(key: 'school', value: jsonEncode(school));
    await storage.write(
        key: 'current_academic_session',
        value: jsonEncode(currentAcademicSession));
    await storage.write(
        key: 'current_academic_term', value: jsonEncode(currentAcademicTerm));
    await storage.write(key: 'roles', value: jsonEncode(roles));
    await storage.write(key: 'permissions', value: jsonEncode(permissions));
    await storage.write(key: 'students', value: jsonEncode(students));

    // Update AuthController
    authController.setUser(user);
    authController.setSchool(school);
    authController.setCurrentAcademicSession(currentAcademicSession);
    authController.setCurrentAcademicTerm(currentAcademicTerm);
    authController.setRoles(roles);
    authController.setPermissions(permissions);
    authController.setStudents(students);

    // Preserve selected student
    if (user['role'] == 'parent' && students.isNotEmpty) {
      final savedStudentJson = await storage.read(key: 'selectedStudent');

      if (savedStudentJson != null) {
        final savedStudent = jsonDecode(savedStudentJson);

        // Check if saved student still exists in refreshed list
        Map<String, dynamic>? matchingStudent;
        try {
          matchingStudent = students.firstWhere(
                (s) => s['id'].toString() == savedStudent['id'].toString(),
          );
        } catch (e) {
          matchingStudent = null; // No match found
        }

        if (matchingStudent != null) {
          // Restore previously selected student
          authController.setSelectedStudent(matchingStudent);
        } else {
          // Fallback to first active student
          final activeStudent = students.firstWhere(
                (s) => s['active'] == 1,
            orElse: () => students.first,
          );
          authController.setSelectedStudent(activeStudent);
        }
      } else {
        // No saved student yet, fallback to first active student
        final activeStudent = students.firstWhere(
              (s) => s['active'] == 1,
          orElse: () => students.first,
        );
        authController.setSelectedStudent(activeStudent);
      }
    }
  } else if (response.statusCode == 401) {
    // Token expired or invalid
    print("Token expired or invalid. Forcing logout...");
    throw TokenExpiredException();
  } else {
    print("Failed to refresh profile: ${response.statusCode}");
  }
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
      builder: (_) => PdfViewerScreen(filePath: path, title: title,),
    ),
  );
}

Future<String> generateHashedKey(String dataToEncrypt) async {
  try {
    // Parse the RSA public key
    final publicKey = encrypt.RSAKeyParser().parse(KiotaPayConstants.publicKey)
        as RSAPublicKey;
    // final publicKey = keyParser.parse(publicKeyString) as RSAPublicKey;

    // Create the encrypter with RSA PKCS1 padding
    final encrypter = encrypt.Encrypter(
      encrypt.RSA(
        publicKey: publicKey,
        encoding: encrypt.RSAEncoding.PKCS1, // Use PKCS1 padding
      ),
    );

    // Encrypt the plaintext data
    final encrypted = encrypter.encrypt(dataToEncrypt);

    // Return the Base64 encoded encrypted string
    return encrypted.base64;
  } catch (e) {
    // Handle exceptions gracefully and rethrow if needed
    print('Error during encryption: $e');
    throw Exception('Failed to encrypt data.');
  }
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

Future<void> _downloadAndOpenFile(BuildContext context, String url, String extension) async {
  final dio = Dio();
  final dir = await getTemporaryDirectory();
  final savePath = '${dir.path}/file_${DateTime.now().millisecondsSinceEpoch}.$extension';

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
    case 'pdf': return 'application/pdf';
    case 'doc': return 'application/msword';
    case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'jpg': case 'jpeg': return 'image/jpeg';
    case 'png': return 'image/png';
    case 'zip': return 'application/zip';
    case 'xls': return 'application/vnd.ms-excel';
    case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'ppt': return 'application/vnd.ms-powerpoint';
    case 'pptx': return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    case 'txt': return 'text/plain';
    default: return 'application/octet-stream';
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

