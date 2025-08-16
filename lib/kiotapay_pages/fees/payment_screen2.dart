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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => _searchQuery.value.isEmpty
            ? Text('Payment History', style: TextStyle(fontWeight: FontWeight.w600))
            : _buildSearchField(isDarkMode)),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: theme.iconTheme.color),
            onPressed: _handleSearchAction,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.iconTheme.color),
            onPressed: () {
              _selectedRange.value = 'all';
              _paymentController.fetchPayments(refresh: true, range: 'all');
            },
          ),
        ],
      ),
      body: GetBuilder<PaymentController>(
        init: _paymentController,
        builder: (controller) {
          if (controller.isLoading.value && controller.payments.isEmpty) {
            return _buildLoadingState();
          }

          if (controller.errorMessage.value.isNotEmpty && controller.payments.isEmpty) {
            return _buildErrorState(controller);
          }

          if (controller.isRefreshing.value) {
            return _buildLoadingState();
          }

          if (!controller.isLoading.value && !controller.isRefreshing.value && controller.payments.isEmpty) {
            return _buildEmptyState(controller);
          }

          return Column(
            children: [
              _buildOfflineBanner(controller),
              _buildFilterChips(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => controller.refreshPayments(),
                  color: theme.primaryColor,
                  child: _buildPaymentList(controller, theme),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading payments...'),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDarkMode) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search payments...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
      ),
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      autofocus: true,
      onChanged: (value) => _searchQuery.value = value.toLowerCase(),
    );
  }

  Widget _buildFilterChips() {
    final filters = {
      'all': 'All',
      '7_days': 'Last 7 Days',
      'last_month': 'Last Month',
      'last_year': 'Last Year',
    };

    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = filters.entries.elementAt(index);
          return Obx(() => FilterChip(
            label: Text(entry.value),
            selected: _selectedRange.value == entry.key,
            onSelected: (_) {
              _selectedRange.value = entry.key;
              _paymentController.fetchPayments(refresh: true, range: entry.key);
            },
            selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
            checkmarkColor: Theme.of(context).primaryColor,
            labelStyle: TextStyle(
              color: _selectedRange.value == entry.key
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            backgroundColor: Theme.of(context).cardColor,
            shape: StadiumBorder(
              side: BorderSide(
                color: _selectedRange.value == entry.key
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).dividerColor,
              ),
            ),
          ));
        },
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
      padding: EdgeInsets.all(12),
      width: double.infinity,
      color: Colors.amber.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 16, color: Colors.amber.shade800),
          SizedBox(width: 8),
          Text(
            'Offline Mode - Showing cached data',
            style: TextStyle(color: Colors.amber.shade800),
          ),
        ],
      ),
    )
        : SizedBox.shrink());
  }
  Widget _buildPaymentList(PaymentController controller, ThemeData theme) {
    final filteredPayments = _getFilteredPayments(controller);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'KES');

    return ListView.builder(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredPayments.length + (controller.hasMore.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredPayments.length) {
          return _buildLoadMoreButton(controller);
        }

        final payment = filteredPayments[index];
        return _buildPaymentItem(payment, controller, theme, currencyFormat);
      },
    );
  }

  Widget _buildPaymentItem(Payment payment, PaymentController controller, ThemeData theme, NumberFormat currencyFormat) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.to(() => PaymentDetailsScreen(
          payment: payment,
          isOnline: controller.isOnline.value,
        )),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      payment.transId,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getMethodColor(payment.method, theme),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      payment.method.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: theme.primaryColor),
                  SizedBox(width: 4),
                  Text(
                    currencyFormat.format(payment.amount),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: theme.hintColor),
                  SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(payment.paymentDate),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (!controller.isOnline.value) _buildCachedIndicator(theme),
            ],
          ),
        ),
      ),
    );
  }
  Color _getMethodColor(String method, ThemeData theme) {
    switch (method.toLowerCase()) {
      case 'mpesa':
        return Color(0xFF00B300);
      case 'cash':
        return Color(0xFF4CAF50);
      case 'bank':
        return Color(0xFF2196F3);
      case 'card':
        return Color(0xFF9C27B0);
      default:
        return theme.primaryColor;
    }
  }

  Widget _buildCachedIndicator(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 14, color: Colors.amber),
          SizedBox(width: 4),
          Text(
            'Showing cached data',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.amber.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(PaymentController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: controller.isLoading.value
            ? CircularProgressIndicator()
            : TextButton(
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          if (!controller.isLoading.value)
            TextButton(
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _resetAndRefresh,
            child: Text('Try Again'),
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