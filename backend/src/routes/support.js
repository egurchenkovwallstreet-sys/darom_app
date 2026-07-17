const express = require('express');
const db = require('../db/pool');
const { sanitizeUserText, containsDangerousMarkup } = require('../utils/sanitize_text');
const { requireUserSession, rejectMismatchedPhone } = require('../middleware/user_auth');
const {
  requireAdminUserSession,
  requireSuperAdminUserSession,
} = require('../middleware/require_admin_user');
const { supportCreateLimiter, supportMessageLimiter } = require('../middleware/rate_limit');

const router = express.Router();

const VALID_STATUSES = ['new', 'in_progress', 'closed'];

function ensureSessionPhone(req, res, phoneRaw) {
  if (!phoneRaw) {
    res.status(400).json({ error: 'Нужен phone' });
    return false;
  }
  if (!rejectMismatchedPhone(req, res, phoneRaw)) {
    return false;
  }
  return true;
}

function validateSupportBody(body, { maxLen = 2000, minLen = 1 } = {}) {
  const text = sanitizeUserText(body);
  if (text.length < minLen) {
    return { ok: false, error: 'Сообщение не может быть пустым' };
  }
  if (containsDangerousMarkup(String(body ?? ''))) {
    return { ok: false, error: 'HTML и скрипты запрещены' };
  }
  if (text.length > maxLen) {
    return { ok: false, error: `Слишком длинный текст (макс. ${maxLen} символов)` };
  }
  return { ok: true, text };
}

function validateSubject(subjectRaw) {
  if (subjectRaw == null || String(subjectRaw).trim() === '') {
    return { ok: true, subject: null };
  }
  const subject = sanitizeUserText(subjectRaw).slice(0, 200);
  if (containsDangerousMarkup(String(subjectRaw ?? ''))) {
    return { ok: false, error: 'HTML и скрипты в теме запрещены' };
  }
  return { ok: true, subject: subject || null };
}

function mapTicketRow(row) {
  return {
    id: row.id,
    subject: row.subject,
    status: row.status,
    created_at: row.created_at,
    updated_at: row.updated_at,
    last_message: row.last_message ?? null,
    last_message_at: row.last_message_at ?? row.updated_at,
    user_name: row.user_name ?? null,
    user_phone: row.user_phone ?? null,
    unread_for_user: Number(row.unread_for_user ?? 0),
    unread_for_admin: Number(row.unread_for_admin ?? 0),
  };
}

function mapMessageRow(row) {
  return {
    id: row.id,
    ticket_id: row.ticket_id,
    author_role: row.author_role,
    body: row.body,
    created_at: row.created_at,
  };
}

async function getTicketForUser(ticketId, userId) {
  const result = await db.query(
    `
    SELECT id, user_id, subject, status, created_at, updated_at
    FROM support_tickets
    WHERE id = $1 AND user_id = $2
    `,
    [ticketId, userId]
  );
  return result.rows[0] ?? null;
}

async function getTicketById(ticketId) {
  const result = await db.query(
    `
    SELECT id, user_id, subject, status, created_at, updated_at
    FROM support_tickets
    WHERE id = $1
    `,
    [ticketId]
  );
  return result.rows[0] ?? null;
}

async function fetchMessages(ticketId) {
  const result = await db.query(
    `
    SELECT id, ticket_id, author_role, body, created_at
    FROM support_messages
    WHERE ticket_id = $1
    ORDER BY created_at ASC
    `,
    [ticketId]
  );
  return result.rows.map(mapMessageRow);
}

async function markTicketRead(ticketId, readerRole, readerId) {
  await db.query(
    `
    INSERT INTO support_ticket_reads (ticket_id, reader_role, reader_id, last_read_at)
    VALUES (
      $1,
      $2,
      $3,
      COALESCE(
        (SELECT MAX(created_at) FROM support_messages WHERE ticket_id = $1),
        NOW()
      )
    )
    ON CONFLICT (ticket_id, reader_role, reader_id)
    DO UPDATE SET last_read_at = EXCLUDED.last_read_at
    `,
    [ticketId, readerRole, readerId]
  );
}

