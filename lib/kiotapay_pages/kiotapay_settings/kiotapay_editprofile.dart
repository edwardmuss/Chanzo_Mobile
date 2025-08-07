import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kiotapay/globalclass/global_methods.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_models/user_model.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pull_to_refresh/pull_to_refresh.dart';

class KiotaPayEditProfile extends StatefulWidget {
  const KiotaPayEditProfile({super.key});


  @override
  State<KiotaPayEditProfile> createState() => _KiotaPayEditProfileState();
}

class _KiotaPayEditProfileState extends State<KiotaPayEditProfile> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());
  RefreshController refreshController =
  RefreshController(initialRefresh: false);
  final _formKey = GlobalKey<FormState>();
  late TextEditingController userFirstNameController =
      TextEditingController(text: authController.userFirstName);

  late TextEditingController userMiddleNameController =
  TextEditingController(text: authController.userMiddleName);

  late TextEditingController userLastNameController =
  TextEditingController(text: authController.userLastName);

  late TextEditingController phoneController =
      TextEditingController(text: authController.userPhone);

  late TextEditingController primaryEmailController =
      TextEditingController(text: authController.userEmail);

  isInternetConnected() async {
    bool isConnected = await checkNetwork();
    if (!isConnected) {
      showSnackBar(context, "No internet connection", Colors.red, 2.00, 2, 10);
      return;
    }
  }

  @override
  void initState() {
    refreshUserProfile(context);
    super.initState();
  }

  Future<void> updateprofile() async {
    isInternetConnected();
    isLoginedIn();
    showLoading('Updating...');
    var minutes = await getTokenExpiryMinutes();
    if (minutes < 4) {
      refreshToken();
    }
    var token = await getAccessToken();
    var headers = {
      'Authorization': 'Bearer $token',
      "Content-Type": "application/json"
    };
    var body = {
      "phone":phoneController.text,
      "first_name":userFirstNameController.text,
      "middle_name":userMiddleNameController.text,
      "last_name":userLastNameController.text,
      "email":primaryEmailController.text,
    };
    try {
      var url = Uri.parse(KiotaPayConstants.updateProfile);
      http.Response response =
      await http.put(url, body: jsonEncode(body), headers: headers);
      print("Response body is: " +
          response.body.toString() +
          " and Code is " +
          response.statusCode.toString());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        var msg = jsonDecode(response.body)['msg'];
        hideLoading();
        awesomeDialog(context, "Success", msg.toString(), true, DialogType.info,
            ChanzoColors.primary)
          ..show();
        // Navigator.of(context).pop();
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).colorScheme.onSecondaryContainer,
        // centerTitle: true,
        title: Text(
          "Edit_Profile".tr,
          style: pmedium.copyWith(
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: width / 36, vertical: height / 36),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: ChanzoColors.lightPrimary,
                    child: CachedNetworkImage(
                      imageUrl: authController.user['avatar'] != null
                          ? '${KiotaPayConstants.webUrl}storage/${authController.user['avatar']}'
                          : '', // Empty string will trigger errorWidget
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      placeholder: (context, url) => CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage(KiotaPayPngimage.profile),
                      ),
                      errorWidget: (context, url, error) => CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage(KiotaPayPngimage.profile),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: height / 56,
                ),
                Center(
                  child: Text(
                    "${authController.userFullName}",
                    style: pmedium.copyWith(
                      fontSize: 17,
                    ),
                  ),
                ),
                SizedBox(
                  height: height / 200,
                ),
                Center(
                  child: Text(
                    "${authController.userPhone}",
                    style: pregular.copyWith(
                        fontSize: 12, color: ChanzoColors.textgrey),
                  ),
                ),
                SizedBox(
                  height: height / 26,
                ),
                Text(
                  "First Name".tr,
                  style: pregular_md.copyWith(color: ChanzoColors.textgrey),
                ),
                SizedBox(
                  height: height / 200,
                ),
                TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Full Name is required';
                      }
                      return null;
                    },
                    controller: userFirstNameController,
                    scrollPadding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    style: pregular.copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter First Name'.tr,
                      hintStyle: pregular.copyWith(fontSize: 14),
                      prefixIcon: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Image.asset(
                            KiotaPayPngimage.userprofile,
                            height: height / 36,
                            color: ChanzoColors.textgrey,
                          )),
                      enabledBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide:
                              const BorderSide(color: ChanzoColors.textfield)),
                      focusedBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide:
                              const BorderSide(color: ChanzoColors.primary)),
                    )),
                SizedBox(
                  height: height / 36,
                ),
                Text(
                  "Middle Name".tr,
                  style: pregular_md.copyWith(color: ChanzoColors.textgrey),
                ),
                SizedBox(
                  height: height / 200,
                ),
                TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Middle name is required';
                      }
                      return null;
                    },
                    controller: userMiddleNameController,
                    scrollPadding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    style: pregular.copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter Middle Name'.tr,
                      hintStyle: pregular.copyWith(fontSize: 14),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Icon(BootstrapIcons.at),
                      ),
                      enabledBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide:
                              const BorderSide(color: ChanzoColors.textfield)),
                      focusedBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide:
                              const BorderSide(color: ChanzoColors.primary)),
                    )),
                SizedBox(
                  height: height / 36,
                ),
                Text(
                  "Last Name".tr,
                  style: pregular_md.copyWith(color: ChanzoColors.textgrey),
                ),
                SizedBox(
                  height: height / 200,
                ),
                TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Last name is required';
                      }
                      return null;
                    },
                    controller: userLastNameController,
                    scrollPadding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    style: pregular.copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter Last Name'.tr,
                      hintStyle: pregular.copyWith(fontSize: 14),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Icon(BootstrapIcons.person),
                      ),
                      enabledBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide:
                          const BorderSide(color: ChanzoColors.textfield)),
                      focusedBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide:
                          const BorderSide(color: ChanzoColors.primary)),
                    )),
                SizedBox(
                  height: height / 36,
                ),
                Text(
                  "Email_Address".tr,
                  style: pregular_md.copyWith(color: ChanzoColors.textgrey),
                ),
                SizedBox(
                  height: height / 200,
                ),
                TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      return null;
                    },
                    controller: primaryEmailController,
                    scrollPadding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    style: pregular.copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter_Email_Address'.tr,
                      hintStyle: pregular.copyWith(fontSize: 14),
                      prefixIcon: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Image.asset(
                            KiotaPayPngimage.email,
                            height: height / 36,
                            color: ChanzoColors.textgrey,
                          )),
                      enabledBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide:
                              const BorderSide(color: ChanzoColors.textfield)),
                      focusedBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide:
                              const BorderSide(color: ChanzoColors.primary)),
                    )),
                SizedBox(
                  height: height / 36,
                ),
                Text(
                  "Phone Number".tr,
                  style: pregular_md.copyWith(color: ChanzoColors.textgrey),
                ),
                SizedBox(
                  height: height / 200,
                ),
                TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Primary Phone Number is required';
                      }
                      return null;
                    },
                    controller: phoneController,
                    scrollPadding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    style: pregular.copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter_Phone_Number'.tr,
                      hintStyle: pregular.copyWith(fontSize: 14),
                      prefixIcon: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Image.asset(
                            KiotaPayPngimage.call,
                            height: height / 36,
                            color: ChanzoColors.textgrey,
                          )),
                      enabledBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide:
                              const BorderSide(color: ChanzoColors.textfield)),
                      focusedBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide:
                              const BorderSide(color: ChanzoColors.primary)),
                    )),
                SizedBox(
                  height: height / 36,
                ),

                // Text(
                //   "Birth_Date".tr,
                //   style: pregular.copyWith(
                //       fontSize: 14, color: ChanzoColors.textgrey),
                // ),
                // SizedBox(
                //   height: height / 200,
                // ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     SizedBox(
                //       width: width / 3.5,
                //       child: TextFormField(
                //           scrollPadding: EdgeInsets.only(
                //               bottom: MediaQuery.of(context).viewInsets.bottom),
                //           style: pregular.copyWith(fontSize: 14),
                //           textAlign: TextAlign.center,
                //           decoration: InputDecoration(
                //             hintText: 'Date'.tr,
                //             hintStyle: pregular.copyWith(fontSize: 14),
                //             enabledBorder: UnderlineInputBorder(
                //                 borderRadius: BorderRadius.circular(0),
                //                 borderSide: const BorderSide(
                //                     color: ChanzoColors.textfield)),
                //             focusedBorder: UnderlineInputBorder(
                //                 borderRadius: BorderRadius.circular(0),
                //                 borderSide: const BorderSide(
                //                     color: ChanzoColors.primary)),
                //           )),
                //     ),
                //     SizedBox(
                //       width: width / 3.5,
                //       child: TextFormField(
                //           scrollPadding: EdgeInsets.only(
                //               bottom: MediaQuery.of(context).viewInsets.bottom),
                //           style: pregular.copyWith(fontSize: 14),
                //           textAlign: TextAlign.center,
                //           decoration: InputDecoration(
                //             hintText: 'Month'.tr,
                //             hintStyle: pregular.copyWith(fontSize: 14),
                //             enabledBorder: UnderlineInputBorder(
                //                 borderRadius: BorderRadius.circular(0),
                //                 borderSide: const BorderSide(
                //                     color: ChanzoColors.textfield)),
                //             focusedBorder: UnderlineInputBorder(
                //                 borderRadius: BorderRadius.circular(0),
                //                 borderSide: const BorderSide(
                //                     color: ChanzoColors.primary)),
                //           )),
                //     ),
                //     SizedBox(
                //       width: width / 3.5,
                //       child: TextFormField(
                //           scrollPadding: EdgeInsets.only(
                //               bottom: MediaQuery.of(context).viewInsets.bottom),
                //           style: pregular.copyWith(fontSize: 14),
                //           textAlign: TextAlign.center,
                //           decoration: InputDecoration(
                //             hintText: 'Year'.tr,
                //             hintStyle: pregular.copyWith(fontSize: 14),
                //             enabledBorder: UnderlineInputBorder(
                //                 borderRadius: BorderRadius.circular(0),
                //                 borderSide: const BorderSide(
                //                     color: ChanzoColors.textfield)),
                //             focusedBorder: UnderlineInputBorder(
                //                 borderRadius: BorderRadius.circular(0),
                //                 borderSide: const BorderSide(
                //                     color: ChanzoColors.primary)),
                //           )),
                //     ),
                //   ],
                // ),
                // SizedBox(
                //   height: height / 36,
                // ),
                InkWell(
                  splashColor: ChanzoColors.transparent,
                  highlightColor: ChanzoColors.transparent,
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      isLoginedIn();
                      updateprofile();
                    }
                  },
                  child: Container(
                    height:
                    MediaQuery.of(context).size.height / 15,
                    width:
                    MediaQuery.of(context).size.width / 1.2,
                    decoration: BoxDecoration(
                        color: ChanzoColors.primary,
                        borderRadius:
                        BorderRadius.circular(50)),
                    child: Center(
                      child: Text("Save Changes".tr,
                          style: pbold_md.copyWith(
                              color: ChanzoColors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
