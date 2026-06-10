import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'monthly_payment_model.dart';

class MonthlyPaymentsChart extends StatelessWidget {
  final List<MonthlyPayment> payments;

  const MonthlyPaymentsChart({required this.payments});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 12 Months Fee Payments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxY(payments),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          return Transform.rotate(
                            angle: -1.55, // -0.5 radians ≈ -30 degrees
                            child: Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                payments[index].month,
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: payments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final payment = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: payment.amount,
                          color: _getColorForAmount(payment.amount),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        )
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateMaxY(List<MonthlyPayment> payments) {
    final maxAmount = payments.fold(0.0, (max, e) => e.amount > max ? e.amount : max);
    return (maxAmount * 1.2).ceilToDouble(); // Add 20% padding
  }

  Color _getColorForAmount(double amount) {
    if (amount == 0) return Colors.grey;
    return amount > 5000 ? Colors.green : Colors.blue;
  }
}