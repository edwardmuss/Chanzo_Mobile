class StudentAcademicSession {
  final int id;
  final int studentId;
  final int academicSessionId;
  final int termId;
  final String year;
  final String status;
  final List<Term> terms;

  StudentAcademicSession({
    required this.id,
    required this.studentId,
    required this.academicSessionId,
    required this.termId,
    required this.year,
    required this.status,
    required this.terms,
  });

  factory StudentAcademicSession.fromJson(Map<String, dynamic> json) {
    final session = json['academic_session'];
    return StudentAcademicSession(
      id: json['id'],
      studentId: json['student_id'],
      academicSessionId: session['id'],
      termId: json['term_id'],
      year: session['year'],
      status: session['status'],
      terms: (session['terms'] as List)
          .map((t) => Term.fromJson(t))
          .toList(),
    );
  }
}

class Term {
  final int id;
  final String termNumber;

  Term({
    required this.id,
    required this.termNumber,
  });

  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      id: json['id'],
      termNumber: json['term_number'],
    );
  }
}
