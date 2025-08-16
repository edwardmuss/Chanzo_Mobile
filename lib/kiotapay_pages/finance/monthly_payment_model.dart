
class MonthlyPayment {
  final String month;
  final double amount;
  final int year;
  final int monthNumber;

  MonthlyPayment({
    required this.month,
    required this.amount,
    required this.year,
    required this.monthNumber,
  });

  factory MonthlyPayment.fromJson(Map<String, dynamic> json) => MonthlyPayment(
    month: json['month'],
    amount: json['amount'].toDouble(),
    year: json['year'],
    monthNumber: json['month_number'],
  );
}