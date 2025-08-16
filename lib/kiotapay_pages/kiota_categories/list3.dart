import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_dahsboard/kiotapay_dahsboard.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_drawer/kiotapay_drawer.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'package:nb_utils/nb_utils.dart' hide DialogType;
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import '../../globalclass/global_methods.dart';
import '../../kiotapay_models/category_model.dart';
import 'package:http/http.dart' as http;

class KiotaPayCategories2 extends StatefulWidget {
  const KiotaPayCategories2({super.key});

  @override
  State<KiotaPayCategories2> createState() => _KiotaPayCategories2State();
}

class _KiotaPayCategories2State extends State<KiotaPayCategories2> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Map<String, dynamic>? _userData;
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  List<Data>? items = [];
  RefreshController refreshController =
      RefreshController(initialRefresh: false);
  int page = 0;

  final categoryController = TextEditingController();
  final subCategoryController = TextEditingController();
  TextEditingController editcategoryController = TextEditingController();
  List<Menu> data = [];
  List dataList = [];

  @override
  void initState() {
    super.initState();
    isLoginedIn();
    loadItems();
    // dataList.forEach((element) {
    //   data.add(Menu.fromJson(element));
    // });
  }

  @override
  void dispose() {
    super.dispose();
    categoryController.dispose();
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

  void setItems(List<Data>? item) {
    items!.clear();
    items = item;
    print("SetItems $item");
    refreshController.refreshCompleted();
    setState(() {});
  }

  void setMoreItems(List<Data> item) {
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

  Future<Data?> fetchItems() async {
    try {
      isLoginedIn();
      var minutes = await getTokenExpiryMinutes();
      if (minutes < 4) {
        refreshToken();
      }
      var token = await getAccessToken();
      var headers = {'Authorization': 'Bearer $token'};
      var _body = jsonEncode({"page": page.toString()});
      showLoading('Loading Categories...');
      var response = await http
          .get(Uri.parse(KiotaPayConstants.getAllCategories), headers: headers);
      // print(response);
      if (response.statusCode == 200) {
        hideLoading();
        dynamic res = jsonDecode(response.body);
        // print("Res is ${res['data']}");
        dataList = res['data'];
        data.clear();
        dataList.forEach((element) {
          data.add(Menu.fromJson(element));
        });
        List<Data>? itemList = parseItemsList(res);
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

  static List<Data>? parseItemsList(dynamic res) {
    final parsed = res['data'].cast<Map<String, dynamic>>();
    return parsed.map<Data>((json) => Data.fromJson(json)).toList();
  }

  Future<void> _addCategory() async {
    isInternetConnected();
    isLoginedIn();
    showLoading('Adding category...');
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
      'name': categoryController.text,
    };
    try {
      var url = Uri.parse(KiotaPayConstants.addCategories);
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
        categoryController.clear();

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

  Future<void> updateCategory(String uuid) async {
    isInternetConnected();
    isLoginedIn();
    showLoading('Updating category...');
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
      'name': editcategoryController.text,
      'link_category': uuid,
    };
    try {
      var url = Uri.parse(KiotaPayConstants.updateCategories);
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
        editcategoryController.clear();

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

  Future<void> updateSubCategory(String uuid) async {
    isInternetConnected();
    isLoginedIn();
    // print("The UUID subcategory is $uuid");return;
    showLoading('Updating subcategory...');
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
      'name': editcategoryController.text,
      'link_category': uuid,
    };
    try {
      var url = Uri.parse(KiotaPayConstants.updateSubCategories);
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
        editcategoryController.clear();

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

  Future<void> addNewSubCategory(String uuid) async {
    isInternetConnected();
    isLoginedIn();
    showLoading('Adding subcategory...');
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
      'name': subCategoryController.text,
      'link_category': uuid,
    };
    try {
      var url = Uri.parse(KiotaPayConstants.addSubCategories);
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
        subCategoryController.clear();

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

  Future<void> deleteCategory(String uuid) async {
    isInternetConnected();
    isLoginedIn();
    showLoading('Sending request...');
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
      'link_category': uuid,
    };
    try {
      var url = Uri.parse(KiotaPayConstants.deleteCategories);
      http.Response response =
      await http.delete(url, body: jsonEncode(body), headers: headers);
      print("Response body is: " +
          response.body.toString() +
          "and Code is " +
          response.statusCode.toString());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        var msg = jsonDecode(response.body)['msg'];
        hideLoading();
        subCategoryController.clear();

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
    print("The dataList is $dataList");

    void addCategory() => showModalBottomSheet(
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
                        'Create New Categories',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'What would you like to do today',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: ChanzoColors.textgrey,
                            fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 30),
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Category Name is required';
                          }
                          return null;
                        },
                        controller: categoryController,
                        decoration: InputDecoration(
                          labelText: 'Category Name',
                          border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: ChanzoColors.lightPrimary)),
                        ),
                        // minLines: 3,
                        keyboardType: TextInputType.name,
                        maxLines: null,
                      ),
                      SizedBox(height: 15),
                      SizedBox(height: 15),
                      InkWell(
                        splashColor: ChanzoColors.transparent,
                        highlightColor: ChanzoColors.transparent,
                        onTap: () async {
                          print('Category Add btn clicked');

                          if (_formKey.currentState!.validate()) {
                            _addCategory();
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
                                Text("Save Category".tr,
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

    void addsubCategory(
            String uuid, String categoryName, String? link_category) =>
        showModalBottomSheet(
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
                        'Subcategory',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Add subcategory in $categoryName',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: ChanzoColors.textgrey,
                            fontWeight: FontWeight.w300),
                      ),
                      Text(
                        "UUID:$uuid | Link_Category: $link_category",
                      ),
                      SizedBox(height: 30),
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Subcategory Name is required';
                          }
                          return null;
                        },
                        controller: subCategoryController,
                        decoration: InputDecoration(
                          labelText: 'Subcategory Name',
                          border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: ChanzoColors.lightPrimary)),
                        ),
                        // minLines: 3,
                        keyboardType: TextInputType.name,
                        maxLines: null,
                      ),
                      SizedBox(height: 15),
                      SizedBox(height: 15),
                      InkWell(
                        splashColor: ChanzoColors.transparent,
                        highlightColor: ChanzoColors.transparent,
                        onTap: () async {
                          if (_formKey.currentState!.validate()) {
                            addNewSubCategory(uuid);
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
                                Text("Add Subcategory".tr,
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

    void editCategory(
            String CategoryName, String uuid, String? link_category) =>
        showModalBottomSheet(
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
                      SizedBox(height: 25),
                      Text(
                        'Update',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'What would you like to do today',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: ChanzoColors.textgrey,
                            fontWeight: FontWeight.w300),
                      ),
                      Text(
                        "UUID:$uuid | Category Name: $CategoryName | Link_Category: $link_category",
                      ),
                      // SizedBox(height: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          link_category == null
                              ? TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    addsubCategory(
                                        uuid, CategoryName, link_category);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: ChanzoColors.primary,
                                    minimumSize: Size.zero, // Set this
                                    padding: EdgeInsets.zero, // and this
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          addsubCategory(uuid, CategoryName,
                                              link_category);
                                        },
                                        padding:
                                            EdgeInsets.only(left: 0, right: 5),
                                        constraints: const BoxConstraints(),
                                        // override default min size of 48px
                                        style: const ButtonStyle(
                                          tapTargetSize: MaterialTapTargetSize
                                              .shrinkWrap, // the '2023' part
                                        ),
                                        icon: Icon(
                                          BootstrapIcons.plus_circle,
                                        ),
                                        color: ChanzoColors.primary,
                                      ),
                                      Text(
                                        'Add Subcategory',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                )
                              : SizedBox(),
                          TextButton(
                            onPressed: () {
                              deleteCategory(uuid);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: ChanzoColors.secondary,
                              minimumSize: Size.zero, // Set this
                              padding: EdgeInsets.zero, // and this
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                IconButton(
                                  onPressed: () { deleteCategory(uuid);},
                                  padding: EdgeInsets.only(left: 10, right: 5),
                                  constraints: const BoxConstraints(),
                                  // override default min size of 48px
                                  style: const ButtonStyle(
                                    tapTargetSize: MaterialTapTargetSize
                                        .shrinkWrap, // the '2023' part
                                  ),
                                  icon: Icon(BootstrapIcons.trash),
                                  color: ChanzoColors.secondary,
                                ),
                                Text(
                                  'Delete',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                        controller: editcategoryController =
                            TextEditingController(text: CategoryName),
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: ChanzoColors.lightPrimary)),
                        ),
                        // minLines: 3,
                        keyboardType: TextInputType.name,
                        maxLines: null,
                      ),
                      SizedBox(height: 15),
                      SizedBox(height: 15),
                      InkWell(
                        splashColor: ChanzoColors.transparent,
                        highlightColor: ChanzoColors.transparent,
                        onTap: () async {
                          if (_formKey.currentState!.validate()) {
                            if(link_category == null){
                              updateCategory(uuid);
                            }else{
                              updateSubCategory(uuid);
                            }

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
                                Text("Update".tr,
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

    Widget _buildList(Menu list) {
      // print("List is ${list.categoryName}");
      if (list.subCategories.isEmpty)
        return Builder(builder: (context) {
          return Card(
            elevation: 0,
            color: Colors.transparent,
            shape: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              onTap: () {
                editCategory(
                    list.categoryName!, list.uuid!, list.link_category);
                // if (list.subCategories.single == '') {
                //   Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //           builder: (context) => SubCategory(list.categoryName)));
                // }
              },
              leading: Icon(Icons.payment),
              title: Text(
                list.categoryName ?? '',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          );
        });
      return Builder(
        builder: (context) {
          return ExpansionTile(
            leading: Icon(Icons.star),
            title: InkWell(
              onTap: () => {
                editCategory(list.categoryName!, list.uuid!, list.link_category)
              },
              child: Text(
                list.categoryName!,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
            children: list.subCategories.map(_buildList).toList(),
          );
        },
      );
    }

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
                SizedBox(height: MediaQuery.of(context).size.height / 10),
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
                        "Expense Categories".tr,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(color: ChanzoColors.white),
                      ),
                      Text(
                        "Manage how you spend by grouping similar transaction"
                            .tr,
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
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.length,
                      itemBuilder: (BuildContext context, int index) =>
                          _buildList(data[index]),
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
                print('Add category btn clicked');
                addCategory();
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
                      Text("Create New Category".tr,
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

class Menu {
  String? categoryName;
  String? subCategoryName;
  String? uuid;
  String? link_category;

  // IconData? icon;
  List<Menu> subCategories = [];

  Menu(
      {required this.categoryName,
      required this.subCategories,
      this.subCategoryName,
      this.uuid,
      this.link_category});

  Menu.fromJson(Map<String, dynamic> json) {
    categoryName = json['categoryName'];
    link_category = json['link_category'];
    uuid = json['uuid'];
    // icon = json['icon'];
    if (json['subCategories'] != null) {
      subCategories.clear();
      json['subCategories'].forEach((v) {
        v['categoryName'] = v['subCategoryName'];
        subCategoryName = v['subCategoryName'];
        subCategories.add(new Menu.fromJson(v));
      });
    }
  }
}

class SubCategory extends StatelessWidget {
  String? name;

  SubCategory(this.name, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(name ?? ""),
        ),
        body: Center(
          child: Text("This is $name category screen"),
        ));
  }
}
