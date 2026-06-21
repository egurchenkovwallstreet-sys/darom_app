const REAL_PHONE_REQUIRED_MESSAGE =
  'Для размещения объявления или переписки нужно один раз подтвердить реальный номер телефона по SMS.';

function isRealPhoneVerified(user) {
  return Boolean(user?.real_phone_verified_at);
}

function buildRealPhoneRequiredResponse() {
  return {
    code: 'REAL_PHONE_REQUIRED',
    message: REAL_PHONE_REQUIRED_MESSAGE,
  };
}

async function countUserChatMessages(db, userId) {
  const result = await db.query(
    'SELECT COUNT(*)::int AS cnt FROM chat_messages WHERE sender_id = $1',
    [userId],
  );
  return result.rows[0]?.cnt ?? 0;
}

module.exports = {
  REAL_PHONE_REQUIRED_MESSAGE,
  isRealPhoneVerified,
  buildRealPhoneRequiredResponse,
  countUserChatMessages,
};
