import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:shimmer/shimmer.dart';

import '../globalclass/kiotapay_fontstyle.dart';
import '../kiotapay_pages/Examination/performance_controller.dart';

class StudentPerformanceDashboard {
  final PerformanceController ctrl = Get.find<PerformanceController>();

  // ---------------- TABLE ----------------
  Widget buildSubjectPerformanceTable() {
    return Obx(() {
      if (ctrl.data.value == null) {
        return _emptyCard(
          title: 'No results',
          subtitle: 'Try refreshing to view subject summary.',
          icon: Icons.event_busy,
        );
      }

      if (ctrl.isLoading.value) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(height: 18),
                const SizedBox(height: 16),
                _shimmerBox(height: 12),
                const SizedBox(height: 10),
                _shimmerBox(height: 12),
                const SizedBox(height: 10),
                _shimmerBox(height: 12),
                const SizedBox(height: 10),
                _shimmerBox(height: 12),
              ],
            ),
          ),
        );
      }

      final performance = ctrl.data.value;
      if (performance == null || performance.subjects.isEmpty) {
        return _emptyCard(
          title: 'No results',
          subtitle: 'No subject performance found for the selected exam/date.',
        );
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
                'Subjects Δ Summary\n${performance.exam.name} - Term ${performance.exam.term}, ${performance.exam.academicSession}',
                style: pmedium.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(flex: 3, child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  Expanded(child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  Expanded(child: Text('Δ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  Expanded(child: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              const Divider(color: ChanzoColors.primary80),
              ...subjects.map((subj) {
                final score = subj.score.toDouble();
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(subj.subjectName)),
                          Expanded(
                            child: Text(
                              score.toStringAsFixed(1),
                              style: TextStyle(
                                color: _getScoreColor(score),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              (subj.change ?? '—').toString(),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              subj.trend ?? '—',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: ChanzoColors.secondary50, thickness: 0.4, height: 2),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      );
    });
  }

  // ---------------- BAR CHART ----------------
  Widget buildSubjectPerformanceChart() {
    return Obx(() {
      if (ctrl.data.value == null) {
        return _emptyCard(
          title: 'No results',
          subtitle: 'Try refreshing to view the performance chart.',
          icon: Icons.bar_chart_outlined,
        );
      }

      if (ctrl.isLoading.value) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(height: 18),
                const SizedBox(height: 16),
                _shimmerBox(height: 280, radius: 16),
              ],
            ),
          ),
        );
      }

      final performance = ctrl.data.value;
      if (performance == null || performance.subjects.isEmpty) {
        return _emptyCard(
          title: 'No results',
          subtitle: 'No subject performance found for the selected exam/date.',
        );
      }

      final subjects = performance.subjects;

      final maxScore = subjects
          .map((s) => s.score.toDouble())
          .fold<double>(0.0, (a, b) => math.max(a, b));
      final maxY = math.max(100.0, ((maxScore / 10).ceil() * 10).toDouble());

      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subjects Performance\n${performance.exam.name} - Term ${performance.exam.term}, ${performance.exam.academicSession}',
                style: pmedium.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 320,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(enabled: true),
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (value, meta) =>
                              Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 56,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            final label = (index >= 0 && index < subjects.length)
                                ? subjects[index].subjectName
                                : '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Transform.rotate(
                                angle: -0.6,
                                child: SizedBox(
                                  width: 60,
                                  child: Text(
                                    label,
                                    style: const TextStyle(fontSize: 10),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(subjects.length, (index) {
                      final score = subjects[index].score.toDouble();
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: score,
                            color: _getScoreColor(score),
                            width: 18,
                            borderRadius: BorderRadius.circular(6),
                          ),
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

  // ---------------- GRID ----------------
  Widget buildPerformanceGrid() {
    return Obx(() {
      if (ctrl.data.value == null) {
        return _emptyCard(
          title: 'No results',
          subtitle: 'Try refreshing to view performance summary.',
          icon: Icons.grid_view,
        );
      }

      if (ctrl.isLoading.value) {
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: List.generate(4, (_) => _shimmerBox(height: 90, radius: 14)),
        );
      }

      final performance = ctrl.data.value;
      if (performance == null) {
        return _emptyCard(
          title: 'No results',
          subtitle: 'No summary found for the selected exam/date.',
        );
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

  // ---------------- TREND CHART ----------------
  Widget buildExamTrendChart() {
    return Obx(() {
      if (ctrl.data.value == null) {
        return _emptyCard(
          title: 'No results',
          subtitle: 'Try refreshing to view trend.',
          icon: Icons.show_chart,
        );
      }

      if (ctrl.isLoading.value) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(height: 18),
                const SizedBox(height: 16),
                _shimmerBox(height: 260, radius: 16),
              ],
            ),
          ),
        );
      }

      final performanceTrend = ctrl.trend_data.value;
      if (performanceTrend == null) {
        return _emptyCard(
          title: 'No results',
          subtitle: 'No trend data available for the selection.',
        );
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

      if (examLabels.isEmpty) {
        return _emptyCard(
          title: 'No results',
          subtitle: 'No exams found to plot.',
        );
      }

      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Trend \nLast ${examLabels.length} Exams in ${performanceTrend.session}',
                style: pmedium.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= examLabels.length) return const SizedBox.shrink();
                            return Transform.rotate(
                              angle: -1.55,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  examLabels[index],
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
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) =>
                              Text('${value.toInt()}%', style: const TextStyle(fontSize: 10)),
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

  // ---------------- helpers (unchanged) ----------------
  Widget _buildStatCard(String title, String value, IconData icon) {
    final bool isDarkMode = Theme.of(Get.context!).brightness == Brightness.dark;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: ChanzoColors.secondary),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
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

  Widget _shimmerBox({double height = 16, double radius = 12}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget _emptyCard({
    required String title,
    required String subtitle,
    IconData icon = Icons.search_off,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 30, color: ChanzoColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}

