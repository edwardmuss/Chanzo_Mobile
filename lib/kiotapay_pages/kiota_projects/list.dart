import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';
import 'package:kiotapay/kiotapay_pages/kiota_projects/details.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_dahsboard/kiotapay_dahsboard.dart';
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
import '../../kiotapay_models/projects_model.dart';
import 'package:http/http.dart' as http;

class KiotaPayProjects extends StatefulWidget {
  const KiotaPayProjects({super.key});

  @override
  State<KiotaPayProjects> createState() => _KiotaPayProjectsState();
}

class _KiotaPayProjectsState extends State<KiotaPayProjects> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Map<String, dynamic>? _userData;
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  List<Project>? items = [];
  List<Teams>? teams = [];
  RefreshController refreshController =
      RefreshController(initialRefresh: false);
  int page = 0;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final estAmountController = TextEditingController();
  bool _validate = false;

  @override
  void initState() {
    super.initState();
    isLoginedIn();
    loadItems();
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    descriptionController.dispose();
    amountController.dispose();
    estAmountController.dispose();
  }

  void _onRefresh() async {
    loadItems();
  }

  void _onLoading() async {
    loadItems();
    // loadMoreItems();
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
  void setTeams(List<Teams>? teamItem) {
    teams!.clear();
    teams = teamItem;
    refreshController.refreshCompleted();
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
      showLoading('Loading Projects...');
      var response = await http.get(Uri.parse(KiotaPayConstants.getProjects),
          headers: headers);
      // print(response);
      if (response.statusCode == 200) {
        hideLoading();
        dynamic res = jsonDecode(response.body);
        print(res['data']);

        List<Project>? itemList = parseItemsList(res);
        setItems(itemList);

        List<Teams>? teamList = parseTeamList(res);
        setTeams(teamList);
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

  static List<Teams>? parseTeamList(dynamic res) {
    final parsed = res['data']['teams'].cast<Map<String, dynamic>>();
    return parsed.map<Teams>((json) => Teams.fromJson(json)).toList();
  }

  Future<void> _addItem() async {
    isInternetConnected();
    showLoading('Submitting Request...');
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
      'name': nameController.text,
      'description': descriptionController.text,
      'project_amount': amountController.text.toInt(),
      'estimated_amount': estAmountController.text.toInt()
    };
    try {
      var url = Uri.parse(KiotaPayConstants.addProject);
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
        nameController.clear();
        descriptionController.clear();
        amountController.clear();
        estAmountController.clear();
        loadItems();
        Navigator.of(context).pop();
        awesomeDialog(context, "Success", msg.toString(), true, DialogType.info,
            ChanzoColors.secondary)
          ..show();
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
    print(_userData);

    void addItem() => showModalBottomSheet(
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
                        'Create New Project',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Create New project here',
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
                        controller: amountController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Project Amount is required';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Project Amount',
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
                          print('Add btn clicked');

                          if (_formKey.currentState!.validate()) {
                            _addItem();
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
                                  icon: Icon(BootstrapIcons.plus_circle),
                                  color: ChanzoColors.white,
                                ),
                                Text("Create Project".tr,
                                    style: psemibold.copyWith(
                                        fontSize: 14,
                                        color: ChanzoColors.white)),
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

    return Scaffold(
      drawer: const KiotaPayDrawer(),
      body: SmartRefresher(
        controller: refreshController,
        enablePullDown: true,
        // enablePullUp: true,
        header: WaterDropHeader(),
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        footer: CustomFooter(
          builder: (BuildContext context, LoadStatus? mode) {
            Widget body;
            if (mode == LoadStatus.idle) {
              body = Text("Pull up to load more");
            } else if (mode == LoadStatus.loading) {
              body = Text("");
            } else if (mode == LoadStatus.failed) {
              body = Text("Failed, Retry");
            } else if (mode == LoadStatus.canLoading) {
              body = Text("Release Load More");
            } else {
              body = Text("No More data");
            }
            return Container(
              height: 55.0,
              child: Center(child: body),
            );
          },
        ),
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
                                  Get.off(() => KiotaPayDashboard('0'));
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
                                  Get.off(() => KiotaPayDashboard('0'));
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
                        "My Projects".tr,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(color: ChanzoColors.white),
                      ),
                      Text(
                        "We believe in the future technologies".tr,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: ChanzoColors.primary80),
                      ),
                      SizedBox(height: height / 15),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: themedata.isdark == false
                        ? ChanzoColors.bgcolor
                        : ChanzoColors.bgdark,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return ItemTile(
                          data: items![index], index: index,
                        );
                      },
                      separatorBuilder: (context, index) {
                        return SizedBox(
                          height: height / 46,
                        );
                      },
                      itemCount: items!.length,
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
                print('Add Team btn clicked');
                addItem();
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
                        icon: Icon(BootstrapIcons.plus_circle),
                        color: ChanzoColors.white,
                      ),
                      Text("Create New Project".tr,
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

class ItemTile extends StatelessWidget {
  final Project data;
  final Teams? teams;
  final int index;

  const ItemTile({
    Key? key,
    required this.data, this.teams, required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) {
            return KiotaPayProjectsDetails(data: data, index: index);
          },
        ));
      },
      child: Container(
        height: 240,
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade100,
              Colors.green.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green)
        ),
        // Adds a gradient background and rounded corners to the container
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Text(
                        data.projectName!,
                        style:
                            Theme.of(context).textTheme.headlineSmall!.copyWith(
                                  color: ChanzoColors.primary,
                                  fontSize: 18,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: Icon(BootstrapIcons.three_dots),
                          color: ChanzoColors.primary,
                        ),
                      ],
                    )
                    // Adds a stack of three dots icon to the right of the title
                  ],
                ),
                Text(
                  data.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ), // Adds a subtitle to the card
                SizedBox(height: 10),
                Text(
                  data.teams!.length > 1
                      ? data.teams!.length.toString() + " Teams"
                      : data.teams!.length.toString() + " Team",
                ),
                SizedBox(height: 10),
                RoundedBackgroundText(
                  '${data.status}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ChanzoColors.white),
                  backgroundColor: ChanzoColors.primary,
                ),
              ],
            ),
            Text("KES " + data.projectAmount!.toString(),
                style: TextStyle(
                    fontSize: 24,
                    color:
                    ChanzoColors.primary)) // Adds a price to the bottom of the card
          ],
        ),
      ),
    );
  }
}
