const REAL_PHONE_REQUIRED_MESSAGE =
  'Чтобы разместить объявление или написать в чате, один раз бесплатно подтвердите номер телефона.';

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
