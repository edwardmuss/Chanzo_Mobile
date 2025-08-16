import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/kiotapay_pages/fees/fee_structure_screen.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:shimmer/shimmer.dart';

import '../../globalclass/global_methods.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/grid_card.dart';
import '../fees/payment_controller.dart';
import '../fees/payment_methods_screen.dart';
import '../fees/payment_screen.dart';
import '../kiotapay_authentication/AuthController.dart';
import '../kiotapay_drawer/kiotapay_drawer.dart';
import 'monthly_chart.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final themedata = Get.put(KiotaPayThemecontroler());
  final paymentController =
      Get.put(PaymentController(authController.selectedStudentId));
  bool _isShowBalance = false;
  String _selectedFilter = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _loadShowBalancePreference();
    await authController.fetchAndCacheFeeBalance();
    await paymentController.fetchLast12MonthsPayments();
  }

  Future<void> _loadShowBalancePreference() async {
    final prefs = await SharedPreferences.getInstance();
    print("Show Balance: ${prefs.getBool("isShowBalance")}");
    setState(() {
      _isShowBalance = prefs.getBool("isShowBalance") ?? false;
    });
  }

  void _toggleBalanceVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isShowBalance = !_isShowBalance;
    });
    await prefs.setBool("isShowBalance", _isShowBalance);
  }

  Widget _buildChartShimmer(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Pick base/highlight dynamically depending on brightness
    final isDark = theme.brightness == Brightness.dark;
    final baseColor =
    isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final highlightColor =
    isDark ? Colors.grey.shade500 : Colors.grey.shade100;
    final placeholderColor =
    isDark ? colorScheme.surfaceVariant : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart Title Placeholder
            Container(
              width: 180,
              height: 20,
              color: placeholderColor,
            ),
            const SizedBox(height: 20),

            // Fake vertical bar chart
            SizedBox(
              height: 180, // chart area height
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(6, (index) {
                  final heights = [60.0, 120.0, 90.0, 150.0, 80.0, 100.0];
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6.0),
                      height: heights[index],
                      color: placeholderColor,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const KiotaPayDrawer(),
      appBar: KiotaPayAppBar(scaffoldKey: _scaffoldKey),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(children: [
                Text(
                  "Finance Dashboard".tr,
                  style: pbold_hlg.copyWith(fontSize: 18),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(
                    !_isShowBalance ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: _toggleBalanceVisibility,
                ),
              ]),
            ),
            // Balance Cards Row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Obx(() => Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: BalanceCard(
                            title: "Fee Balance",
                            value: formatedNumber
                                .format(authController.feeBalance.value),
                            backgroundColor: themedata.isdark.value
                                ? ChanzoColors.bgdark
                                : ChanzoColors.primary50,
                            showValue: _isShowBalance,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: BalanceCard(
                            title: "Total Fee",
                            value: formatedNumber
                                .format(authController.totalFees.value),
                            backgroundColor: themedata.isdark.value
                                ? ChanzoColors.bgdark
                                : ChanzoColors.lightSecondary,
                            showValue: _isShowBalance,
                          ),
                        ),
                      ),
                    ],
                  )),
            ),

            // Quick Actions Grid
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  GridCard(
                    title: 'Structure',
                    param: 'structure',
                    icon: LucideIcons.check,
                    isSelected: _selectedFilter == 'structure',
                    onTap: () {
                      setState(() => _selectedFilter = 'structure');
                      Get.to(() => const FeeStructureScreen());
                    },
                  ),
                  GridCard(
                    title: 'Pay Now',
                    param: 'pay',
                    icon: LucideIcons.coins,
                    isSelected: _selectedFilter == 'pay',
                    onTap: () {
                      setState(() => _selectedFilter = 'pay');
                      Get.to(() => const PaymentMethodsScreen());
                    },
                  ),
                ],
              ),
            ),

            // Monthly Payments Chart
            Obx(() {
              if (paymentController.isLoading.value) {
                return _buildChartShimmer(context);
              }
              return MonthlyPaymentsChart(
                  payments: paymentController.monthlyPayments.toList(),
              );
            }),

            // View All Payments Button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: ElevatedButton(
                onPressed: () {
                  Get.to(() => PaymentsScreen(
                        studentId: authController.selectedStudentId,
                      ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChanzoColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'View All Payments',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 30)
          ],
        ),
      ),
    );
  }
}
