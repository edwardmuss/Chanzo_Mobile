import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/kiotapay_pages/fees/fee_structure_screen.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../globalclass/global_methods.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/grid_card.dart';
import '../fees/payment_controller.dart';
import '../fees/payment_methods_screen.dart';
import '../fees/payment_screen.dart';
import '../kiotapay_authentication/AuthController.dart';
import 'monthly_chart.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final themedata = Get.put(KiotaPayThemecontroler());
  final paymentController = Get.put(PaymentController(authController.selectedStudentId));
  bool _isShowBalance = false;
  String _selectedFilter = '';

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).colorScheme.onSecondaryContainer,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          "Finance".tr,
          style: pmedium.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(
              !_isShowBalance ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: _toggleBalanceVisibility,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Balance Cards Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Obx(() => Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5.0),
                      child: BalanceCard(
                        title: "Fee Balance",
                        value: formatedNumber.format(authController.feeBalance.value),
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
                        value: formatedNumber.format(authController.totalFees.value),
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
                return const Center(child: CircularProgressIndicator());
              }
              return MonthlyPaymentsChart(
                payments: paymentController.monthlyPayments,
              );
            }),

            // View All Payments Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
          ],
        ),
      ),
    );
  }
}