import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../globalclass/kiotapay_constants.dart';
import '../../models/payment_model.dart';
import '../finance/monthly_payment_model.dart';
import '../kiotapay_authentication/AuthController.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';

class PaymentController extends GetxController {
  final RxList<Payment> payments = <Payment>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool hasMore = true.obs;
  final RxBool isOnline = true.obs;
  final RxString errorMessage = ''.obs;
  final RxInt currentPage = 1.obs;
  final int studentId;

  late Box<Payment>? _paymentBox;

  PaymentController(this.studentId);

  final storage = const FlutterSecureStorage();
  final authController = Get.put(AuthController());
  final RxInt totalItems = 0.obs; // Track total items count
  final RxInt cachedPage = 1.obs; // Track cached pagination
  final monthlyPayments = <MonthlyPayment>[].obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    if (!Hive.isBoxOpen('payments')) {
      _paymentBox = await Hive.openBox<Payment>('payments');
    } else {
      _paymentBox = Hive.box('payments');
    }
    await loadCachedPayments(); // Load cached data first
    fetchPayments(); // Then try to fetch fresh data
  }

  Future<void> fetchPayments({bool refresh = false, String range = 'all'}) async {
    if ((isLoading.value && !refresh) || (isRefreshing.value && refresh)) return;

    try {
      errorMessage.value = '';

      if (refresh) {
        isRefreshing.value = true;
        currentPage.value = 1;
        cachedPage.value = 1;
        hasMore.value = true;
        // payments.clear();
        update();
      } else {
        isLoading.value = true;
      }

      if (range != 'all') {
        payments.clear();
      }

      final token = await storage.read(key: 'token');
      if (token == null) throw Exception('No authentication token found');

      final url = Uri.parse(
        KiotaPayConstants.getRecentPayments
            .replaceFirst('{student_id}', studentId.toString()) +
            '?page=${isOnline.value ? currentPage.value : cachedPage.value}' +
            '&range=$range',
      );

      final response = await http.get(url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final paymentResponse = PaymentResponse.fromJson(jsonResponse);

        totalItems.value = paymentResponse.pagination.total;

        if (paymentResponse.payments.isNotEmpty) {
          if (refresh) {
            payments.value = paymentResponse.payments;
            await _cachePayments(paymentResponse.payments, clearExisting: true); // clear old
          } else {
            final newPayments = paymentResponse.payments.where(
                    (newPayment) => !payments.any((p) => p.id == newPayment.id)
            ).toList();
            payments.addAll(newPayments);
            await _cachePayments(newPayments); // just append new ones
          }

          // await _cachePayments(paymentResponse.payments);

          if (isOnline.value) {
            hasMore.value = currentPage.value < paymentResponse.pagination.lastPage;
            currentPage.value++;
          } else {
            hasMore.value = payments.length < totalItems.value;
            cachedPage.value++;
          }
        }
      } else {
        throw Exception('Failed to load payments: ${response.statusCode}');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      if (refresh && payments.isEmpty && range == 'all') {
        await loadCachedPayments();
      }
      rethrow;
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      update();
    }
  }

  Future<void> refreshPayments() async {
    try {
      await fetchPayments(refresh: true);
    } catch (e) {
      // Error will be shown through errorMessage
      rethrow;
    }
  }

  Future<void> _cachePayments(List<Payment> newPayments, {bool clearExisting = false}) async {
    if (_paymentBox == null) return;

    try {
      if (clearExisting) {
        // Only clear if we're doing a full refresh
        final toRemove = _paymentBox!.values.where((p) => p.studentId == studentId).toList();
        for (final payment in toRemove) {
          await _paymentBox!.delete(payment.id);
        }
      }

      // Add/update new payments
      for (final payment in newPayments) {
        await _paymentBox!.put(payment.id, payment);
      }
    } catch (e) {
      print('Error caching payments: $e');
    }
  }


  Future<void> loadCachedPayments() async {
    if (_paymentBox == null) return;

    try {
      isLoading.value = true;
      final allCachedPayments = _paymentBox!.values.toList().cast<Payment>();
      final studentPayments = allCachedPayments.where((p) => p.studentId == studentId).toList();

      totalItems.value = studentPayments.length;
      payments.value = studentPayments.take(4).toList(); // Initial load of 4 items

      hasMore.value = payments.length < totalItems.value;
      cachedPage.value = 2; // Start from page 2 for cached data
    } catch (e) {
      errorMessage.value = 'Failed to load cached payments';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreCached() async {
    if (_paymentBox == null || !hasMore.value) return;

    try {
      isLoading.value = true;
      final allCachedPayments = _paymentBox!.values.toList().cast<Payment>();
      final studentPayments = allCachedPayments.where((p) => p.studentId == studentId).toList();

      final startIndex = (cachedPage.value - 1) * 4;
      final endIndex = startIndex + 4;
      final newPayments = studentPayments.sublist(
          startIndex,
          endIndex > studentPayments.length ? studentPayments.length : endIndex
      );

      payments.addAll(newPayments);
      hasMore.value = payments.length < totalItems.value;
      cachedPage.value++;
    } catch (e) {
      errorMessage.value = 'Failed to load more cached payments';
    } finally {
      isLoading.value = false;
    }
  }

  void loadMore() {
    if (hasMore.value && !isLoading.value) {
      fetchPayments();
    }
  }

  Future<void> fetchLast12MonthsPayments() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) return;

      final url = Uri.parse(
        KiotaPayConstants.getRecentYearlyPayments
            .replaceFirst('{student_id}', studentId.toString()),
      );

      final response = await http.get(url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        monthlyPayments.value = data.map((e) => MonthlyPayment.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching monthly payments: $e');
    }
  }
}
