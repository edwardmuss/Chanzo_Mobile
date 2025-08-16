import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_pincode_confirm.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_signin.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class KiotaPaySetPin extends StatefulWidget {
  const KiotaPaySetPin({super.key});

  @override
  State<KiotaPaySetPin> createState() => _KiotaPaySetPinState();
}

class _KiotaPaySetPinState extends State<KiotaPaySetPin> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  late bool initializing = true;
  late String firstPinCode = '';
  late String secondPinCode = '';
  late String _pinHeading = 'Create your PIN';
  String pinError = '';
  String pinSuccess = '';
  final TextEditingController pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  String encodeMobileUserServices(String apiKey, String pin, String apisecret) {
    String concatenatedString = apiKey + pin + apisecret;

    var bytes = utf8.encode(concatenatedString);
    var digest = sha256.convert(bytes);

    String encodedHashString = digest.toString();
    print('Encoded hash: $encodedHashString');

    return encodedHashString;
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter PIN";
                      }
                      if (value.length < 4) {
                        return "The Pin MUST be 4 digits";
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
                        Get.to(() => KiotaPayPinConfirm(pin: pinController.text));
                        print('Set PIN Clicked');
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
                          'Continue',
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
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return const KiotaPaySignIn();
                      },
                    ));
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    size: 24.0,
                  ),
                  label: Text('Back to Login'),
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