const unreadForUserSelect = `
  COALESCE((
    SELECT COUNT(*)::int
    FROM support_messages sm
    LEFT JOIN support_ticket_reads str
      ON str.ticket_id = sm.ticket_id
     AND str.reader_role = 'user'
     AND str.reader_id = $1
    WHERE sm.ticket_id = t.id
      AND sm.author_role = 'admin'
      AND sm.created_at > COALESCE(str.last_read_at, TIMESTAMPTZ '1970-01-01')
  ), 0) AS unread_for_user
`;

function unreadForAdminSelect(adminIdParam) {
  return `
  COALESCE((
    SELECT COUNT(*)::int
    FROM support_messages sm
    LEFT JOIN support_ticket_reads str
      ON str.ticket_id = sm.ticket_id
     AND str.reader_role = 'admin'
     AND str.reader_id = ${adminIdParam}
    WHERE sm.ticket_id = t.id
      AND sm.author_role = 'user'
      AND sm.created_at > COALESCE(str.last_read_at, TIMESTAMPTZ '1970-01-01')
  ), 0) AS unread_for_admin
`;
}

function supportReadsDbError(error) {
  const message = String(error?.message ?? error);
  if (error?.code === '42P01' && message.includes('support_ticket_reads')) {
    return 'База данных не обновлена: выполните migrate_support_reads.sql на сервере (VNC)';
  }
  if (error?.code === '42P01') {
    return 'База данных не обновлена: выполните migrate_support.sql на сервере (VNC)';
  }
  return message;
}

// ─── Пользователь ───────────────────────────────────────────────────────────

