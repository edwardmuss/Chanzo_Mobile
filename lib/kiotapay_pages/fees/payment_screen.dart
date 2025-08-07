import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../globalclass/chanzo_color.dart';
import '../../kiotapay_theme/kiotapay_themecontroller.dart';
import '../../models/payment_model.dart';
import 'payment_controller.dart';
import 'payment_details_screen.dart';

class PaymentsScreen extends StatefulWidget {
  final int studentId;

  const PaymentsScreen({Key? key, required this.studentId}) : super(key: key);

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final RxString _selectedRange = 'all'.obs;
  late PaymentController _paymentController;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _paymentController = PaymentController(widget.studentId);

    // Check initial state
    _initConnectivity();

    // Start listening for connectivity changes (multi-network support)
    _startConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();

      final online = connectivityResults.any((r) => r != ConnectivityResult.none);

      print("Initial active connections: $connectivityResults");
      _paymentController.isOnline.value = online;
    } catch (e) {
      print("Failed to check initial connectivity: $e");
      _paymentController.isOnline.value = false;
    }
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((results) {
      // For multi-network: results is List<ConnectivityResult>
      final activeConnections = results
          .where((r) => r != ConnectivityResult.none)
          .toList();

      final online = activeConnections.isNotEmpty;
      _paymentController.isOnline.value = online;

      print("Connectivity changed: $activeConnections, online = $online");

      // Log each active connection type
      for (var connection in activeConnections) {
        switch (connection) {
          case ConnectivityResult.wifi:
            print("Connected to Wi-Fi");
            break;
          case ConnectivityResult.mobile:
            print("Connected to Mobile Data");
            break;
          case ConnectivityResult.ethernet:
            print("Connected to Ethernet");
            break;
          case ConnectivityResult.vpn:
            print("Connected through VPN");
            break;
          default:
            print("Unknown connection: $connection");
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => _searchQuery.value.isEmpty
            ? Text('Recent Payments')
            : TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search payments...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: TextStyle(color: Colors.white),
          autofocus: true,
          onChanged: (value) => _searchQuery.value = value.toLowerCase(),
        )),
        actions: [
          IconButton(
            icon: Obx(() => _searchQuery.value.isEmpty
                ? Icon(Icons.search)
                : Icon(Icons.close)),
            onPressed: _handleSearchAction,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _selectedRange.value = 'all'; // Reset filter to 'All'
              _paymentController.fetchPayments(refresh: true, range: 'all');
            },
          ),
        ],
      ),
      body: GetBuilder<PaymentController>(
        init: _paymentController,
        builder: (controller) {
          // Show loading only during initial load
          if (controller.isLoading.value && controller.payments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error if no data
          if (controller.errorMessage.value.isNotEmpty && controller.payments.isEmpty) {
            return _buildErrorState(controller);
          }

          // Show loading while refreshing
          if (controller.isRefreshing.value) {
            return const Center(child: CircularProgressIndicator());
          }

          // Avoid showing empty state while refreshing
          if (!controller.isLoading.value &&
              !controller.isRefreshing.value &&
              controller.payments.isEmpty) {
            return _buildEmptyState(controller);
          }

          // Show actual content
          return Column(
            children: [
              _buildOfflineBanner(controller),
          SizedBox(height: 20),
          _buildFilterChips(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => controller.refreshPayments(),
                  child: _buildPaymentList(controller),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  Widget _buildFilterChips() {
    final filters = {
      'all': 'All',
      '7_days': '7 Days',
      'last_month': 'Last Month',
      'last_year': 'Last Year',
    };

    return SizedBox(
      height: 40, // Adjust height as needed
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: filters.entries.map((entry) {
            return Obx(() => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child:ChoiceChip(
                label: Text(entry.value),
                selected: _selectedRange.value == entry.key,
                selectedColor: ChanzoColors.primary,
                labelStyle: TextStyle(
                  color: _selectedRange.value == entry.key ? Colors.white : Colors.black,
                ),
                avatar: _selectedRange.value == entry.key
                    ? Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
                onSelected: (_) {
                  _selectedRange.value = entry.key;
                  _paymentController.fetchPayments(refresh: true, range: entry.key);
                },
              ),
            ));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadMoreSection(PaymentController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: controller.isLoading.value
            ? CircularProgressIndicator()
            : ElevatedButton(
          onPressed: () => controller.fetchPayments(),
          child: Text('Load More'),
        ),
      ),
    );
  }

  List<Payment> _getFilteredPayments(PaymentController controller) {
    return _searchQuery.value.isEmpty
        ? controller.payments
        : controller.payments.where((payment) {
      return payment.transId.toLowerCase().contains(_searchQuery.value) ||
          payment.method.toLowerCase().contains(_searchQuery.value) ||
          payment.amount.toString().contains(_searchQuery.value) ||
          DateFormat('dd MMM yyyy, hh:mm a')
              .format(payment.paymentDate)
              .toLowerCase()
              .contains(_searchQuery.value);
    }).toList();
  }

  void _handleSearchAction() {
    if (_searchQuery.value.isNotEmpty) {
      _searchController.clear();
      _searchQuery.value = '';
    } else {
      showSearch(
        context: context,
        delegate: PaymentSearchDelegate(_paymentController),
      );
    }
  }

  Future<void> _handleRefresh() async {
    try {
      await _paymentController.refreshPayments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refresh failed: ${e.toString()}')),
      );
    }
  }

  Widget _buildOfflineBanner(PaymentController controller) {
    return Obx(() => !controller.isOnline.value
        ? Container(
      padding: EdgeInsets.all(8),
      color: Colors.amber,
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 16),
          SizedBox(width: 8),
          Text('Offline Mode - Showing cached data'),
        ],
      ),
    )
        : SizedBox.shrink());
  }

  Widget _buildPaymentItem(Payment payment, PaymentController controller) {
    return InkWell(
      onTap: () => Get.to(() => PaymentDetailsScreen(
        payment: payment,
        isOnline: controller.isOnline.value,
      )),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'TXN: ${payment.transId}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    label: Text(
                      payment.method.toUpperCase(),
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: ChanzoColors.primary,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Amount: ${NumberFormat.currency(locale: 'en_US', symbol: 'KES').format(payment.amount)}',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(payment.paymentDate)}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 4),
              Text(
                'Type: ${payment.paymentType}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              if (!controller.isOnline.value) _buildCachedIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentList(PaymentController controller) {
    final filteredPayments = _getFilteredPayments(controller);

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        // Auto-load when scrolled near bottom
        if (scrollNotification.metrics.pixels >=
            scrollNotification.metrics.maxScrollExtent - 200 &&
            !controller.isLoading.value &&
            controller.hasMore.value &&
            _searchQuery.value.isEmpty) {
          controller.fetchPayments();
          return true;
        }
        return false;
      },
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: filteredPayments.length +
            ((controller.hasMore.value && _searchQuery.value.isEmpty) ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredPayments.length) {
            return _buildLoadMoreSection(controller);
          }
          return _buildPaymentItem(filteredPayments[index], controller);
        },
      ),
    );
  }

  Widget _buildCachedIndicator() {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 14, color: Colors.amber),
          SizedBox(width: 4),
          Text('Cached',
              style: TextStyle(fontSize: 12, color: Colors.amber.shade800)),
        ],
      ),
    );
  }

  Widget _buildPaymentItem2(Payment payment, KiotaPayThemecontroler themeController,
      PaymentController controller) {
    return InkWell(
      onTap: () => Get.to(() => PaymentDetailsScreen(
        payment: payment,
        isOnline: controller.isOnline.value,
      )),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'TXN: ${payment.transId}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    label: Text(
                      payment.method.toUpperCase(),
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: ChanzoColors.primary,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Amount: ${NumberFormat.currency(locale: 'en_US', symbol: 'KES').format(payment.amount)}',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(payment.paymentDate)}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 4),
              Text(
                'Type: ${payment.paymentType}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Obx(() => !_paymentController.isOnline.value
                  ? Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, size: 14, color: Colors.amber),
                    SizedBox(width: 4),
                    Text('Cached',
                        style: TextStyle(
                            fontSize: 12, color: Colors.amber.shade800)),
                  ],
                ),
              )
                  : SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton(PaymentController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: controller.isLoading.value
            ? CircularProgressIndicator()
            : ElevatedButton(
          onPressed: controller.loadMore,
          child: Text('Load More'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(PaymentController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Payments Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          if (controller.isLoading.value)
            CircularProgressIndicator()
          else
            ElevatedButton(
            onPressed: _resetAndRefresh,
              child: Text('Refresh'),
            ),
        ],
      ),
    );
  }

  void _resetAndRefresh() {
    _selectedRange.value = 'all';
    _paymentController.fetchPayments(refresh: true, range: 'all');
  }

  Widget _buildErrorState(PaymentController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Error Loading Payments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _resetAndRefresh,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class PaymentSearchDelegate extends SearchDelegate<String> {
  final PaymentController paymentController;

  PaymentSearchDelegate(this.paymentController);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = paymentController.payments.where((payment) {
      return payment.transId.toLowerCase().contains(query.toLowerCase()) ||
          payment.method.toLowerCase().contains(query.toLowerCase()) ||
          payment.amount.toString().contains(query) ||
          DateFormat('dd MMM yyyy, hh:mm a')
              .format(payment.paymentDate)
              .toLowerCase()
              .contains(query.toLowerCase());
    }).toList();

    return _buildSearchResults(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }

  Widget _buildSearchResults(List<Payment> results) {
    if (results.isEmpty) {
      return Center(
        child: Text('No payments found for "$query"'),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final payment = results[index];
        return ListTile(
          title: Text('TXN: ${payment.transId}'),
          subtitle: Text(
              '${NumberFormat.currency(locale: 'en_US', symbol: 'KES').format(payment.amount)} - ${DateFormat('dd MMM yyyy').format(payment.paymentDate)}'),
          onTap: () {
            close(context, '');
            Get.to(() => PaymentDetailsScreen(
              payment: payment,
              isOnline: paymentController.isOnline.value,
            ));
          },
        );
      },
    );
  }
}