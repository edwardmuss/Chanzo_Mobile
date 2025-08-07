class StudentPerformanceTrend {
  final String student;
  final String session;
  final Map<String, Map<String, double>> trend;

  StudentPerformanceTrend({
    required this.student,
    required this.session,
    required this.trend,
  });

  factory StudentPerformanceTrend.fromJson(Map<String, dynamic> json) {
    final trendData = <String, Map<String, double>>{};

    final trendJson = json['data']['trend'] as Map<String, dynamic>;

    trendJson.forEach((term, assessments) {
      trendData[term] = Map<String, double>.from(
        (assessments as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      );
    });

    return StudentPerformanceTrend(
      student: json['data']['student'] ?? '',
      session: json['data']['session'] ?? '',
      trend: trendData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student': student,
      'session': session,
      'trend': trend.map((term, scores) => MapEntry(
          term, scores.map((k, v) => MapEntry(k, v)))),
    };
  }
}
