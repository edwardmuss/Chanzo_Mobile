import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';

import '../globalclass/kiotapay_fontstyle.dart';
import '../kiotapay_pages/Examination/performance_controller.dart';

class StudentPerformanceDashboard {
  final PerformanceController ctrl = Get.put(PerformanceController());
  // Bar Chart for Subject Performance
  Widget buildSubjectPerformanceTable() {
    return Obx(() {
      final performance = ctrl.data.value;
      if (performance == null) {
        return const SizedBox.shrink();
      }

      final subjects = performance.subjects;

      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subject Deviation (Δ)\n${performance.exam.name} - ${performance.exam.term}, ${performance.exam.academicSession}',
                style: pmedium.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),

              // Table Header
              Row(
                children: const [
                  Expanded(flex: 3, child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Δ', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              const Divider(color: ChanzoColors.primary80,),

              // Table Rows
              ...subjects.map((subj) {
                final deviation = subj.subjectChange;
                final isPositive = deviation >= 0;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(subj.subject)),
                          // Score
                          Expanded(
                            child: Text(
                              subj.finalScore.toStringAsFixed(1),
                              style: TextStyle(
                                color: _getScoreColor(subj.finalScore.toDouble()),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Deviation with arrow
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  deviation.abs().toStringAsFixed(1),
                                  style: TextStyle(
                                    color: isPositive ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 14,
                                  color: isPositive ? Colors.green : Colors.red,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: ChanzoColors.secondary50,
                      // height: 2,
                      thickness: 0.4,
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      );
    });
  }

  // Bar Chart for Subject Performance
  Widget buildSubjectPerformanceChart() {
    return Obx(() {
      final performance = ctrl.data.value;
      if (performance == null) {
        return const SizedBox.shrink();
      }

      final subjects = performance.subjects;

      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subjects Performance\n${performance.exam.name} - ${performance.exam.term}, ${performance.exam.academicSession}',
                style: pmedium.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          // getTitlesWidget: (value, meta) {
                          //   final index = value.toInt();
                          //   return Padding(
                          //     padding: const EdgeInsets.only(top: 8.0),
                          //     child: Text(
                          //       index < subjects.length ? subjects[index].subject : '',
                          //       style: const TextStyle(fontSize: 10),
                          //       overflow: TextOverflow.ellipsis,
                          //     ),
                          //   );
                          // },

                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            return Transform.rotate(
                              angle: -1.55, // -0.5 radians ≈ -30 degrees
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  index < subjects.length ? subjects[index].subject : '',
                                  style: const TextStyle(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) =>
                              Text('${value.toInt()}%', style: const TextStyle(fontSize: 10)),
                          reservedSize: 40,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(subjects.length, (index) {
                      final score = subjects[index].finalScore;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: score.toDouble(),
                            color: _getScoreColor(score.toDouble()),
                            width: 20,
                            borderRadius: BorderRadius.circular(4),
                          )
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // Performance Summary Grid (2x2)
  Widget buildPerformanceGrid() {
    return Obx(() {
      final performance = ctrl.data.value;
      if (performance == null) {
        return const SizedBox.shrink();
      }

      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _buildStatCard('Mean Marks', '${performance.meanScore.toStringAsFixed(1)}%', Icons.percent),
          _buildStatCard('Total Marks', '${performance.totalScore}', Icons.check_circle_outline),
          _buildStatCard('Mean Grade', performance.grade, Icons.school),
          _buildStatCard('Last Mean', '${performance.previousMean.toStringAsFixed(1)}%', Icons.history),
        ],
      );
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    // Get the current theme brightness
    final bool isDarkMode = Theme.of(Get.context!).brightness == Brightness.dark;

    return Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: ChanzoColors.secondary),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                // Use white in dark mode, primary color in light mode
                color: isDarkMode ? Colors.white : ChanzoColors.primary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildExamTrendChart() {
    return Obx(() {
      final performanceTrend = ctrl.trend_data.value;

      if (performanceTrend == null) {
        return const SizedBox.shrink();
      }

      final trend = performanceTrend.trend;

      final examLabels = <String>[];
      final examScores = <double>[];

      trend.forEach((term, exams) {
        final shortTerm = term.replaceAll('Term-', 'T');
        exams.forEach((examName, score) {
          examLabels.add('$shortTerm $examName');
          examScores.add(score);
        });
      });

      return Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Trend \nLast ${examLabels.length} Exams in ${performanceTrend.session}',
                style: pmedium.copyWith(fontSize: 18),
              ),
              SizedBox(height: 16),
              Container(
                height: 300,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index < 0 || index >= examLabels.length) {
                              return SizedBox();
                            }
                            return Transform.rotate(
                              angle: -1.55,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  examLabels[index],
                                  style: TextStyle(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
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
                              '${value.toInt()}%',
                              style: TextStyle(fontSize: 10),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: const Color(0xff37434d), width: 1),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(examScores.length, (index) {
                          return FlSpot(index.toDouble(), examScores[index]);
                        }),
                        isCurved: true,
                        color: ChanzoColors.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: ChanzoColors.primary.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // Helper function to determine bar color based on score
  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
