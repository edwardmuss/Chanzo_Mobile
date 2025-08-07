import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_drawer/kiotapay_drawer.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'package:nb_utils/nb_utils.dart' hide DialogType;
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import '../../globalclass/global_methods.dart';
import '../../kiotapay_models/projects_model.dart';
import 'package:http/http.dart' as http;

import 'list.dart';

class KiotaPayProjectsDetails extends StatefulWidget {
  const KiotaPayProjectsDetails(
      {super.key, required this.data, required this.index});

  final Project data;
  final int index;

  @override
  State<KiotaPayProjectsDetails> createState() =>
      _KiotaPayProjectsDetailsState();
}

class _KiotaPayProjectsDetailsState extends State<KiotaPayProjectsDetails> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Map<String, dynamic>? _userData;
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  List<Project>? items = [];
  RefreshController refreshController =
      RefreshController(initialRefresh: false);
  int page = 0;

  late final nameController =
      TextEditingController(text: widget.data.projectName);
  late final descriptionController =
      TextEditingController(text: widget.data.description);
  late final estAmountController =
      TextEditingController(text: widget.data.projectEstAmount.toString());

  late String statusController;

  bool _validate = false;

  @override
  void initState() {
    super.initState();
    isLoginedIn();
    loadItems();
    setState(() {
      statusController = widget.data.status.toString();
    });
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    descriptionController.dispose();
    estAmountController.dispose();
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
  }

  loadMoreItems() {
    page = page + 1;
    fetchItems();
  }

  void setItems(List<Project>? item) {
    items!.clear();
    items = item;
    print("SetItems $item");
    refreshController.refreshCompleted();
    setState(() {});
  }

  void setMoreItems(List<Project> item) {
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

  Future<Project?> fetchItems() async {
    try {
      var minutes = await getTokenExpiryMinutes();
      if (minutes < 4) {
        refreshToken();
      }
      var token = await getAccessToken();
      var headers = {'Authorization': 'Bearer $token'};
      var _body = jsonEncode({"page": page.toString()});
      showLoading('Loading...');
      var response = await http.get(Uri.parse(KiotaPayConstants.getAllTeams),
          headers: headers);
      // print(response);
      if (response.statusCode == 200) {
        hideLoading();
        dynamic res = jsonDecode(response.body);
        // print(res);

        List<Project>? itemList = parseItemsList(res);
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

  static List<Project>? parseItemsList(dynamic res) {
    final parsed = res['data'].cast<Map<String, dynamic>>();
    return parsed.map<Project>((json) => Project.fromJson(json)).toList();
  }

  Future<void> _editItem() async {
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
      'project_name': nameController.text,
      'description': descriptionController.text,
      'estimated_amount': estAmountController.text.toInt(),
      'link_project': widget.data.uuid!
    };
    try {
      var url = Uri.parse(KiotaPayConstants.updateProject);
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
        nameController.clear();
        descriptionController.clear();
        estAmountController.clear();

        awesomeDialog(context, "Success", msg.toString(), true, DialogType.info,
            ChanzoColors.secondary)
          ..show();
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
          Get.to(() => KiotaPayProjects());
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

  Future<void> _updateStatus() async {
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
    var body = {'status': statusController, 'link_project': widget.data.uuid!};
    try {
      var url = Uri.parse(KiotaPayConstants.updateStatusProject);
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
        // statusController = '';

        awesomeDialog(context, "Success", msg.toString(), true, DialogType.info,
            ChanzoColors.secondary)
          ..show();
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.of(context).pop();
          Get.back();
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

  Future<void> deleteItem() async {
    isInternetConnected();
    showLoading('Deleting...');
    var minutes = await getTokenExpiryMinutes();
    if (minutes < 4) {
      refreshToken();
    }
    var token = await getAccessToken();
    var headers = {
      'Authorization': 'Bearer $token',
      "Content-Type": "application/json"
    };
    var body = {'link_project': widget.data.uuid!};
    try {
      var url = Uri.parse(KiotaPayConstants.deleteProject);
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
            ChanzoColors.secondary)
          ..show();
        Future.delayed(const Duration(seconds: 3), () {
          Get.back();
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

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    void editItem() => showModalBottomSheet(
          isScrollControlled: true,
          clipBehavior: Clip.antiAlias,
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
                        'Edit Project',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Update project details',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: ChanzoColors.textgrey,
                            fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'project name is required';
                          }
                          return null;
                        },
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Project Name',
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
                        controller: descriptionController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Project description is required';
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
                        controller: estAmountController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Project Est Amount is required';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Estimated Amount',
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
                          print('Edit btn clicked');

                          if (_formKey.currentState!.validate()) {
                            isLoginedIn();
                            _editItem();
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
                                  "Update Project".tr,
                                  style: psemibold.copyWith(
                                      fontSize: 14,
                                      color: ChanzoColors.white),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _editItem();
                                  },
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

    void updateStatus() => showModalBottomSheet(
          isScrollControlled: true,
          // set this when inner content overflows, making RoundedRectangleBorder not working as expected
          clipBehavior: Clip.antiAlias,
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
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
                            'Update project status',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall!
                                .copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 20),
                          new ListTile(
                            title: const Text('Status'),
                            trailing: new DropdownButton<String>(
                                hint: Text('Choose'),
                                onChanged: (String? changedValue) {
                                  setState(() {
                                    this.statusController = changedValue!;
                                    print(statusController);
                                  });
                                },
                                value: statusController,
                                items: <String>[
                                  'ONGOING',
                                  'SUSPENDED',
                                  'COMPLETED',
                                ].map((String value) {
                                  return new DropdownMenuItem<String>(
                                    value: value,
                                    child: new Text(value),
                                  );
                                }).toList()),
                          ),
                          SizedBox(height: 20),
                          InkWell(
                            splashColor: ChanzoColors.transparent,
                            highlightColor: ChanzoColors.transparent,
                            onTap: () async {
                              if (_formKey.currentState!.validate()) {
                                isLoginedIn();
                                _updateStatus();
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
                                      "Update Status".tr,
                                      style: psemibold.copyWith(
                                          fontSize: 14,
                                          color: ChanzoColors.white),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        isLoginedIn();
                                        _updateStatus();
                                      },
                                      icon: Icon(
                                          BootstrapIcons.arrow_right_circle),
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
                        widget.data.projectName!,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(color: ChanzoColors.white),
                      ),
                      Text(
                        widget.data.description!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: ChanzoColors.primary80),
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
                                  "Project Amount",
                                ),
                                // Adds a subtitle to the card
                                SizedBox(height: 10),
                                Text(
                                  "KES " +
                                      decimalformatedNumber
                                          .format(widget.data.projectAmount!)
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
                                    print('status btn clicked');
                                    updateStatus();
                                  },
                                  child: Container(
                                    height: height / 15,
                                    width: width / 1.2,
                                    decoration: BoxDecoration(
                                        color: ChanzoColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(50)),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            onPressed: () {},
                                            icon: Icon(BootstrapIcons.wallet),
                                            color: ChanzoColors.white,
                                          ),
                                          Text("Change Status".tr,
                                              style: psemibold.copyWith(
                                                  fontSize: 14,
                                                  color: ChanzoColors.white)),
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
                        ListTile(
                          title: const Text('Status'),
                          trailing: new DropdownButton<String>(
                              hint: Text('Choose'),
                              onChanged: (String? changedValue) {
                                setState(() {
                                  this.statusController = changedValue!;
                                  print(statusController);
                                });
                                isLoginedIn();
                                _updateStatus();
                              },
                              value: statusController,
                              items: <String>[
                                'ONGOING',
                                'SUSPENDED',
                                'COMPLETED',
                              ].map((String value) {
                                return new DropdownMenuItem<String>(
                                  value: value,
                                  child: new Text(value),
                                );
                              }).toList()),
                        ),
                        Text(
                          "Teams",
                          style: pbold.copyWith(fontSize: 18),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.data.teams!.map((item) {
                            return item != null
                                ? ListTile(
                                    leading: Icon(Icons.people),
                                    title: Text('${item.name}'),
                                    trailing: Icon(Icons.arrow_right),
                                  )
                                : Text('No teams assigned to this project');
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                )
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
                print('Edit btn clicked');
                editItem();
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
                          editItem();
                        },
                        icon: Icon(BootstrapIcons.pen),
                        color: ChanzoColors.white,
                      ),
                      Text("Edit".tr,
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
                print('Delete btn clicked');
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.warning,
                  headerAnimationLoop: false,
                  animType: AnimType.bottomSlide,
                  title: 'Delete Project',
                  desc: 'Are you sure you want to delete ' +
                      widget.data.projectName!,
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
                            title: 'Delete Project',
                            desc: 'Are you sure you want to delete ' +
                                widget.data.projectName!,
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
                        icon: Icon(BootstrapIcons.plus_circle),
                        color: ChanzoColors.white,
                      ),
                      Text("Delete".tr,
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
