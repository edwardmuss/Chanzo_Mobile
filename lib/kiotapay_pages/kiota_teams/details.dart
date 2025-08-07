import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';
import 'package:kiotapay/globalclass/text_icon_button.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_drawer/kiotapay_drawer.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'package:nb_utils/nb_utils.dart' hide DialogType;
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import 'package:rounded_background_text/rounded_background_text.dart';
import '../../globalclass/global_methods.dart';
import '../../kiotapay_models/teams_model.dart';
import 'package:http/http.dart' as http;

import 'list.dart';

class KiotaPayTeamsDetails extends StatefulWidget {
  const KiotaPayTeamsDetails({super.key, required this.team});

  final Team team;

  @override
  State<KiotaPayTeamsDetails> createState() => _KiotaPayTeamsDetailsState();
}

class _KiotaPayTeamsDetailsState extends State<KiotaPayTeamsDetails> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  double _orgBalance = 0.00;
  double _memberBalance = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _userDataLocal;
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  List<Team>? items = [];
  String? selectedUserUuid;
  int? selectedUserAmount;
  Team? _teamModel;
  RefreshController refreshController =
      RefreshController(initialRefresh: false);
  int page = 0;

  late final teamNameController = TextEditingController(text: widget.team.name);
  late final teamDescriptionController =
      TextEditingController(text: widget.team.description);
  late final teamLimitController =
      TextEditingController(text: widget.team.teamLimit.toString());
  late final teamProjectController = TextEditingController();

  late final teamMemberController = TextEditingController();
  late final teamAmountAllocationController =
      TextEditingController(text: widget.team.teamLimit.toString());

  late final teamReasonController = TextEditingController();

  late final allocationReasonController = TextEditingController();
  late final allocationAmountController = TextEditingController();
  TextEditingController allocationLinkUserController =
      TextEditingController(text: '');
  String _selectedUuid = '';

  bool _validate = false;

  @override
  void initState() {
    super.initState();
    isLoginedIn();
    loadItems();
    getOrgBalance();
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    teamNameController.dispose();
    teamDescriptionController.dispose();
    teamLimitController.dispose();
    teamProjectController.dispose();
    allocationReasonController.dispose();
    allocationAmountController.dispose();
    allocationLinkUserController.dispose();
  }

  void _onRefresh() async {
    isLoginedIn();
    loadItems();
  }

  void _onLoading() async {
    isLoginedIn();
    loadMoreItems();
  }

  loadItems() {
    // refreshController.requestRefresh();
    page = 0;
    setState(() {});
    fetchItems();
    getOrgBalance();
    getUserData();
  }

  loadMoreItems() {
    page = page + 1;
    fetchItems();
  }

  void setItems(List<Team>? item) {
    items!.clear();
    items = item;
    print("SetItems $item");
    refreshController.refreshCompleted();
    setState(() {});
  }

  void setMoreItems(List<Team> item) {
    refreshController.loadComplete();
    items!.addAll(item);
    setState(() {});
  }

  isInternetConnected() async {
    bool isConnected = await checkNetwork();
    if (!isConnected) {
      showSnackBar(context, "No internet connection", Colors.red, 2.00, 2, 10);
      return;
    }
  }

  Future<void> onQueryChanged(String userName, String uuid) async {
    setState(() {
      allocationLinkUserController = TextEditingController(text: userName);
      _selectedUuid = uuid;
    });
  }

  getUserData() async {
    final SharedPreferences? prefs = await _prefs;
    String? userPref = prefs!.getString('user') ?? '';
    Map<String, dynamic> userData =
        jsonDecode(userPref) as Map<String, dynamic>;
    print(userData['access_token']);
    if (prefs.getString('access_token') != null)
      setState(() {
        _userDataLocal = jsonDecode(userPref) as Map<String, dynamic>;
      });
    print("getuser is $_userDataLocal");
  }

  getOrgBalance() async {
    try {
      isLoginedIn();
      var token = await getAccessToken();
      var headers = {'Authorization': 'Bearer $token'};
      var response = await http.get(Uri.parse(KiotaPayConstants.orgWallet),
          headers: headers);
      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        print("The User Org Wallet is ${res['balance']}");
        setState(() async {
          _orgBalance = res['balance'].toDouble();
        });
      } else {
        print("Not 200 Res" + response.body);
        return;
      }
    } catch (exception) {
      print("Exception $exception");
      return;
    }
  }

  Future<Team?> fetchItems() async {
    try {
      var minutes = await getTokenExpiryMinutes();
      if (minutes < 4) {
        refreshToken();
      }
      var token = await getAccessToken();
      var headers = {'Authorization': 'Bearer $token'};
      var _body = jsonEncode({"page": page.toString()});
      showLoading('Loading Teams...');
      var response = await http.get(Uri.parse(KiotaPayConstants.getAllTeams),
          headers: headers);
      // print(response);
      if (response.statusCode == 200) {
        hideLoading();
        dynamic res = jsonDecode(response.body);
        // print(res);

        List<Team>? itemList = parseItemsList(res);
        print(itemList);
        setItems(itemList);
        // if (page == 0) {
        //   setItems(itemList);
        // } else {
        //   setMoreItems(itemList!);
        // }
      } else {
        hideLoading();
        print("Not 200 Res" + response.body);
        // If the server did not return a 200 OK response,
        // then throw an exception.
        showSnackBar(context, "An error occurred", Colors.red, 2.00, 2, 8);
      }
    } catch (exception) {
      hideLoading();
      // I get no exception here
      print("Exception $exception");
    }
    return null;
  }

  static List<Team>? parseItemsList(dynamic res) {
    final parsed = res['data'].cast<Map<String, dynamic>>();
    return parsed.map<Team>((json) => Team.fromJson(json)).toList();
  }

  Future<void> editTeamMember() async {
    isInternetConnected();
    isLoginedIn();
    showLoading("Sending request...");
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
      'name': teamNameController.text,
      'description': teamDescriptionController.text,
      'link_team': widget.team.uuid
    };
    try {
      var url = Uri.parse(KiotaPayConstants.updateTeam);
      http.Response response =
          await http.put(url, body: jsonEncode(body), headers: headers);
      print("Response body is: " +
          response.body.toString() +
          "and Code is " +
          response.statusCode.toString());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        var msg = jsonDecode(response.body)['msg'];
        hideLoading();
        teamNameController.clear();
        teamDescriptionController.clear();
        teamLimitController.clear();

        awesomeDialog(context, "Success", msg.toString(), true, DialogType.info,
            ChanzoColors.primary)
          ..show();
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.of(context).pop();
          Get.to(() => KiotaPayTeams());
        });
      } else {
        var _error =
            jsonDecode(response.body)['message'] ?? "Unknown Error Occurred";
        // _dialog..dismiss();
        // context.loaderOverlay.hide();
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

  Future<void> allocateMemberMoney() async {
    isInternetConnected();
    isLoginedIn();
    showLoading("Sending request...");
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
      'amount': allocationAmountController.text.toInt(),
      'link_user': selectedUserUuid,
      'reason': allocationReasonController.text
    };
    try {
      var url = Uri.parse(KiotaPayConstants.allocateMemberMoney);
      http.Response response =
          await http.post(url, body: jsonEncode(body), headers: headers);
      print("Response body is: " +
          response.body.toString() +
          "and Code is " +
          response.statusCode.toString());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        var msg = jsonDecode(response.body)['msg'];
        hideLoading();
        teamAmountAllocationController.clear();

        awesomeDialog(context, "Success", msg.toString(), true, DialogType.info,
            ChanzoColors.primary)
          ..show();
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.of(context).pop();
          Get.to(() => KiotaPayTeams());
        });
      } else {
        var _error =
            jsonDecode(response.body)['message'] ?? "Unknown Error Occurred";
        // _dialog..dismiss();
        // context.loaderOverlay.hide();
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
    }
  }

  Future<void> deAllocateMemberMoney() async {
    isInternetConnected();
    isLoginedIn();
    showLoading("Just a moment...");
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
      'amount': allocationAmountController.text.toInt(),
      'link_user': selectedUserUuid,
      'reason': allocationReasonController.text
    };
    try {
      var url = Uri.parse(KiotaPayConstants.deAllocateMemberMoney);
      http.Response response =
          await http.put(url, body: jsonEncode(body), headers: headers);
      print("Response body is: " +
          response.body.toString() +
          "and Code is " +
          response.statusCode.toString());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        var msg = jsonDecode(response.body)['msg'];
        hideLoading();
        teamAmountAllocationController.clear();

        awesomeDialog(context, "Success", msg.toString(), true, DialogType.info,
            ChanzoColors.primary)
          ..show();
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.of(context).pop();
          Get.to(() => KiotaPayTeams());
        });
      } else {
        var _error =
            jsonDecode(response.body)['message'] ?? "Unknown Error Occurred";
        // _dialog..dismiss();
        // context.loaderOverlay.hide();
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
    }
  }

  Future<void> requestMyAllocation() async {
    isInternetConnected();
    isLoginedIn();
    showLoading("Sending request...");
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
      'amount': allocationAmountController.text.toInt(),
      // 'link_user': selectedUserUuid,
      'narration': allocationReasonController.text
    };
    try {
      var url = Uri.parse(KiotaPayConstants.requestMyAllocation);
      http.Response response =
          await http.post(url, body: jsonEncode(body), headers: headers);
      print("Response body is: " +
          response.body.toString() +
          "and Code is " +
          response.statusCode.toString());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        var msg = jsonDecode(response.body)['msg'];
        hideLoading();
        teamAmountAllocationController.clear();

        awesomeDialog(context, "Success", msg.toString(), true, DialogType.info,
            ChanzoColors.primary)
          ..show();
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.of(context).pop();
          Get.to(() => KiotaPayTeams());
        });
      } else {
        var _error =
            jsonDecode(response.body)['message'] ?? "Unknown Error Occurred";
        // _dialog..dismiss();
        // context.loaderOverlay.hide();
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
    }
  }

  Future<void> requestAllocationForOther() async {
    isInternetConnected();
    isLoginedIn();
    showLoading("Sending request...");
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
      'amount': allocationAmountController.text.toInt(),
      'link_user': selectedUserUuid,
      'narration': allocationReasonController.text
    };
    try {
      var url = Uri.parse(KiotaPayConstants.requestAllocationForOther);
      http.Response response =
          await http.post(url, body: jsonEncode(body), headers: headers);
      print("Response body is: " +
          response.body.toString() +
          "and Code is " +
          response.statusCode.toString());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        var msg = jsonDecode(response.body)['msg'];
        hideLoading();
        teamAmountAllocationController.clear();

        awesomeDialog(context, "Success", msg.toString(), true, DialogType.info,
            ChanzoColors.primary)
          ..show();
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.of(context).pop();
          Get.to(() => KiotaPayTeams());
        });
      } else {
        var _error =
            jsonDecode(response.body)['message'] ?? "Unknown Error Occurred";
        // _dialog..dismiss();
        // context.loaderOverlay.hide();
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
    }
  }

  Future<void> deleteItem() async {
    isInternetConnected();
    showLoading('Deleting Team...');
    var minutes = await getTokenExpiryMinutes();
    if (minutes < 4) {
      refreshToken();
    }
    var token = await getAccessToken();
    var headers = {
      'Authorization': 'Bearer $token',
      "Content-Type": "application/json"
    };
    var body = {'link_team': widget.team.uuid};
    try {
      var url = Uri.parse(KiotaPayConstants.deleteTeam);
      http.Response response =
          await http.delete(url, body: jsonEncode(body), headers: headers);
      print("Response body is: " +
          response.body.toString() +
          "and Code is " +
          response.statusCode.toString());
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        var msg = jsonDecode(response.body)['msg'];
        hideLoading();

        awesomeDialog(context, "Success", msg.toString(), true, DialogType.info,
            ChanzoColors.primary)
          ..show();
        Future.delayed(const Duration(seconds: 3), () {
          Get.off(() => KiotaPayTeams());
        });
      } else {
        var _error =
            jsonDecode(response.body)['message'] ?? "Unknown Error Occurred";
        // _dialog..dismiss();
        // context.loaderOverlay.hide();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    print(_userData);

    void editTeam() => showModalBottomSheet(
          isScrollControlled: true,
          // set this when inner content overflows, making RoundedRectangleBorder not working as expected
          clipBehavior: Clip.antiAlias,
          // set shape to make top corners rounded
          // shape: const RoundedRectangleBorder(
          //   borderRadius: BorderRadius.only(
          //     topLeft: Radius.circular(16),
          //     topRight: Radius.circular(16),
          //   ),
          // ),
          context: context,
          builder: (context) {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                      left: 20.00,
                      right: 20.00,
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        'Edit Team',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Edit Team here',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: ChanzoColors.textgrey,
                            fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Team name is required';
                          }
                          return null;
                        },
                        controller: teamNameController,
                        decoration: InputDecoration(
                          labelText: 'Team Name',
                          border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: ChanzoColors.lightPrimary)),
                        ),
                        // minLines: 3,
                        keyboardType: TextInputType.name,
                        maxLines: null,
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: teamDescriptionController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Team description is required';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: ChanzoColors.lightPrimary)),
                        ),
                        // minLines: 3,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: teamLimitController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Spend limit is required';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Team Spending Limit',
                          border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: ChanzoColors.lightPrimary)),
                        ),
                        // minLines: 3,
                        keyboardType: TextInputType.number,
                        maxLines: null,
                      ),
                      SizedBox(height: 15),
                      InkWell(
                        splashColor: ChanzoColors.transparent,
                        highlightColor: ChanzoColors.transparent,
                        onTap: () async {
                          print('Team Edit btn clicked');

                          if (_formKey.currentState!.validate()) {
                            isLoginedIn();
                            editTeamMember();
                          }
                        },
                        child: Container(
                          height: height / 15,
                          width: width / 1.2,
                          decoration: BoxDecoration(
                              color: ChanzoColors.primary,
                              borderRadius: BorderRadius.circular(50)),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Update Team".tr,
                                  style: psemibold.copyWith(
                                      fontSize: 14,
                                      color: ChanzoColors.white),
                                ),
                                IconButton(
                                  onPressed: () {},
                                  icon: Icon(BootstrapIcons.arrow_right_circle),
                                  color: ChanzoColors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            );
          },
        );
    void showTeamUsers() => showModalBottomSheet(
          // isScrollControlled: true,
          clipBehavior: Clip.antiAlias,
          context: context,
          builder: (context) {
            return ListView.builder(
              itemCount: widget.team.users.length,
              itemBuilder: (BuildContext context, int index) {
                final user = widget.team.users[index];
                return ListTile(
                  onTap: () {
                    // var fullname = user.clientData.fullName;
                    // setState(() {
                    //   allocationLinkUserController.text ==
                    //       TextEditingController(text: fullname);
                    //   _selectedUuid = user.uuid;
                    // });
                    onQueryChanged(user.clientData.fullName, user.uuid);
                    print("hello ${allocationLinkUserController.text}");
                    Navigator.of(context).pop();
                    // showSnackBar(context, "User id is ${allocationLinkUserController.text}", ChanzoColors.primary, 2.00, 2, 10);
                  },
                  // leading: Icon(Icons.payment),
                  title: Text(
                    user.clientData.fullName,
                    style: pregular_lg,
                  ),
                );
              },
            );
          },
        );

    void requestAllocation() => showModalBottomSheet(
          isScrollControlled: true,
          clipBehavior: Clip.antiAlias,
          context: context,
          builder: (context) {
            return StatefulBuilder(builder: (context, setStateSB) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: 20.00,
                        right: 20.00,
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 50),
                        Text(
                          'Request Allocation',
                          style: pregular_hmd.copyWith(
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Available Business balance: KES ${_orgBalance} ',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  color: ChanzoColors.secondary,
                                  fontWeight: FontWeight.w300),
                        ),
                        SizedBox(height: 20),
                        DropdownButtonFormField<User>(
                          decoration: InputDecoration(
                            labelText: 'Team Member',
                            border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: ChanzoColors.lightPrimary)),
                          ),
                          hint: Text('Select Member'),
                          // value: selectedUserUuid,
                          onChanged: (User? value) {
                            setStateSB(() {
                              selectedUserUuid = value!.uuid;
                            });
                            setState(() {
                              selectedUserUuid = value!.uuid;
                              selectedUserAmount = value.walletAmount;
                            });
                            print('Selected user UUID: $selectedUserUuid');
                          },
                          validator: (value) {
                            if (value == null || value.uuid.isEmpty) {
                              return 'Team Member is required';
                            }
                            return null;
                          },
                          items: widget.team.users
                              .map((user) => DropdownMenuItem<User>(
                                    value: user,
                                    // assuming 'uuid' is unique for each user
                                    child: Text(user.clientData.fullName),
                                  ))
                              .toList(),
                        ),
                        Text(
                          selectedUserAmount != null
                              ? "User current balance: $selectedUserAmount"
                              : "",
                          style: pregular_sm.copyWith(
                              color: ChanzoColors.textgrey),
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: allocationAmountController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Amount is required';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: ChanzoColors.lightPrimary)),
                          ),
                          // minLines: 3,
                          keyboardType: TextInputType.number,
                          maxLines: null,
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: allocationReasonController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Reason is required';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Reason',
                            border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: ChanzoColors.lightPrimary)),
                          ),
                          // minLines: 3,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                        ),
                        SizedBox(height: 15),
                        InkWell(
                          splashColor: ChanzoColors.transparent,
                          highlightColor: ChanzoColors.transparent,
                          onTap: () async {
                            print('allocate btn clicked');

                            if (_formKey.currentState!.validate()) {
                              isLoginedIn();
                              requestAllocationForOther();
                            }
                          },
                          child: Container(
                            height: height / 15,
                            width: width / 1.2,
                            decoration: BoxDecoration(
                                color: ChanzoColors.primary,
                                borderRadius: BorderRadius.circular(50)),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () {},
                                    icon: Icon(BootstrapIcons.wallet),
                                    color: ChanzoColors.white,
                                  ),
                                  Text(
                                    "Request Allocation".tr,
                                    style: psemibold.copyWith(
                                        fontSize: 14,
                                        color: ChanzoColors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              );
            });
          },
        );

    void requestMyAllocationForm() => showModalBottomSheet(
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateSB) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                    left: 20.00,
                    right: 20.00,
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 50),
                    Text(
                      'Request Allocation',
                      style: pregular_hmd.copyWith(
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Available Business balance: KES ${_orgBalance} ',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(
                          color: ChanzoColors.secondary,
                          fontWeight: FontWeight.w300),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: allocationAmountController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Amount is required';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: ChanzoColors.lightPrimary)),
                      ),
                      // minLines: 3,
                      keyboardType: TextInputType.number,
                      maxLines: null,
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: allocationReasonController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Reason is required';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Reason',
                        border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: ChanzoColors.lightPrimary)),
                      ),
                      // minLines: 3,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                    ),
                    SizedBox(height: 15),
                    InkWell(
                      splashColor: ChanzoColors.transparent,
                      highlightColor: ChanzoColors.transparent,
                      onTap: () async {
                        print('allocate btn clicked');

                        if (_formKey.currentState!.validate()) {
                          isLoginedIn();
                          requestMyAllocation();
                        }
                      },
                      child: Container(
                        height: height / 15,
                        width: width / 1.2,
                        decoration: BoxDecoration(
                            color: ChanzoColors.primary,
                            borderRadius: BorderRadius.circular(50)),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: Icon(BootstrapIcons.wallet),
                                color: ChanzoColors.white,
                              ),
                              Text(
                                "Request Allocation".tr,
                                style: psemibold.copyWith(
                                    fontSize: 14,
                                    color: ChanzoColors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );

    void allocateTeam() => showModalBottomSheet(
          isScrollControlled: true,
          clipBehavior: Clip.antiAlias,
          context: context,
          builder: (context) {
            return StatefulBuilder(builder: (context, setStateSB) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: 20.00,
                        right: 20.00,
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 50),
                        Text(
                          'Allocate Member money',
                          style: pregular_hmd.copyWith(
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Available Business balance: KES ${_orgBalance} ',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  color: ChanzoColors.secondary,
                                  fontWeight: FontWeight.w300),
                        ),
                        SizedBox(height: 20),
                        DropdownButtonFormField<User>(
                          decoration: InputDecoration(
                            labelText: 'Team Member',
                            border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: ChanzoColors.lightPrimary)),
                          ),
                          hint: Text('Select Member'),
                          // value: selectedUserUuid,
                          onChanged: (User? value) {
                            setStateSB(() {
                              selectedUserUuid = value!.uuid;
                            });
                            setState(() {
                              selectedUserUuid = value!.uuid;
                              selectedUserAmount = value.walletAmount;
                            });
                            print('Selected user UUID: $selectedUserUuid');
                          },
                          validator: (value) {
                            if (value == null || value.uuid.isEmpty) {
                              return 'Team Member is required';
                            }
                            return null;
                          },
                          items: widget.team.users
                              .map((user) => DropdownMenuItem<User>(
                                    value: user,
                                    // assuming 'uuid' is unique for each user
                                    child: Text(user.clientData.fullName),
                                  ))
                              .toList(),
                        ),
                        Text(
                          selectedUserAmount != null
                              ? "User current balance: $selectedUserAmount"
                              : "",
                          style: pregular_sm.copyWith(
                              color: ChanzoColors.textgrey),
                        ),
                        // TextFormField(
                        //   readOnly: true,
                        //   onTap: () {
                        //     // Navigator.of(context).pop();
                        //     showTeamUsers();
                        //   },
                        //   validator: (value) {
                        //     if (value == null || value.isEmpty) {
                        //       return 'Team Member is required';
                        //     }
                        //     return null;
                        //   },
                        //   controller: allocationLinkUserController,
                        //   // initialValue: _selectedUuid,
                        //   decoration: InputDecoration(
                        //     labelText: 'Team Member',
                        //     border: OutlineInputBorder(
                        //         borderSide: BorderSide(
                        //             color: ChanzoColors.lightPrimary)),
                        //   ),
                        //   // minLines: 3,
                        //   keyboardType: TextInputType.name,
                        //   maxLines: null,
                        // ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: allocationAmountController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Amount is required';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: ChanzoColors.lightPrimary)),
                          ),
                          // minLines: 3,
                          keyboardType: TextInputType.number,
                          maxLines: null,
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: allocationReasonController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Allocation reason is required';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Reason',
                            border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: ChanzoColors.lightPrimary)),
                          ),
                          // minLines: 3,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                        ),
                        SizedBox(height: 15),
                        InkWell(
                          splashColor: ChanzoColors.transparent,
                          highlightColor: ChanzoColors.transparent,
                          onTap: () async {
                            print('allocate btn clicked');

                            if (_formKey.currentState!.validate()) {
                              isLoginedIn();
                              allocateMemberMoney();
                            }
                          },
                          child: Container(
                            height: height / 15,
                            width: width / 1.2,
                            decoration: BoxDecoration(
                                color: ChanzoColors.primary,
                                borderRadius: BorderRadius.circular(50)),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () {},
                                    icon: Icon(BootstrapIcons.wallet),
                                    color: ChanzoColors.white,
                                  ),
                                  Text(
                                    "Allocate Money".tr,
                                    style: psemibold.copyWith(
                                        fontSize: 14,
                                        color: ChanzoColors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              );
            });
          },
        );

    void deAllocateTeam() => showModalBottomSheet(
          isScrollControlled: true,
          clipBehavior: Clip.antiAlias,
          context: context,
          builder: (context) {
            return StatefulBuilder(builder: (context, setStateSB) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: 20.00,
                        right: 20.00,
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 50),
                        Text(
                          'Deallocate Member Money',
                          style: pregular_hmd.copyWith(
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Available Business balance: KES ${_orgBalance} ',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  color: ChanzoColors.secondary,
                                  fontWeight: FontWeight.w300),
                        ),
                        SizedBox(height: 20),
                        DropdownButtonFormField<User>(
                          decoration: InputDecoration(
                            labelText: 'Team Member',
                            border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: ChanzoColors.lightPrimary)),
                          ),
                          hint: Text('Select Member'),
                          // value: selectedUserUuid,
                          onChanged: (User? value) {
                            setStateSB(() {
                              selectedUserUuid = value!.uuid;
                            });
                            setState(() {
                              selectedUserUuid = value!.uuid;
                              selectedUserAmount = value.walletAmount;
                            });
                            print('Selected user UUID: $selectedUserUuid');
                          },
                          validator: (value) {
                            if (value == null || value.uuid.isEmpty) {
                              return 'Team Member is required';
                            }
                            return null;
                          },
                          items: widget.team.users
                              .map((user) => DropdownMenuItem<User>(
                                    value: user,
                                    // assuming 'uuid' is unique for each user
                                    child: Text(user.clientData.fullName),
                                  ))
                              .toList(),
                        ),
                        Text(
                          selectedUserAmount != null
                              ? "User current balance: $selectedUserAmount"
                              : "",
                          style: pregular_sm.copyWith(
                              color: ChanzoColors.textgrey),
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: allocationAmountController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Amount is required';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Deallocation Amount',
                            border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: ChanzoColors.lightPrimary)),
                          ),
                          // minLines: 3,
                          keyboardType: TextInputType.number,
                          maxLines: null,
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: allocationReasonController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Deallocation reason is required';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Deallocation Reason',
                            border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: ChanzoColors.lightPrimary)),
                          ),
                          // minLines: 3,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                        ),
                        SizedBox(height: 15),
                        InkWell(
                          splashColor: ChanzoColors.transparent,
                          highlightColor: ChanzoColors.transparent,
                          onTap: () async {
                            print('de-allocate btn clicked');

                            if (_formKey.currentState!.validate()) {
                              isLoginedIn();
                              deAllocateMemberMoney();
                            }
                          },
                          child: Container(
                            height: height / 15,
                            width: width / 1.2,
                            decoration: BoxDecoration(
                                color: ChanzoColors.primary,
                                borderRadius: BorderRadius.circular(50)),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () {},
                                    icon: Icon(BootstrapIcons.wallet),
                                    color: ChanzoColors.white,
                                  ),
                                  Text(
                                    "De-Allocate Money".tr,
                                    style: psemibold.copyWith(
                                        fontSize: 14,
                                        color: ChanzoColors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              );
            });
          },
        );

    void choseAllocateDeallocate() => showModalBottomSheet(
          isScrollControlled: true,
// set this when inner content overflows, making RoundedRectangleBorder not working as expected
          clipBehavior: Clip.antiAlias,
// set shape to make top corners rounded
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          context: context,
          builder: (context) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 25,
                  ),
                  TextIconButton(
                    onPressed: () {
                      print('Allocate Button Clicked');
                      Navigator.pop(context);
                      allocateTeam();
                    },
                    icon: BootstrapIcons.plus,
                    size: 30,
                    label: 'Allocate Member Money',
                    leftIcon: BootstrapIcons.chevron_right,
                  ),
                  TextIconButton(
                    onPressed: () {
                      print('Deallocate Button Clicked');
                      Navigator.pop(context);
                      deAllocateTeam();
                    },
                    icon: BootstrapIcons.dash,
                    size: 30,
                    label: 'Deallocate Member Money',
                    leftIcon: BootstrapIcons.chevron_right,
                  ),
                  SizedBox(
                    height: 50,
                  ),
                ],
              ),
            );
          },
        );
    void chooseRequestAllocationType() => showModalBottomSheet(
          isScrollControlled: true,
// set this when inner content overflows, making RoundedRectangleBorder not working as expected
          clipBehavior: Clip.antiAlias,
// set shape to make top corners rounded
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          context: context,
          builder: (context) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 25,
                  ),
                  TextIconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      requestMyAllocationForm();
                    },
                    icon: BootstrapIcons.arrow_right_circle,
                    size: 30,
                    label: 'Request Allocation',
                    leftIcon: BootstrapIcons.chevron_right,
                  ),
                  TextIconButton(
                    onPressed: () {;
                      Navigator.pop(context);
                      requestAllocation();
                    },
                    icon: BootstrapIcons.arrow_right_circle,
                    size: 30,
                    label: 'Request for other',
                    leftIcon: BootstrapIcons.chevron_right,
                  ),
                  SizedBox(
                    height: 50,
                  ),
                ],
              ),
            );
          },
        );

    return Scaffold(
      drawer: const KiotaPayDrawer(),
      body: SmartRefresher(
        controller: refreshController,
        enablePullDown: true,
        // enablePullUp: true,
        header: WaterDropHeader(),
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        // footer: CustomFooter(
        //   builder: (BuildContext context, LoadStatus? mode) {
        //     Widget body;
        //     if (mode == LoadStatus.idle) {
        //       body = Text("Pull up to load more");
        //     } else if (mode == LoadStatus.loading) {
        //       body = CupertinoActivityIndicator();
        //     } else if (mode == LoadStatus.failed) {
        //       body = Text("Failed, Retry");
        //     } else if (mode == LoadStatus.canLoading) {
        //       body = Text("Release Load More");
        //     } else {
        //       body = Text("No More data");
        //     }
        //     return Container(
        //       height: 55.0,
        //       child: Center(child: body),
        //     );
        //   },
        // ),
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: ChanzoColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height / 15),
                Padding(
                  padding: const EdgeInsets.only(left: 16.00, right: 16.00),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ClipOval(
                            child: Material(
                              color: ChanzoColors.white, // Button color
                              child: InkWell(
                                splashColor: ChanzoColors.primary,
                                // Splash color
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: SizedBox(
                                  width: 35,
                                  height: 35,
                                  child: Icon(
                                    BootstrapIcons.chevron_left,
                                    size: 25,
                                    color: ChanzoColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ClipOval(
                            child: Material(
                              color: ChanzoColors.white, // Button color
                              child: InkWell(
                                splashColor: ChanzoColors.primary,
                                // Splash color
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: SizedBox(
                                  width: 35,
                                  height: 35,
                                  child: Icon(
                                    BootstrapIcons.chevron_left,
                                    size: 25,
                                    color: ChanzoColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(
                        widget.team.name,
                        style: pbold_hmd.copyWith(color: ChanzoColors.white),
                      ),
                      Text(
                        widget.team.description,
                        style: pregular_md.copyWith(
                            color: ChanzoColors.primary80),
                      ),
                      SizedBox(height: height / 35),
                      Container(
                        // height: 240,
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ChanzoColors.lightPrimary,
                              ChanzoColors.primary80,
                              ChanzoColors.primary50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        // Adds a gradient background and rounded corners to the container
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Business Total",
                                ),
                                // Adds a subtitle to the card
                                SizedBox(height: 10),
                                Text(
                                  "KES " +
                                      decimalformatedNumber
                                          .format(_orgBalance)
                                          .toString(),
                                  style: psemibold.copyWith(
                                      fontSize: 25,
                                      color: ChanzoColors.white),
                                ),
                                SizedBox(height: 10),
                                // Row(
                                //   mainAxisAlignment: MainAxisAlignment.center,
                                //   children: [
                                //     Initicon(text: "T1"),
                                //     Initicon(text: "T2"),
                                //   ],
                                // ),
                                InkWell(
                                  splashColor: ChanzoColors.transparent,
                                  highlightColor: ChanzoColors.transparent,
                                  onTap: () async {
                                    print('Allocate btn clicked');
                                    _userDataLocal != null &&
                                            _userDataLocal![
                                                    'allocation_request'] !=
                                                null &&
                                            _userDataLocal![
                                                    'allocation_request']
                                                .isNotEmpty
                                        ? chooseRequestAllocationType()
                                        : choseAllocateDeallocate();
                                  },
                                  child: Container(
                                    height: height / 15,
                                    width: width / 1.2,
                                    decoration: BoxDecoration(
                                        color: ChanzoColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(50)),
                                    child: Center(
                                      child: _userDataLocal != null &&
                                              _userDataLocal![
                                                      'allocation_request'] !=
                                                  null &&
                                              _userDataLocal![
                                                      'allocation_request']
                                                  .isNotEmpty
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  onPressed: () {
                                                    choseAllocateDeallocate();
                                                  },
                                                  icon: Icon(
                                                      BootstrapIcons.wallet),
                                                  color: ChanzoColors.white,
                                                ),
                                                Text("Request Allocation".tr,
                                                    style: psemibold.copyWith(
                                                        fontSize: 14,
                                                        color: ChanzoColors
                                                            .white)),
                                              ],
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  onPressed: () {
                                                    choseAllocateDeallocate();
                                                  },
                                                  icon: Icon(
                                                      BootstrapIcons.wallet),
                                                  color: ChanzoColors.white,
                                                ),
                                                Text("Allocate/De-allocate".tr,
                                                    style: psemibold.copyWith(
                                                        fontSize: 14,
                                                        color: ChanzoColors
                                                            .white)),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Adds a price to the bottom of the card
                          ],
                        ),
                      ),
                      SizedBox(height: 50),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: themedata.isdark == false
                        ? ChanzoColors.white
                        : ChanzoColors.bgdark,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 30, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Members ${widget.team.users.length}",
                          style: pbold.copyWith(fontSize: 18),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.team.users.map((user) {
                            return user != null
                                ? ListTile(
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 0.0),
                                    leading: Initicon(
                                      size: 50,
                                      text: '${user.clientData.fullName}',
                                      backgroundColor: ChanzoColors.primary20,
                                      style: TextStyle(
                                        color: ChanzoColors.primary,
                                      ),
                                    ),
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${user.clientData.fullName}',
                                          style: pbold_hsm.copyWith(
                                              color: ChanzoColors.black),
                                        ),
                                        Text('@${user.clientData.username}',
                                            style: pregular_md.copyWith(
                                                color: ChanzoColors.primary)),
                                      ],
                                    ),
                                    trailing: RoundedBackgroundText(
                                      '${user.walletAmount}',
                                      style: pbold_lg.copyWith(
                                          color: ChanzoColors.secondary),
                                      backgroundColor:
                                          ChanzoColors.lightSecondary,
                                    ),
                                  )
                                : Text('No users assigned to this team');
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            InkWell(
              splashColor: ChanzoColors.transparent,
              highlightColor: ChanzoColors.transparent,
              onTap: () async {
                print('Edit Team btn clicked');
                editTeam();
              },
              child: Container(
                height: height / 15,
                width: width / 2.3,
                decoration: BoxDecoration(
                    color: ChanzoColors.primary,
                    borderRadius: BorderRadius.circular(50)),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          editTeam();
                        },
                        icon: Icon(BootstrapIcons.pen),
                        color: ChanzoColors.white,
                      ),
                      Text("Edit Team".tr,
                          style: psemibold.copyWith(
                              fontSize: 14, color: ChanzoColors.white)),
                    ],
                  ),
                ),
              ),
            ),
            InkWell(
              splashColor: ChanzoColors.transparent,
              highlightColor: ChanzoColors.transparent,
              onTap: () async {
                print('Delete Team btn clicked');
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.warning,
                  headerAnimationLoop: false,
                  animType: AnimType.bottomSlide,
                  title: 'Delete Team',
                  desc: 'Are you sure you want to delete ' + widget.team.name,
                  buttonsTextStyle: const TextStyle(color: Colors.white),
                  btnOkColor: ChanzoColors.primary,
                  btnCancelColor: ChanzoColors.secondary,
                  btnOkText: "Delete",
                  showCloseIcon: true,
                  btnCancelOnPress: () {},
                  btnOkOnPress: deleteItem,
                ).show();
              },
              child: Container(
                height: height / 15,
                width: width / 2.3,
                decoration: BoxDecoration(
                    color: ChanzoColors.secondary,
                    borderRadius: BorderRadius.circular(50)),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          AwesomeDialog(
                            context: context,
                            dialogType: DialogType.warning,
                            headerAnimationLoop: false,
                            animType: AnimType.bottomSlide,
                            title: 'Delete Team',
                            desc: 'Are you sure you want to delete ' +
                                widget.team.name,
                            buttonsTextStyle:
                                const TextStyle(color: Colors.white),
                            btnOkColor: ChanzoColors.primary,
                            btnCancelColor: ChanzoColors.secondary,
                            btnOkText: "Delete",
                            showCloseIcon: true,
                            btnCancelOnPress: () {},
                            btnOkOnPress: deleteItem,
                          ).show();
                        },
                        icon: Icon(BootstrapIcons.trash),
                        color: ChanzoColors.white,
                      ),
                      Text("Delete Team".tr,
                          style: psemibold.copyWith(
                              fontSize: 14, color: ChanzoColors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
