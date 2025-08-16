import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';
import 'package:kiotapay/kiotapay_pages/kiota_teams/details.dart';
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
import '../../kiotapay_models/teams_model.dart';
import 'package:http/http.dart' as http;

class KiotaPayTeams extends StatefulWidget {
  const KiotaPayTeams({super.key});

  @override
  State<KiotaPayTeams> createState() => _KiotaPayTeamsState();
}

class _KiotaPayTeamsState extends State<KiotaPayTeams> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Map<String, dynamic>? _userData;
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  List<Team> teams = [];
  List<Team> filteredTeams = [];
  RefreshController refreshController =
      RefreshController(initialRefresh: false);
  int page = 0;

  final teamNameController = TextEditingController();
  final teamDescriptionController = TextEditingController();
  final teamLimitController = TextEditingController();
  final teamProjectController = TextEditingController();
  final _searchController = TextEditingController();
  bool _validate = false;
  List<String> uuids = [];
  List<String> projectNames = [];
  String? selectedUuid;

  @override
  void initState() {
    super.initState();
    isLoginedIn();
    loadItems();
  }

  @override
  void dispose() {
    super.dispose();
    teamNameController.dispose();
    teamDescriptionController.dispose();
    teamLimitController.dispose();
    teamProjectController.dispose();
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
    fetchProjects();
    refreshController.refreshCompleted();
  }

  loadMoreItems() {
    page = page + 1;
    fetchItems();
  }

  isInternetConnected() async {
    bool isConnected = await checkNetwork();
    if (!isConnected) {
      showSnackBar(context, "No internet connection", Colors.red, 2.00, 2, 10);
      return;
    }
  }

  Future<Team?> fetchItems() async {
    try {
      isLoginedIn();
      var token = await getAccessToken();
      var headers = {'Authorization': 'Bearer $token'};
      var _body = jsonEncode({"page": page.toString()});
      showLoading('Loading Teams...');
      var response = await http.get(Uri.parse(KiotaPayConstants.getAllTeams),
          headers: headers);
      // print(response);
      if (response.statusCode == 200) {
        hideLoading();
        final jsonData = json.decode(response.body)['data'];

        setState(() {
          teams = jsonData
              .map<Team>((teamJson) => Team.fromJson(teamJson))
              .toList();
          filteredTeams = teams;
        });
        print("Teams are $teams");
      } else {
        hideLoading();
        print("Not 200 Res" + response.body);
      }
    } catch (exception) {
      hideLoading();
      // I get no exception here
      print("Exception $exception");
    }
    return null;
  }

  void filterTeams(String query) {
    setState(() {
      filteredTeams = teams
          .where(
              (team) => team.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> addTeamMember() async {
    isInternetConnected();
    showLoading('Adding Team Member...');
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
      'team_limit': teamLimitController.text.toInt(),
      'link_project': ''
    };
    try {
      var url = Uri.parse(KiotaPayConstants.addTeam);
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
        teamNameController.clear();
        teamDescriptionController.clear();
        teamLimitController.clear();
        teamProjectController.clear();
        loadItems();
        Navigator.of(context).pop();
        awesomeDialog(context, "Success", msg.toString(), true, DialogType.info,
            ChanzoColors.primary)
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

  Future<void> fetchProjects() async {
    isInternetConnected();
    var minutes = await getTokenExpiryMinutes();
    if (minutes < 4) {
      refreshToken();
    }
    var token = await getAccessToken();
    var headers = {
      'Authorization': 'Bearer $token',
      "Content-Type": "application/json"
    };

    try {
      var url = Uri.parse(KiotaPayConstants.getProjects);
      http.Response response = await http.get(url, headers: headers);
      // print("Response body is: " +
      //     response.body.toString() +
      //     "and Code is " +
      //     response.statusCode.toString());
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'];
        setState(() {
          uuids = [''] + data.map((item) => item['uuid'] as String).toList();
          projectNames = ['Select Project'] +
              data.map((item) => item['project_name'] as String).toList();
          selectedUuid = uuids.isNotEmpty ? uuids[0] : null;
        });
        print(data);
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
      awesomeDialog(context, "Error", error.toString(), true, DialogType.error,
          ChanzoColors.secondary)
        ..show();
      hideLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    print(_userData);

    void addTeam() => showModalBottomSheet(
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
                        SizedBox(height: 20),
                        Text(
                          'Create New Team',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Create New Team here',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
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
                        if (selectedUuid !=
                            null) // Only build the DropdownButton if selectedUuid is not null
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Project',
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: ChanzoColors.lightPrimary)),
                            ),
                            value: selectedUuid,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedUuid = newValue;
                              });
                            },
                            items: List.generate(
                              uuids.length,
                              (index) => DropdownMenuItem<String>(
                                value: uuids[index],
                                child: Text(projectNames[index]),
                              ),
                            ),
                          ),
                        SizedBox(height: 40),
                        InkWell(
                          splashColor: ChanzoColors.transparent,
                          highlightColor: ChanzoColors.transparent,
                          onTap: () async {
                            print('Team Add btn clicked');

                            if (_formKey.currentState!.validate()) {
                              addTeamMember();
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
                                  Text("Create Team".tr,
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
            });
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
                        "My Teams".tr,
                        style: pbold_hmd.copyWith(color: ChanzoColors.white),
                      ),
                      Text(
                        "We believe in the future technologies".tr,
                        style: pregular_md.copyWith(
                            color: ChanzoColors.primary80),
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
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Search by name',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 10.0),
                            ),
                            onChanged: filterTeams,
                          ),
                        ),
                        filteredTeams.isNotEmpty
                            ? ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredTeams.length,
                                itemBuilder: (context, index) {
                                  Team team = filteredTeams[index];
                                  return InkWell(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (context) {
                                          return KiotaPayTeamsDetails(
                                              team: team);
                                        },
                                      ));
                                    },
                                    child: Container(
                                      // height: 240,
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Color(0xfffed7da),
                                            Color(0xffd4e3e6)
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: ChanzoColors.primary80,
                                        ),
                                      ),
                                      // Adds a gradient background and rounded corners to the container
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    flex: 6,
                                                    child: Text(
                                                      team.name,
                                                      style: pbold_hsm.copyWith(
                                                        color: ChanzoColors
                                                            .primary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Stack(
                                                    children: [
                                                      IconButton(
                                                        onPressed: () {},
                                                        icon: Icon(
                                                            BootstrapIcons
                                                                .three_dots),
                                                        color: ChanzoColors
                                                            .white,
                                                      ),
                                                    ],
                                                  )
                                                  // Adds a stack of three dots icon to the right of the title
                                                ],
                                              ),
                                              Text(
                                                team.description,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              // Adds a subtitle to the card
                                              SizedBox(height: 10),
                                              Text(team.users.length > 1
                                                  ? team.users.length
                                                          .toString() +
                                                      " Members"
                                                  : team.users.length
                                                          .toString() +
                                                      " Member"),
                                              SizedBox(height: 10),
                                              // Row(
                                              //   mainAxisAlignment: MainAxisAlignment.center,
                                              //   children: [
                                              //     Initicon(text: "T1"),
                                              //     Initicon(text: "T2"),
                                              //   ],
                                              // ),
                                              team.teamLimit !=0 ? LinearProgressIndicator(
                                                value: (team.teamSpentAmount) /
                                                    team.teamLimit,
                                                // % progress
                                                backgroundColor:
                                                    ChanzoColors.primary80,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.green),
                                                borderRadius: BorderRadius.all(
                                                    radiusCircular()),
                                                minHeight:
                                                    7.0, // Minimum height of the line
                                              ): Text(""),
                                            ],
                                          ),
                                          // Text(
                                          //   "KES " +
                                          //       team.teamSpentAmount!.toString() +
                                          //       " of " +
                                          //       NumberFormat.compact().format(team.teamLimit!),
                                          //   style: TextStyle(fontSize: 24, color: Colors.white),
                                          // ), // Adds a price to the bottom of the card
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                separatorBuilder: (context, index) {
                                  return SizedBox(
                                    height: height / 46,
                                  );
                                },
                              )
                            : Padding(
                                padding: const EdgeInsets.only(
                                    top: 100, bottom: 100),
                                child: Center(
                                  child: Text('No results found'),
                                ),
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
                print('Add Team btn clicked');
                addTeam();
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
                      Text("Create New Team".tr,
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
  final Team team;

  const ItemTile({
    Key? key,
    required this.team,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) {
            return KiotaPayTeamsDetails(team: team);
          },
        ));
      },
      child: Container(
        // height: 240,
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xfffed7da), Color(0xffd4e3e6)],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: ChanzoColors.primary80,
          ),
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
                        team.name,
                        style: pbold_hsm.copyWith(
                          color: ChanzoColors.primary,
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
                          color: ChanzoColors.white,
                        ),
                      ],
                    )
                    // Adds a stack of three dots icon to the right of the title
                  ],
                ),
                Text(
                  team.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ), // Adds a subtitle to the card
                SizedBox(height: 10),
                Text(team.users.length > 1
                    ? team.users.length.toString() + " Members"
                    : team.users.length.toString() + " Member"),
                SizedBox(height: 10),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Initicon(text: "T1"),
                //     Initicon(text: "T2"),
                //   ],
                // ),
                LinearProgressIndicator(
                  value: (team.teamSpentAmount) / team.teamLimit,
                  // % progress
                  backgroundColor: ChanzoColors.primary80,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  borderRadius: BorderRadius.all(radiusCircular()),
                  minHeight: 7.0, // Minimum height of the line
                ),
              ],
            ),
            // Text(
            //   "KES " +
            //       team.teamSpentAmount!.toString() +
            //       " of " +
            //       NumberFormat.compact().format(team.teamLimit!),
            //   style: TextStyle(fontSize: 24, color: Colors.white),
            // ), // Adds a price to the bottom of the card
          ],
        ),
      ),
    );
  }
}