router.post('/tickets', requireUserSession, supportCreateLimiter, async (req, res) => {
  const { phone, subject: subjectRaw, body } = req.body ?? {};
  if (!ensureSessionPhone(req, res, phone)) return;

  const subjectCheck = validateSubject(subjectRaw);
  if (!subjectCheck.ok) {
    return res.status(400).json({ error: subjectCheck.error });
  }

  const bodyCheck = validateSupportBody(body);
  if (!bodyCheck.ok) {
    return res.status(400).json({ error: bodyCheck.error });
  }

  const userId = req.userSession.userId;

  try {
    const client = await db.pool.connect();
    try {
      await client.query('BEGIN');

      const ticketResult = await client.query(
        `
        INSERT INTO support_tickets (user_id, subject, status)
        VALUES ($1, $2, 'new')
        RETURNING id, user_id, subject, status, created_at, updated_at
        `,
        [userId, subjectCheck.subject]
      );
      const ticket = ticketResult.rows[0];

      await client.query(
        `
        INSERT INTO support_messages (ticket_id, author_role, body)
        VALUES ($1, 'user', $2)
        `,
        [ticket.id, bodyCheck.text]
      );

      await client.query('COMMIT');

      res.status(201).json({
        ticket: mapTicketRow({
          ...ticket,
          last_message: bodyCheck.text,
          last_message_at: ticket.created_at,
          unread_for_user: 0,
          unread_for_admin: 1,
        }),
      });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    const message = String(error?.message ?? error);
    if (error?.code === '42P01') {
      return res.status(503).json({
        error: 'База данных не обновлена: выполните migrate_support.sql на сервере (VNC)',
      });
    }
    res.status(500).json({ error: message });
  }
});

router.get('/tickets', requireUserSession, async (req, res) => {
  const { phone } = req.query;
  if (!ensureSessionPhone(req, res, phone)) return;

  const userId = req.userSession.userId;

  try {
    const result = await db.query(
      `
      SELECT
        t.id,
        t.subject,
        t.status,
        t.created_at,
        t.updated_at,
        lm.body AS last_message,
        lm.created_at AS last_message_at,
        ${unreadForUserSelect}
      FROM support_tickets t
      LEFT JOIN LATERAL (
        SELECT body, created_at
        FROM support_messages
        WHERE ticket_id = t.id
        ORDER BY created_at DESC
        LIMIT 1
      ) lm ON TRUE
      WHERE t.user_id = $1
      ORDER BY t.updated_at DESC
      `,
      [userId]
    );

    res.json({ items: result.rows.map(mapTicketRow) });
  } catch (error) {
    res.status(500).json({ error: supportReadsDbError(error) });
  }
});

// GET /api/support/unread-summary?phone=
router.get('/unread-summary', requireUserSession, async (req, res) => {
  const { phone } = req.query;
  if (!ensureSessionPhone(req, res, phone)) return;

  const userId = req.userSession.userId;

  try {
    const result = await db.query(
      `
      SELECT COUNT(*)::int AS total_unread
      FROM support_messages sm
      JOIN support_tickets t ON t.id = sm.ticket_id
      LEFT JOIN support_ticket_reads str
        ON str.ticket_id = sm.ticket_id
       AND str.reader_role = 'user'
       AND str.reader_id = $1
      WHERE t.user_id = $1
        AND sm.author_role = 'admin'
        AND sm.created_at > COALESCE(str.last_read_at, TIMESTAMPTZ '1970-01-01')
      `,
      [userId]
    );

    res.json({ total_unread: result.rows[0]?.total_unread ?? 0 });
  } catch (error) {
    res.status(500).json({ error: supportReadsDbError(error) });
  }
});

router.get('/tickets/:id/messages', requireUserSession, async (req, res) => {
  const { phone } = req.query;
  if (!ensureSessionPhone(req, res, phone)) return;

  const userId = req.userSession.userId;
  const ticketId = req.params.id;

  try {
    const ticket = await getTicketForUser(ticketId, userId);
    if (!ticket) {
      return res.status(404).json({ error: 'Обращение не найдено' });
    }

    const messages = await fetchMessages(ticketId);
    res.json({
      ticket: mapTicketRow({ ...ticket, last_message: null, last_message_at: ticket.updated_at }),
      messages,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/support/tickets/:id/read { phone }
router.post('/tickets/:id/read', requireUserSession, async (req, res) => {
  const { phone } = req.body ?? {};
  if (!ensureSessionPhone(req, res, phone)) return;

  const userId = req.userSession.userId;
  const ticketId = req.params.id;

  try {
    const ticket = await getTicketForUser(ticketId, userId);
    if (!ticket) {
      return res.status(404).json({ error: 'Обращение не найдено' });
    }

    await markTicketRead(ticketId, 'user', userId);
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ error: supportReadsDbError(error) });
  }
});

router.post('/tickets/:id/messages', requireUserSession, supportMessageLimiter, async (req, res) => {
  const { phone, body } = req.body ?? {};
  if (!ensureSessionPhone(req, res, phone)) return;

  const bodyCheck = validateSupportBody(body);
  if (!bodyCheck.ok) {
    return res.status(400).json({ error: bodyCheck.error });
  }

  const userId = req.userSession.userId;
  const ticketId = req.params.id;

  try {
    const ticket = await getTicketForUser(ticketId, userId);
    if (!ticket) {
      return res.status(404).json({ error: 'Обращение не найдено' });
    }
    if (ticket.status === 'closed') {
      return res.status(400).json({ error: 'Обращение закрыто. Создайте новое.' });
    }

    const client = await db.pool.connect();
    try {
      await client.query('BEGIN');

      const msgResult = await client.query(
        `
        INSERT INTO support_messages (ticket_id, author_role, body)
        VALUES ($1, 'user', $2)
        RETURNING id, ticket_id, author_role, body, created_at
        `,
        [ticketId, bodyCheck.text]
      );

      await client.query(
        `
        UPDATE support_tickets
        SET updated_at = NOW(), status = CASE WHEN status = 'closed' THEN status ELSE 'new' END
        WHERE id = $1
        `,
        [ticketId]
      );

      await client.query('COMMIT');
      res.status(201).json({ message: mapMessageRow(msgResult.rows[0]) });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ─── Админ (обычный Bearer token + super_admin) ─────────────────────────────

router.get('/admin/tickets', ...requireSuperAdminUserSession, async (req, res) => {
  const adminId = req.adminUser.id;

  try {
    const result = await db.query(
      `
      SELECT
        t.id,
        t.subject,
        t.status,
        t.created_at,
        t.updated_at,
        u.name AS user_name,
        u.phone AS user_phone,
        lm.body AS last_message,
        lm.created_at AS last_message_at,
        ${unreadForAdminSelect('$1')}
      FROM support_tickets t
      JOIN users u ON u.id = t.user_id
      LEFT JOIN LATERAL (
        SELECT body, created_at
        FROM support_messages
        WHERE ticket_id = t.id
        ORDER BY created_at DESC
        LIMIT 1
      ) lm ON TRUE
      ORDER BY
        CASE WHEN t.status = 'closed' THEN 1 ELSE 0 END,
        t.updated_at DESC
      LIMIT 200
      `,
      [adminId]
    );

    res.json({ items: result.rows.map(mapTicketRow) });
  } catch (error) {
    res.status(500).json({ error: supportReadsDbError(error) });
  }
});

// GET /api/support/admin/unread-summary
router.get('/admin/unread-summary', ...requireSuperAdminUserSession, async (req, res) => {
  const adminId = req.adminUser.id;

  try {
    const result = await db.query(
      `
      SELECT COUNT(*)::int AS total_unread
      FROM support_messages sm
      JOIN support_tickets t ON t.id = sm.ticket_id
      LEFT JOIN support_ticket_reads str
        ON str.ticket_id = sm.ticket_id
       AND str.reader_role = 'admin'
       AND str.reader_id = $1
      WHERE sm.author_role = 'user'
        AND sm.created_at > COALESCE(str.last_read_at, TIMESTAMPTZ '1970-01-01')
      `,
      [adminId]
    );

    res.json({ total_unread: result.rows[0]?.total_unread ?? 0 });
  } catch (error) {
    res.status(500).json({ error: supportReadsDbError(error) });
  }
});

router.get('/admin/tickets/:id/messages', ...requireSuperAdminUserSession, async (req, res) => {
  const ticketId = req.params.id;

  try {
    const result = await db.query(
      `
      SELECT
        t.id,
        t.subject,
        t.status,
        t.created_at,
        t.updated_at,
        u.name AS user_name,
        u.phone AS user_phone
      FROM support_tickets t
      JOIN users u ON u.id = t.user_id
      WHERE t.id = $1
      `,
      [ticketId]
    );
    const ticket = result.rows[0];
    if (!ticket) {
      return res.status(404).json({ error: 'Обращение не найдено' });
    }

    const messages = await fetchMessages(ticketId);
    res.json({ ticket: mapTicketRow(ticket), messages });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/support/admin/tickets/:id/read
router.post('/admin/tickets/:id/read', ...requireSuperAdminUserSession, async (req, res) => {
  const ticketId = req.params.id;
  const adminId = req.adminUser.id;

  try {
    const ticket = await getTicketById(ticketId);
    if (!ticket) {
      return res.status(404).json({ error: 'Обращение не найдено' });
    }

    await markTicketRead(ticketId, 'admin', adminId);
    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ error: supportReadsDbError(error) });
  }
});

router.post('/admin/tickets/:id/messages', ...requireSuperAdminUserSession, supportMessageLimiter, async (req, res) => {
  const { body } = req.body ?? {};
  const bodyCheck = validateSupportBody(body);
  if (!bodyCheck.ok) {
    return res.status(400).json({ error: bodyCheck.error });
  }

  const ticketId = req.params.id;
  const adminId = req.adminUser.id;

  try {
    const ticket = await getTicketById(ticketId);
    if (!ticket) {
      return res.status(404).json({ error: 'Обращение не найдено' });
    }
    if (ticket.status === 'closed') {
      return res.status(400).json({ error: 'Обращение закрыто' });
    }

    const client = await db.pool.connect();
    try {
      await client.query('BEGIN');

      const msgResult = await client.query(
        `
        INSERT INTO support_messages (ticket_id, author_role, admin_id, body)
        VALUES ($1, 'admin', $2, $3)
        RETURNING id, ticket_id, author_role, body, created_at
        `,
        [ticketId, adminId, bodyCheck.text]
      );

      await client.query(
        `
        UPDATE support_tickets
        SET updated_at = NOW(), status = 'in_progress'
        WHERE id = $1
        `,
        [ticketId]
      );

      await client.query('COMMIT');
      res.status(201).json({ message: mapMessageRow(msgResult.rows[0]) });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.patch('/admin/tickets/:id', ...requireSuperAdminUserSession, async (req, res) => {
  const { status } = req.body ?? {};
  if (!VALID_STATUSES.includes(status)) {
    return res.status(400).json({ error: 'Недопустимый статус' });
  }

  const ticketId = req.params.id;

  try {
    const result = await db.query(
      `
      UPDATE support_tickets
      SET status = $2, updated_at = NOW()
      WHERE id = $1
      RETURNING id, user_id, subject, status, created_at, updated_at
      `,
      [ticketId, status]
    );
    const ticket = result.rows[0];
    if (!ticket) {
      return res.status(404).json({ error: 'Обращение не найдено' });
    }
    res.json({ ticket: mapTicketRow(ticket) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
