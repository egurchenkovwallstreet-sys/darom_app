class RealPhoneRequiredException implements Exception {
  RealPhoneRequiredException([this.message =
      'Чтобы разместить объявление или написать в чате, один раз бесплатно подтвердите номер телефона.']);

  final String message;

  @override
  String toString() => message;
}
