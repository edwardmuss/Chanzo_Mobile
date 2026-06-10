class BranchContext {
  final int branchId;
  final String branchName;
  final List<String> roles;

  BranchContext({
    required this.branchId,
    required this.branchName,
    required this.roles,
  });

  factory BranchContext.fromJson(Map<String, dynamic> j) => BranchContext(
    branchId: j['branch_id'],
    branchName: j['branch_name'],
    roles: List<String>.from(j['roles'] ?? []),
  );
}

class ActiveContext {
  final int? branchId;
  final String role;
  final String? branchName;

  ActiveContext({this.branchId, required this.role, this.branchName});

  factory ActiveContext.fromJson(Map<String, dynamic> j) => ActiveContext(
    branchId: j['branch_id'],
    role: j['role'],
    branchName: j['branch_name'],
  );
}
