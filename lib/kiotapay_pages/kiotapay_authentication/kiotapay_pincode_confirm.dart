import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kiotapay/globalclass/global_methods.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_dahsboard/kiotapay_dahsboard.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class KiotaPayPinConfirm extends StatefulWidget {
  const KiotaPayPinConfirm({super.key, required this.pin});
final String pin;
  @override
  State<KiotaPayPinConfirm> createState() => _KiotaPayPinConfirmState();
}

class _KiotaPayPinConfirmState extends State<KiotaPayPinConfirm> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  late bool initializing = true;
  late String firstPinCode = '';
  late String secondPinCode = '';
  late String _pinHeading = 'Confirm PIN';
  String pinError = '';
  String pinSuccess = '';
  final TextEditingController pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

  }

  String hashedKey(String apiKey, String pin, String apisecret) {
    String concatenatedString = apiKey + pin + apisecret;

    var bytes = utf8.encode(concatenatedString);
    var digest = sha256.convert(bytes);

    String encodedHashString = digest.toString();
    print('Encoded hash: $encodedHashString');

    return encodedHashString;
  }

  Future<void> createPin() async {
    isLoginedIn();
    showLoading('Working...');
    var minutes = await getTokenExpiryMinutes();
    if (minutes < 4) {
      refreshToken();
    }
    var token = await getAccessToken();
    var secure_hash = hashedKey(KiotaPayConstants.apiKey, pinController.text, KiotaPayConstants.apiSecret);
    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'secure_hash': secure_hash
    };
    var body = {
      "mobile_pin": widget.pin,
      "confirm_pin": pinController.text,
    };
    try {
      var url = Uri.parse(KiotaPayConstants.createUserPin);
      http.Response response =
      await http.post(url, body: jsonEncode(body), headers: headers);
      print("Response body is: " +
          response.body.toString() +
          " and Code is " +
          response.statusCode.toString());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        var msg = jsonDecode(response.body)['msg'];
        showLoading("PIN set Successfully...");
        Future.delayed(Duration(seconds: 3), () async {
          hideLoading();
          Get.offAll(() => KiotaPayDashboard('0'));
        });

      } else {
        var _error =
            jsonDecode(response.body)['message'] ?? "Unknown Error Occurred";
        hideLoading();

        awesomeDialog(context, "Error", _error.toString(), true,
            DialogType.error, ChanzoColors.secondary)
          ..show();
        throw _error ?? "Unknown Error Occured";
      }
    } catch (error) {
      // Get.back();
      // context.loaderOverlay.hide();
      hideLoading();
      Fluttertoast.showToast(
          msg: "Something went wrong!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return Scaffold(
      // backgroundColor: Colors.white,
      body: SingleChildScrollView(
        reverse: true,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Image.asset(
                  KiotaPayPngimage.emailsent,
                  width: MediaQuery.of(context).size.width / 3,
                  // height: MediaQuery.of(context).size.height / 3,
                  fit: BoxFit.fill,
                ),
                const SizedBox(height: 20),
                Text(
                  _pinHeading,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text(
                    'Set up a pin that will be used to verify your identity before making transactions',
                    textAlign: TextAlign.center,
                  ),
                ),
                // const Text('Pin length is 4 digits'),
                const SizedBox(height: 40),
                SizedBox(
                  width: 222,
                  child: PinCodeTextField(
                    length: 4,
                    controller: pinController,
                    appContext: context,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onChanged: (value) {},
                    enableActiveFill: true,
                    useExternalAutoFillGroup: true,
                    //TRY BY SET FALSE HERE
                    animationDuration: const Duration(milliseconds: 300),
                    animationType: AnimationType.fade,
                    autoFocus: true,
                    cursorColor: ChanzoColors.primary,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    // obscuringWidget: Text('*', style: pbold_hmd,),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter PIN";
                      }
                      if (value.length < 4) {
                        return "The Pin MUST be 4 digits";
                      }
                      if(widget.pin != value){
                        return "PIN and Confirm PIN did not Match";
                      }
                      if (int.tryParse(value) == null) {
                        return "Only Numeric characters are allowed";
                      } else {
                        return null;
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: InkWell(
                    onTap: () {
                      if (_formKey.currentState!.validate()) {
                        createPin();
                        print('Confirm PIN Clicked');
                      }
                    },
                    borderRadius: BorderRadius.circular(30.0),
                    child: Ink(
                      height: 55.0,
                      width: width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.0),
                        color: ChanzoColors.primary,
                      ),
                      child: Center(
                        child: Text(
                          'Create PIN',
                          style: GoogleFonts.urbanist(
                            fontSize: 15.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: ChanzoColors.primary,
                      shadowColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent),
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    size: 24.0,
                  ),
                  label: Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void clearPin() {
    pinController.clear();
  }

  void _showToastWrongPin(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: const Text('Wrong PIN'),
        action: SnackBarAction(
            label: 'Try Again', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }

  void _showToastPinNotMatch(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: const Text('The confirm PIN did not Match'),
        action: SnackBarAction(
            label: 'Try Again', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }

  Widget _dialogSetPinWrong(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text("Error"),
      content: Text("Wrong Length"),
      actions: [
        CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Try Again")),
        // CupertinoDialogAction(onPressed: () {}, child: Text("Next")),
      ],
    );
  }
}

class showAlertPinNotMatch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new CupertinoAlertDialog(
      title: Text("Error"),
      actions: [
        CupertinoDialogAction(onPressed: () {}, child: Text("Try Again")),
        // CupertinoDialogAction(onPressed: () {}, child: Text("Next")),
      ],
      content: Text("PIN and Confirm PIN Not Match"),
    );
  }
}

class showAlertPinTooShort extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new CupertinoAlertDialog(
      title: Text("Error"),
      actions: [
        CupertinoDialogAction(onPressed: () {}, child: Text("Try Again")),
        // CupertinoDialogAction(onPressed: () {}, child: Text("Next")),
      ],
      content: Text("PIN should be 4 characters"),
    );
  }
}
