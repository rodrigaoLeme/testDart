class AccountEntity {
  final bool success;
  final String message;
  final AccountDataEntity dataProfile;
  final int statusCode;

  AccountEntity({
    required this.success,
    required this.message,
    required this.dataProfile,
    required this.statusCode,
  });
}

class AccountDataEntity {
  final int id;
  final String token;

  AccountDataEntity({
    required this.id,
    required this.token,
  });
}
