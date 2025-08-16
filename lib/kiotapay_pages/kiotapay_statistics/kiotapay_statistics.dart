import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:kiotapay/globalclass/global_methods.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../globalclass/kiotapay_constants.dart';

class BankPickStatistics extends StatefulWidget {
  const BankPickStatistics({super.key});

  @override
  State<BankPickStatistics> createState() => _BankPickStatisticsState();
}

class _BankPickStatisticsState extends State<BankPickStatistics> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());
  double _orgBalance = 0.00;
  double _memberBalance = 0.00;
  bool _isShowBalance = false;
  bool isLoading = false;
  List<dynamic> recentTransactions = [];
  List<dynamic> data = [];
  List<Map<String, dynamic>> dailySummations = [];

  @override
  void initState() {
    super.initState();
    getIsShowBalance();
    getUserWallet();
    getOrgBalance();
    getRecentTransactions();
  }

  List month = [
    "Oct",
    "Nov",
    "Dec",
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep"
  ];
  int selected = 0;

  List img = [
    KiotaPayPngimage.transaction,
    KiotaPayPngimage.transaction1,
    KiotaPayPngimage.transaction2,
    KiotaPayPngimage.transaction3,
    KiotaPayPngimage.transaction4
  ];
  List title = [
    "Apple Store",
    "Spotify",
    "Money Transfer",
    "Grocery",
    "Apple Store"
  ];
  List subtitle = [
    "Entertainment",
    "Music",
    "Transaction",
    "Shopping",
    "Entertainment"
  ];
  List price = [
    "- \Ksh 5,99",
    "- \Ksh 12,99",
    "\Ksh 300",
    "- \Ksh 88",
    "- \Ksh 5,99"
  ];

  Future<void> getIsShowBalance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isShowBalance = prefs.getBool("isShowBalance") ?? false;
    setState(
      () {
        _isShowBalance = isShowBalance;
      },
    );
  }

  Future<void> getRecentTransactions() async {
    setState(() {
      isLoading = true;
    });
    try {
      var minutes = await getTokenExpiryMinutes();
      if (minutes < 4) {
        refreshToken();
      }
      var token = await getAccessToken();
      var body = {"type": ""};
      var headers = {
        'Authorization': 'Bearer $token',
        "Content-Type": "application/json"
      };
      var response = await http.post(
          Uri.parse(KiotaPayConstants.getAllCurrentUserTransactions),
          headers: headers,
          body: jsonEncode(body));
      if (response.statusCode == 200 || response.statusCode == 201) {
        hideLoading();
        setState(() {
          // Parse JSON
          Map<String, dynamic> jsonData = jsonDecode(response.body);
          // Access the 'data' array
          recentTransactions = jsonData['data'];
          data = jsonData['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print("Not 200 Res" + response.body);
      }
    } catch (exception) {
      // setState(() {
      //   isLoading = false;
      // });
      print("Exception $exception");
    }
  }

  List<Map<String, dynamic>> getDailySummations() {
    // Filter data for the last 7 days
    DateTime now = DateTime.now();
    DateTime sevenDaysAgo = now.subtract(Duration(days: 6));
    List<Map<String, dynamic>> dailySummations = [];
    for (int i = 0; i < 7; i++) {
      DateTime currentDate = sevenDaysAgo.add(Duration(days: i));
      String formattedDate = DateFormat('EEE').format(currentDate); // Format to full weekday name
      // Sum the amounts for the current date
      double totalAmount = data
          .where((item) => item['created_at'].substring(0, 10) == DateFormat('yyyy-MM-dd').format(currentDate))
          .map((item) => double.parse(item['amount']))
          .fold(0, (prev, amount) => prev + amount);
      dailySummations.add({
        'date': formattedDate,
        'totalAmount': totalAmount,
      });
    }
    return dailySummations;
  }

  Map<String, double> getWeekdayTotalAmounts() {
    Map<String, double> weekdayTotalAmounts = {
      'Sun': 0.0,
      'Mon': 0.0,
      'Tue': 0.0,
      'Wed': 0.0,
      'Thu': 0.0,
      'Fri': 0.0,
      'Sat': 0.0,
    };

    dailySummations.forEach((entry) {
      DateTime date = DateTime.parse(entry['date']);
      String weekday = DateFormat('E').format(date);
      weekdayTotalAmounts[weekday] = (weekdayTotalAmounts[weekday] ?? 0) +
          (entry['totalAmount'] as double? ?? 0);
    });

    return weekdayTotalAmounts;
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

  Future<void> getUserWallet() async {
    try {
      var minutes = await getTokenExpiryMinutes();
      if (minutes < 4) {
        refreshToken();
      }
      var token = await getAccessToken();
      var headers = {'Authorization': 'Bearer $token'};
      var response = await http.get(Uri.parse(KiotaPayConstants.userWallet),
          headers: headers);
      if (response.statusCode == 200) {
        hideLoading();
        dynamic res = jsonDecode(response.body);
        print(res['toSpendAmount']);
        setState(() {
          _memberBalance = res['toSpendAmount'].toDouble();
        });
      } else {
        print("Not 200 Res" + response.body);
      }
    } catch (exception) {
      print("Exception $exception");
    }
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    List<Map<String, dynamic>> dailySummations = getDailySummations();
    Map<String, double> weekdayTotalAmounts = getWeekdayTotalAmounts();
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).colorScheme.onSecondaryContainer,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          "Analytics".tr,
          style: pmedium.copyWith(
            fontSize: 18,
          ),
        ),
        actions: [
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: width / 36),
          //   child: CircleAvatar(
          //     radius: 22,
          //     backgroundColor:
          //         Theme.of(context).colorScheme.secondaryContainer,
          //     child: Image.asset(
          //       KiotaPayPngimage.notification,
          //       height: height / 36,
          //       color: themedata.isdark
          //           ? ChanzoColors.white
          //           : ChanzoColors.black,
          //     ),
          //   ),
          // )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: themedata.isdark == false
                    ? ChanzoColors.primary50
                    : ChanzoColors.bgdark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      height: 30,
                    ),
                    Text(
                      "Business Balance".tr,
                      style: pregular.copyWith(
                          fontSize: 18, color: ChanzoColors.primary),
                    ),
                    Text(
                      !_isShowBalance
                          ? KiotaPayConstants.currency +
                          " " +
                          decimalformatedNumber.format(_orgBalance).toString()
                          : "********",
                      style: pmedium.copyWith(
                        fontSize: 26,
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
            child: Container(
              decoration: BoxDecoration(
                color: themedata.isdark == false
                    ? ChanzoColors.lightSecondary
                    : ChanzoColors.bgdark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      height: 30,
                    ),
                    Text(
                      "Wallet Balance".tr,
                      style: pregular.copyWith(
                          fontSize: 18, color: ChanzoColors.primary),
                    ),
                    Text(
                      !_isShowBalance
                          ? KiotaPayConstants.currency +
                          " " +
                          decimalformatedNumber.format(_memberBalance).toString()
                          : "********",
                      style: pmedium.copyWith(
                        fontSize: 26,
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: height / 56,
          ),
          Expanded(
            child: BarChart(
              BarChartData(
                // maxY: 30,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text("Last 7 Days"),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (double value, meta) {
                        String text = '';
                        switch (value.toInt()) {
                          case 0:
                            text = dailySummations[value.toInt()]['date'];;
                          case 1:
                            text = dailySummations[value.toInt()]['date'];;
                          case 2:
                            text = dailySummations[value.toInt()]['date'];;
                          case 3:
                            text = dailySummations[value.toInt()]['date'];;
                          case 4:
                            text = dailySummations[value.toInt()]['date'];;
                          case 5:
                            text = dailySummations[value.toInt()]['date'];;
                          case 6:
                            text = dailySummations[value.toInt()]['date'];;
                          default:
                            text = '';
                        }
                        return Text(text);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text("Amount (KES)"),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    axisNameWidget: Text(""),
                    sideTitles: SideTitles(
                      showTitles: false,
                      reservedSize: 60,
                    ),
                  ),
                  topTitles: AxisTitles(
                    axisNameWidget: Text("Transaction Last 7 days"),
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: dailySummations.map((data) {
                  print("$data");
                  // Assign numeric values to weekdays
                  int x = dailySummations.indexOf(data);
                  return BarChartGroupData(
                    x: x, // Weekday name
                    barRods: [
                      BarChartRodData(
                        fromY: 0,
                        toY: data['totalAmount'], // Total amount
                        color: Colors.blue, // Color of the bar
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          SizedBox(
            height: height / 10,
          ),
        ],
      ),
    );
  }
}
