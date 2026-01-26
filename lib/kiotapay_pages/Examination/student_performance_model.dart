import 'dart:developer'; // for better formatted logs

class StudentPerformance {
  final StudentInfo student;
  final ExamInfo exam;
  final List<SubjectPerformance> subjects;

  final num totalScore;
  final num previousTotal;
  final num meanScore;
  final String grade;
  final num previousMean;
  final num changeTotal;
  final num percentChangeTotal;
  final num changeMean;
  final String? previousGrade;
  final String? changeTrend;

  StudentPerformance({
    required this.student,
    required this.exam,
    required this.subjects,
    required this.totalScore,
    required this.previousTotal,
    required this.meanScore,
    required this.grade,
    required this.previousMean,
    required this.changeTotal,
    required this.percentChangeTotal,
    required this.changeMean,
    this.previousGrade,
    this.changeTrend,
  });

  factory StudentPerformance.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    return StudentPerformance(
      student: StudentInfo.fromJson(data['student']),
      exam: ExamInfo.fromJson(data['exam']),
      subjects: (data['subjects'] as List<dynamic>)
          .map((e) => SubjectPerformance.fromJson(e))
          .toList(),

      totalScore: data['total_score'] ?? 0,
      previousTotal: data['previous_total'] ?? 0,
      meanScore: data['mean_score'] ?? 0,
      grade: data['grade'] ?? 'N/A',
      previousMean: data['previous_mean'] ?? 0,
      changeTotal: data['change_total'] ?? 0,
      percentChangeTotal: data['percent_change_total'] ?? 0,
      changeMean: data['change_mean'] ?? 0,
      previousGrade: data['previous_grade'],
      changeTrend: data['change_trend'],
    );
  }
}

class StudentInfo {
  final int id;
  final String name;
  final String admissionNo;
  final String className;
  final String stream;

  StudentInfo({
    required this.id,
    required this.name,
    required this.admissionNo,
    required this.className,
    required this.stream,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      admissionNo: json['admission_no'] ?? '',
      className: json['class'] ?? '',
      stream: json['stream'] ?? '',
    );
  }
}

class ExamInfo {
  final int id;
  final String name;
  final String term;
  final String academicSession;

  ExamInfo({
    required this.id,
    required this.name,
    required this.term,
    required this.academicSession,
  });

  factory ExamInfo.fromJson(Map<String, dynamic> json) {
    return ExamInfo(
      id: json['id'],
      name: json['name'] ?? '',
      term: json['term']?.toString() ?? '',
      academicSession: json['academic_session']?.toString() ?? '',
    );
  }
}

class SubjectPerformance {
  final int subjectId;
  final String subjectName;
  final num score;
  final String grade;

  final num? previousScore;
  final String? previousGrade;
  final num? change;
  final String? trend;

  SubjectPerformance({
    required this.subjectId,
    required this.subjectName,
    required this.score,
    required this.grade,
    this.previousScore,
    this.previousGrade,
    this.change,
    this.trend,
  });

  factory SubjectPerformance.fromJson(Map<String, dynamic> json) {
    return SubjectPerformance(
      subjectId: json['subject_id'],
      subjectName: json['subject_name'] ?? '',
      score: json['score'] ?? 0,
      grade: json['grade'] ?? 'N/A',
      previousScore: json['previous_score'],
      previousGrade: json['previous_grade'],
      change: json['change'],
      trend: json['trend'],
    );
  }

  /// Helpers for UI
  bool get hasTrend => trend != null;
  bool get isPositive => change != null && change! >= 0;
}

