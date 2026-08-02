/// Версии юридических документов — синхронизировать с backend/src/utils/legal_versions.js
class LegalConsent {
  LegalConsent._();

  static const String offerVersion = '2026-03-26';
  static const String privacyPolicyVersion = '2026-08-02';
  static const String cookiePolicyVersion = '2026-08-02';

  /// Актуальное согласие на обработку ПДн (версия + дата фиксации).
  static bool isPrivacyConsentCurrent({
    required String? privacyPolicyVersion,
    required DateTime? privacyConsentAt,
  }) {
    return privacyConsentAt != null &&
        privacyPolicyVersion == LegalConsent.privacyPolicyVersion;
  }
}
