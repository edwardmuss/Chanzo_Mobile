class StudentPerformance {
  final StudentInfo student;
  final ExamInfo exam;
  final List<SubjectResult> subjects;
  final num totalScore;
  final num previousTotal;
  final num meanScore;
  final String grade;
  final num previousMean;
  final int changeTotal;
  final num percentChangeTotal;
  final num changeMean;

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
  });

  factory StudentPerformance.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return StudentPerformance(
      student: StudentInfo.fromJson(data['student']),
      exam: ExamInfo.fromJson(data['exam']),
      subjects: (data['subjects'] as List)
          .map((s) => SubjectResult.fromJson(s))
          .toList(),
      totalScore: (data['total_score'] as num).toInt(),
      previousTotal: (data['previous_total'] as num).toInt(),
      meanScore: (data['mean_score'] as num).toDouble(),
      grade: data['grade'],
      previousMean: (data['previous_mean'] as num).toDouble(),
      changeTotal: (data['change_total'] as num).toInt(),
      percentChangeTotal: (data['percent_change_total'] as num).toDouble(),
      changeMean: (data['change_mean'] as num).toDouble(),
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
      name: json['name'],
      admissionNo: json['admission_no'],
      className: json['class'],
      stream: json['stream'],
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
      name: json['name'],
      term: json['term'],
      academicSession: json['academic_session'],
    );
  }
}

class SubjectResult {
  final String subject;
  final num totalWeightedScore;
  final num totalWeight;
  final num finalScore;
  final num previousScore;
  final num percentChange;
  final String grade;
  final num subjectChange;

  SubjectResult({
    required this.subject,
    required this.totalWeightedScore,
    required this.totalWeight,
    required this.finalScore,
    required this.previousScore,
    required this.percentChange,
    required this.grade,
    required this.subjectChange,
  });

  factory SubjectResult.fromJson(Map<String, dynamic> json) {
    return SubjectResult(
      subject: json['subject'],
      totalWeightedScore: json['total_weighted_score'],
      totalWeight: json['total_weight'],
      finalScore: json['final_score'],
      previousScore: json['previous_score'],
      percentChange: (json['percent_change'] as num).toDouble(),
      grade: json['grade'],
      subjectChange: json['subject_change'],
    );
  }
}
