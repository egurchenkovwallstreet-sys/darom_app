const express = require('express');
const db = require('../db/pool');
const { normalizePhone } = require('../utils/phone');
const {
  expireReservations,
  getUserByPhone,
  fetchListingById,
  mapListingRow,
} = require('../db/listing_helpers');
const { getPickupStatus, buildPickupLimitResponse } = require('../utils/pickup_limits');
const { containsPhoneNumber } = require('../utils/phone_detect');

const router = express.Router();

const URL_RE = /https?:\/\/|www\./i;

function validateMessageBody(body) {
  const text = String(body ?? '').trim();
  if (text.length < 1) {
    return { ok: false, error: 'Сообщение не может быть пустым' };
  }
  if (text.length > 2000) {
    return { ok: false, error: 'Сообщение слишком длинное (макс. 2000 символов)' };
  }
  if (URL_RE.test(text)) {
    return { ok: false, error: 'Ссылки в чате запрещены' };
  }
  return { ok: true, text };
}

async function getConversationForUser(conversationId, userId) {
  const result = await db.query(
    `
    SELECT
      c.id,
      c.listing_id,
      c.donor_id,
      c.recipient_id,
      c.created_at,
      c.updated_at,
      l.title AS listing_title,
      l.status AS listing_status,
      l.reserved_by_user_id,
      l.reserved_until,
      du.name AS donor_name,
      ru.name AS recipient_name
    FROM conversations c
    JOIN listings l ON l.id = c.listing_id
    JOIN users du ON du.id = c.donor_id
    JOIN users ru ON ru.id = c.recipient_id
    WHERE c.id = $1 AND (c.donor_id = $2 OR c.recipient_id = $2)
    `,
    [conversationId, userId]
  );
  return result.rows[0] ?? null;
}

function mapConversationRow(row, userId) {
  const isDonor = row.donor_id === userId;
  return {
    id: row.id,
    listing_id: row.listing_id,
    listing_title: row.listing_title,
    listing_status: row.listing_status,
    donor_id: row.donor_id,
    recipient_id: row.recipient_id,
    counterparty_name: isDonor ? row.recipient_name : row.donor_name,
    is_donor: isDonor,
    can_reserve:
      !isDonor &&
      row.listing_status === 'active' &&
      row.recipient_id === userId,
    is_reserved_by_me:
      row.listing_status === 'reserved' && row.reserved_by_user_id === userId,
    last_message: row.last_message ?? null,
    last_message_at: row.last_message_at ?? row.updated_at,
    unread_count: Number(row.unread_count ?? 0),
    created_at: row.created_at,
  };
}

async function markConversationRead(conversationId, userId) {
  await db.query(
    `
    INSERT INTO conversation_reads (conversation_id, user_id, last_read_at)
    VALUES (
      $1,
      $2,
      COALESCE(
        (SELECT MAX(created_at) FROM chat_messages WHERE conversation_id = $1),
        NOW()
      )
    )
    ON CONFLICT (conversation_id, user_id)
    DO UPDATE SET last_read_at = EXCLUDED.last_read_at
    `,
    [conversationId, userId]
  );
}

const unreadCountSelect = `
  COALESCE((
    SELECT COUNT(*)::int
    FROM chat_messages cm
    LEFT JOIN conversation_reads cr
      ON cr.conversation_id = cm.conversation_id AND cr.user_id = $1
    WHERE cm.conversation_id = c.id
      AND cm.sender_id != $1
      AND cm.created_at > COALESCE(cr.last_read_at, TIMESTAMPTZ '1970-01-01')
  ), 0) AS unread_count
`;

