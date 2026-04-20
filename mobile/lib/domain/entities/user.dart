class UserEntity {
  final String id;
  final String username;
  final String? email;
  final String fullName;
  final bool isActive;
  final List<String> roles;

  const UserEntity({
    required this.id,
    required this.username,
    this.email,
    required this.fullName,
    required this.isActive,
    required this.roles,
  });

  bool get isAdmin => roles.contains('admin');
  bool get isSupervisor => roles.contains('supervisor');
  bool get isInventorizator => roles.contains('inventorizator');
  bool get isAccountant => roles.contains('accountant');

  bool hasRole(String role) => roles.contains(role);
}
