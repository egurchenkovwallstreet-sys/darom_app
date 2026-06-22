const admin = require('firebase-admin');
const config = require('../config');

let messaging = null;

function getMessaging() {
  if (config.pushMock || !config.firebase.projectId) return null;
  if (messaging) return messaging;

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: config.firebase.projectId,
        clientEmail: config.firebase.clientEmail,
        privateKey: config.firebase.privateKey,
      }),
    });
  }

  messaging = admin.messaging();
  return messaging;
}

async function upsertPushToken(db, userId, token, platform = 'web') {
  const cleanToken = String(token || '').trim();
  if (!cleanToken) return null;

  const result = await db.query(
    `
    INSERT INTO user_push_tokens (user_id, token, platform)
    VALUES ($1, $2, $3)
    ON CONFLICT (token) DO UPDATE SET
      user_id = EXCLUDED.user_id,
      platform = EXCLUDED.platform,
      updated_at = NOW()
    RETURNING id, user_id, token, platform
    `,
    [userId, cleanToken, String(platform || 'web').slice(0, 16)]
  );
  return result.rows[0] ?? null;
}

async function removePushToken(db, token) {
  const cleanToken = String(token || '').trim();
  if (!cleanToken) return;
  await db.query('DELETE FROM user_push_tokens WHERE token = $1', [cleanToken]);
}

async function getUserPushTokens(db, userId) {
  const result = await db.query(
    'SELECT token FROM user_push_tokens WHERE user_id = $1 ORDER BY updated_at DESC',
    [userId]
  );
  return result.rows.map((row) => row.token);
}

function trimText(text, max = 120) {
  const value = String(text || '').replace(/\s+/g, ' ').trim();
  if (value.length <= max) return value;
  return `${value.slice(0, max - 1)}…`;
}

async function sendPushToUser(db, userId, { title, body, type, data = {} }) {
  if (!userId) return { skipped: true, reason: 'no_user' };

  if (config.pushMock || !config.firebase.projectId) {
    console.log(`[PUSH MOCK] user=${userId} type=${type} ${title}: ${body}`);
    return { mock: true };
  }

  const fcm = getMessaging();
  if (!fcm) {
    console.warn('[PUSH] Firebase не настроен — пропуск');
    return { skipped: true, reason: 'not_configured' };
  }

  const tokens = await getUserPushTokens(db, userId);
  if (!tokens.length) {
    return { skipped: true, reason: 'no_tokens' };
  }

  const payloadData = {
    type: String(type || 'generic'),
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
    ...Object.fromEntries(
      Object.entries(data).map(([key, value]) => [key, String(value ?? '')])
    ),
  };

  const response = await fcm.sendEachForMulticast({
    tokens,
    notification: {
      title: trimText(title, 80),
      body: trimText(body, 180),
    },
    data: payloadData,
    webpush: {
      fcmOptions: {
        link: config.publicBaseUrl || 'https://darom-app.online/',
      },
    },
  });

  if (response.failureCount > 0) {
    const invalidTokens = [];
    response.responses.forEach((item, index) => {
      if (item.success) return;
      const code = item.error?.code || '';
      if (code === 'messaging/registration-token-not-registered' || code === 'messaging/invalid-registration-token') {
        invalidTokens.push(tokens[index]);
      }
    });
    for (const token of invalidTokens) {
      await removePushToken(db, token);
    }
  }

  console.log(
    `[PUSH] user=${userId} type=${type} sent=${response.successCount} failed=${response.failureCount}`
  );
  return {
    sent: response.successCount,
    failed: response.failureCount,
  };
}

function queuePushToUser(db, userId, payload) {
  sendPushToUser(db, userId, payload).catch((err) => {
    console.error('[PUSH] send failed:', err.message);
  });
}

async function notifyListingReserved(db, { donorUserId, listingTitle, recipientName, listingId }) {
  queuePushToUser(db, donorUserId, {
    title: 'Новая бронь',
    body: `${recipientName} забронировал(а) «${listingTitle}» на 24 ч`,
    type: 'reservation',
    data: { listing_id: listingId },
  });
}

async function notifyChatMessage(db, {
  recipientUserId,
  senderName,
  listingTitle,
  conversationId,
  preview,
}) {
  queuePushToUser(db, recipientUserId, {
    title: `${senderName} · ${listingTitle}`,
    body: trimText(preview, 140),
    type: 'chat_message',
    data: { conversation_id: conversationId, listing_title: listingTitle },
  });
}

async function notifyDealGiven(db, { recipientUserId, listingTitle, listingId, dealId }) {
  queuePushToUser(db, recipientUserId, {
    title: 'Вещь отдана',
    body: `Даритель отметил «Отдал» — «${listingTitle}». Оцените сделку в профиле.`,
    type: 'deal_given',
    data: { listing_id: listingId, deal_id: dealId },
  });
}

module.exports = {
  upsertPushToken,
  removePushToken,
  sendPushToUser,
  notifyListingReserved,
  notifyChatMessage,
  notifyDealGiven,
};
