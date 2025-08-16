import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:kiotapay/kiotapay_pages/fees/payment_methods_service.dart';
import '../../globalclass/chanzo_color.dart';
import '../../models/payment_methods.dart';
import '../kiotapay_authentication/AuthController.dart';
import 'payment_kcb_confirm.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _repository = PaymentMethodsService();
  final _authController = Get.put(AuthController());

  bool _isLoading = true;
  String? _error;
  List<PaymentMethod> _activeMethods = [];

  final _nameMap = {
    'mpesa': 'MPESA Express',
    'kcb': 'KCB Online',
    'offline': 'Offline Payment',
  };

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final methods = await _repository.fetchActiveMethods();
      setState(() => _activeMethods = methods);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showOfflineContent(String? html) {
    final admission = _authController.selectedStudentAdmissionNumber;
    final parsedHtml = html?.replaceAll('{admission_number}', admission) ?? 'No instructions provided';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Offline Payment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Html(data: parsedHtml),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentForm(String methodName) {
    final _formKey = GlobalKey<FormState>();
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    final admission = _authController.selectedStudentAdmissionNumber;
    final isKcb = methodName.toLowerCase() == 'kcb';

    final account = isKcb
        ? '${_authController.selectedStudent['bank_code']}#$admission'
        : admission;

    final methodKey = methodName.toLowerCase();
    final methodDisplayName = _nameMap[methodKey] ?? methodName.toUpperCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Header with logo + title + close
                  Row(
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/$methodKey.png',
                        width: 30,
                        height: 30,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.payment, size: 28),
                      ),
                      const SizedBox(width: 10),

                      // Title
                      Expanded(
                        child: Text(
                          '$methodDisplayName',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),

                      // Close
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  /// Phone
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  /// Amount
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Amount is required';
                      }
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  /// Readonly Account
                  TextFormField(
                    initialValue: account,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Account',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: ChanzoColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Continue'),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentConfirmScreen(
                                phone: phoneController.text.trim(),
                                amount: int.parse(amountController.text.trim()),
                                account: account,
                                method: methodName,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Payment Methods')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _loadMethods, child: const Text('Retry')),
          ],
        ),
      )
          : _activeMethods.isEmpty
          ? const Center(child: Text('No active payment methods found'))
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _activeMethods.map((method) {
              final methodName = _nameMap[method.name.toLowerCase()] ?? method.name.toUpperCase();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: ChanzoColors.secondary, width: 1.3),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: Image.asset(
                      'assets/images/${method.name.toLowerCase()}.png',
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.payment),
                    ),
                    title: Text(
                      methodName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Pay using $methodName'),
                    trailing: Icon(Icons.arrow_forward_ios, color: ChanzoColors.secondary, size: 20),
                      onTap: () {
                        final name = method.name.toLowerCase();

                        if (name == 'offline') {
                          _showOfflineContent(method.credentials['offline_content']);
                          return;
                        }

                        if (name == 'kcb') {
                          final bankCode = method.credentials['bank_code'];
                          if (bankCode == null || bankCode.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bank code is required for KCB method')),
                            );
                            return;
                          }

                          // Inject bank_code into student map if needed
                          _authController.selectedStudent['bank_code'] = bankCode;
                        }

                        _showPaymentForm(name); // Proceed to show payment form
                      },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
