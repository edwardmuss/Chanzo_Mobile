import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

import '../../globalclass/kiotapay_constants.dart';
import '../../models/payment_model.dart';
import '../finance/monthly_payment_model.dart';
import '../kiotapay_authentication/AuthController.dart';

class PaymentController extends GetxController {
  final RxList<Payment> payments = <Payment>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool hasMore = true.obs;
  final RxBool isOnline = true.obs;
  final RxString errorMessage = ''.obs;
  final RxInt currentPage = 1.obs;
  final int studentId;

  late Box<PaymentResponse>? _paymentBox;

  PaymentController(this.studentId);

  final storage = const FlutterSecureStorage();
  final authController = Get.put(AuthController());
  final RxInt totalItems = 0.obs;
  final RxInt cachedPage = 1.obs;
  final monthlyPayments = <MonthlyPayment>[].obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _paymentBox = await Hive.openBox<PaymentResponse>('paymentResponses');
    await loadCachedPayments();
    await fetchPayments();
  }

  Future<void> fetchPayments({bool refresh = false, String range = 'all'}) async {
    if ((isLoading.value && !refresh) || (isRefreshing.value && refresh)) return;
    // isLoading.value = true;
    try {

      if (refresh) {
        isRefreshing.value = true;
        currentPage.value = 1;
        cachedPage.value = 1;
        hasMore.value = true;
      } else {
        isLoading.value = true;
      }

      errorMessage.value = '';
      update(); // Force UI update to show loading state

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

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final paymentResponse = PaymentResponse.fromJson(jsonResponse);

        totalItems.value = paymentResponse.pagination.total;

        if (paymentResponse.data.isNotEmpty) {
          if (refresh) {
            payments.value = paymentResponse.data;
            await _cachePaymentResponse(paymentResponse, clearExisting: true);
          } else {
            final newPayments = paymentResponse.data.where(
                  (newPayment) => !payments.any((p) => p.id == newPayment.id),
            ).toList();
            payments.addAll(newPayments);
            await _cachePaymentResponse(paymentResponse);
          }

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
      // await Future.delayed(const Duration(milliseconds: 300));
      isLoading.value = false;
      isRefreshing.value = false;
      update();
    }
  }

  Future<void> _cachePaymentResponse(PaymentResponse paymentResponse, {bool clearExisting = false}) async {
    if (_paymentBox == null) return;

    try {
      final cacheKey = 'student_${studentId}_payments';

      if (clearExisting) {
        await _paymentBox!.delete(cacheKey);
      }

      await _paymentBox!.put(cacheKey, paymentResponse);
    } catch (e) {
      print('Error caching payment response: $e');
    }
  }

  Future<void> loadCachedPayments() async {
    if (_paymentBox == null) return;

    try {
      isLoading.value = true;
      final cacheKey = 'student_${studentId}_payments';
      final cachedResponse = _paymentBox!.get(cacheKey);

      if (cachedResponse != null) {
        totalItems.value = cachedResponse.pagination.total;
        payments.value = cachedResponse.data.take(4).toList();
        hasMore.value = payments.length < totalItems.value;
        cachedPage.value = 2;
      }
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
      final cacheKey = 'student_${studentId}_payments';
      final cachedResponse = _paymentBox!.get(cacheKey);

      if (cachedResponse != null) {
        final startIndex = (cachedPage.value - 1) * 4;
        final endIndex = startIndex + 4;
        final newPayments = cachedResponse.data.sublist(
          startIndex,
          endIndex > cachedResponse.data.length ? cachedResponse.data.length : endIndex,
        );

        payments.addAll(newPayments);
        hasMore.value = payments.length < totalItems.value;
        cachedPage.value++;
      }
    } catch (e) {
      errorMessage.value = 'Failed to load more cached payments';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshPayments() async {
    try {
      await fetchPayments(refresh: true);
    } catch (e) {
      rethrow;
    }
  }

  void loadMore() {
    if (hasMore.value && !isLoading.value) {
      fetchPayments();
    }
  }

  Future<void> fetchLast12MonthsPayments() async {
    try {
      isLoading.value = true;
      final token = await storage.read(key: 'token');
      if (token == null) return;

      final url = Uri.parse(
        KiotaPayConstants.getRecentYearlyPayments
            .replaceFirst('{student_id}', studentId.toString()),
      );

      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        monthlyPayments.value = data.map((e) => MonthlyPayment.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching monthly payments: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _paymentBox?.close();
    super.onClose();
  }
}