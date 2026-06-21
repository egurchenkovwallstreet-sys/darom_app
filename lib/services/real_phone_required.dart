class RealPhoneRequiredException implements Exception {
  RealPhoneRequiredException([this.message =
      'Для размещения объявления или переписки нужно один раз подтвердить реальный номер телефона по SMS.']);

  final String message;

  @override
  String toString() => message;
}