// GET /api/chats/unread-summary?phone= — только число для бейджа в меню
router.get('/unread-summary', async (req, res) => {
  const { phone } = req.query;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен параметр phone' });
  }

  try {
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const result = await db.query(
      `
      SELECT COUNT(*)::int AS total_unread
      FROM chat_messages cm
      JOIN conversations c ON c.id = cm.conversation_id
      LEFT JOIN conversation_reads cr
        ON cr.conversation_id = c.id AND cr.user_id = $1
      WHERE (c.donor_id = $1 OR c.recipient_id = $1)
        AND cm.sender_id != $1
        AND cm.created_at > COALESCE(cr.last_read_at, TIMESTAMPTZ '1970-01-01')
      `,
      [user.id]
    );

    res.json({ total_unread: result.rows[0]?.total_unread ?? 0 });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/chats?phone=
router.get('/', async (req, res) => {
  const { phone } = req.query;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен параметр phone' });
  }

  try {
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const result = await db.query(
      `
      SELECT
        c.id,
        c.listing_id,
        c.donor_id,
        c.recipient_id,
        c.created_at,
        c.updated_at,
        l.title AS listing_title,
        l.status AS listing_status,
        l.reserved_by_user_id,
        l.reserved_until,
        du.name AS donor_name,
        ru.name AS recipient_name,
        lm.body AS last_message,
        lm.created_at AS last_message_at,
        ${unreadCountSelect}
      FROM conversations c
      JOIN listings l ON l.id = c.listing_id
      JOIN users du ON du.id = c.donor_id
      JOIN users ru ON ru.id = c.recipient_id
      LEFT JOIN LATERAL (
        SELECT body, created_at
        FROM chat_messages
        WHERE conversation_id = c.id
        ORDER BY created_at DESC
        LIMIT 1
      ) lm ON TRUE
      WHERE c.donor_id = $1 OR c.recipient_id = $1
      ORDER BY COALESCE(lm.created_at, c.updated_at) DESC
      `,
      [user.id]
    );

    res.json({
      items: result.rows.map((row) => mapConversationRow(row, user.id)),
      total_unread: result.rows.reduce(
        (sum, row) => sum + Number(row.unread_count ?? 0),
        0
      ),
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/chats/start { phone, listing_id }
router.post('/start', async (req, res) => {
  const { phone, listing_id: listingId } = req.body;

  if (!phone || !listingId) {
    return res.status(400).json({ error: 'Нужны phone и listing_id' });
  }

  try {
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const listing = await fetchListingById(db, listingId);
    if (!listing) {
      return res.status(404).json({ error: 'Объявление не найдено' });
    }
    if (listing.owner_id === user.id) {
      return res.status(400).json({ error: 'Нельзя написать самому себе по своему объявлению' });
    }
    if (!['active', 'reserved'].includes(listing.status)) {
      return res.status(400).json({ error: 'Объявление недоступно для чата' });
    }

    const existing = await db.query(
      `
      SELECT id FROM conversations
      WHERE listing_id = $1 AND recipient_id = $2
      `,
      [listingId, user.id]
    );

    let conversationId;
    if (existing.rows[0]) {
      conversationId = existing.rows[0].id;
    } else {
      const inserted = await db.query(
        `
        INSERT INTO conversations (listing_id, donor_id, recipient_id)
        VALUES ($1, $2, $3)
        RETURNING id
        `,
        [listingId, listing.owner_id, user.id]
      );
      conversationId = inserted.rows[0].id;
    }

    const conversation = await getConversationForUser(conversationId, user.id);
    res.status(201).json({ conversation: mapConversationRow(conversation, user.id) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/chats/:id/messages?phone=&after_id=
router.get('/:id/messages', async (req, res) => {
  const { phone, after_id: afterId } = req.query;
  const { id } = req.params;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен параметр phone' });
  }

  try {
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const conversation = await getConversationForUser(id, user.id);
    if (!conversation) {
      return res.status(404).json({ error: 'Чат не найден' });
    }

    const params = [id];
    let afterClause = '';
    if (afterId) {
      params.push(afterId);
      afterClause = `
        AND created_at > (
          SELECT created_at
          FROM chat_messages
          WHERE id = $2::uuid AND conversation_id = $1
        )
      `;
    }

    const result = await db.query(
      `
      SELECT id, conversation_id, sender_id, body, created_at
      FROM chat_messages
      WHERE conversation_id = $1 ${afterClause}
      ORDER BY created_at ASC
      LIMIT 200
      `,
      params
    );

    res.json({
      conversation: mapConversationRow(conversation, user.id),
      messages: result.rows,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/chats/:id/read { phone } — отметить чат прочитанным
router.post('/:id/read', async (req, res) => {
  const { phone } = req.body;
  const { id } = req.params;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  try {
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const conversation = await getConversationForUser(id, user.id);
    if (!conversation) {
      return res.status(404).json({ error: 'Чат не найден' });
    }

    await markConversationRead(id, user.id);
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/chats/:id/messages { phone, body }
router.post('/:id/messages', async (req, res) => {
  const { phone, body } = req.body;
  const { id } = req.params;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  const validation = validateMessageBody(body);
  if (!validation.ok) {
    return res.status(400).json({ error: validation.error });
  }

  try {
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const conversation = await getConversationForUser(id, user.id);
    if (!conversation) {
      return res.status(404).json({ error: 'Чат не найден' });
    }

    const inserted = await db.query(
      `
      INSERT INTO chat_messages (conversation_id, sender_id, body)
      VALUES ($1, $2, $3)
      RETURNING id, conversation_id, sender_id, body, created_at
      `,
      [id, user.id, validation.text]
    );

    await db.query('UPDATE conversations SET updated_at = NOW() WHERE id = $1', [id]);

    const phoneSharingWarning = containsPhoneNumber(validation.text);

    res.status(201).json({
      message: inserted.rows[0],
      phone_sharing_warning: phoneSharingWarning,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/chats/:id/reserve { phone } — бронь из чата
router.post('/:id/reserve', async (req, res) => {
  const { phone } = req.body;
  const { id } = req.params;

  if (!phone) {
    return res.status(400).json({ error: 'Нужен phone' });
  }

  try {
    await expireReservations(db);
    const user = await getUserByPhone(db, normalizePhone(phone));
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const conversation = await getConversationForUser(id, user.id);
    if (!conversation) {
      return res.status(404).json({ error: 'Чат не найден' });
    }
    if (conversation.recipient_id !== user.id) {
      return res.status(403).json({ error: 'Бронировать может только получатель' });
    }

    const listing = await fetchListingById(db, conversation.listing_id);
    if (!listing) {
      return res.status(404).json({ error: 'Объявление не найдено' });
    }
    if (listing.status !== 'active') {
      return res.status(400).json({ error: 'Объявление уже забронировано или недоступно' });
    }

    const pickupStatus = await getPickupStatus(db, user.id);
    if (!pickupStatus.can_reserve) {
      return res.status(402).json(buildPickupLimitResponse(pickupStatus));
    }

    await db.query(
      `
      UPDATE listings
      SET
        status = 'reserved',
        reserved_by_user_id = $2,
        reserved_until = NOW() + INTERVAL '24 hours'
      WHERE id = $1 AND status = 'active'
      `,
      [conversation.listing_id, user.id]
    );

    const updatedListing = await fetchListingById(db, conversation.listing_id);
    const updatedConversation = await getConversationForUser(id, user.id);

    res.json({
      item: mapListingRow(updatedListing),
      conversation: mapConversationRow(updatedConversation, user.id),
      message: 'Забронировано на 24 часа',
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
