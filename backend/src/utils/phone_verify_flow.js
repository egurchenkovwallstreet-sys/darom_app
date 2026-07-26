const db = require('../db/pool');
const config = require('../config');
const {
  STATUS: MOBILE_ID_STATUS,
  canUseMobileId,
  sendMobileIdAuth,
  verifyMobileIdOtp,
  fetchMobileIdStatus,
  isTerminalStatus,
  statusLabel,
} = require('../services/mobile_id_service');
const {
  canUsePlusofonFlash,
  sendPlusofonFlashCall,
  checkPlusofonFlashPin,
  FLASH_CALL_HINT,
} = require('../services/plusofon_flash_service');

function resolveVerifyProvider() {
  const preferred = String(config.verifyProvider || 'auto').toLowerCase();
  if (preferred === 'mobile_id') {
    return canUseMobileId() ? 'mobile_id' : canUsePlusofonFlash() ? 'flash_call' : 'sms';
  }
  if (preferred === 'plusofon' || preferred === 'flash_call') {
    return canUsePlusofonFlash() ? 'flash_call' : canUseMobileId() ? 'mobile_id' : 'sms';
  }
  if (canUsePlusofonFlash()) return 'flash_call';
  if (canUseMobileId()) return 'mobile_id';
  return 'sms';
}

async function insertVerifySession({
  provider,
  aeroId,
  userId,
  accountPhone,
  verifyPhone,
  status,
  purpose,
  partnerCode,
  flashKey,
  flashPin,
}) {
  const inserted = await db.query(
    `
    INSERT INTO mobile_id_sessions (
      aero_id, user_id, account_phone, verify_phone, status,
      partner_activation_code, purpose, provider, flash_key, flash_pin
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    RETURNING id
    `,
    [
      aeroId ?? null,
      userId ?? null,
      accountPhone,
      verifyPhone,
      status ?? 0,
      partnerCode ?? null,
      purpose,
      provider,
      flashKey ?? null,
      flashPin ?? null,
    ]
  );
  return inserted.rows[0];
}

async function startPhoneVerification({
  verifyPhone,
  accountPhone,
  userId,
  purpose,
  partnerCode,
}) {
  const provider = resolveVerifyProvider();

  if (provider === 'flash_call') {
    const flash = await sendPlusofonFlashCall(verifyPhone);
    const row = await insertVerifySession({
      provider: 'flash_call',
      userId,
      accountPhone,
      verifyPhone,
      purpose,
      partnerCode,
      flashKey: flash.key,
      flashPin: flash.mock ? flash.pin : null,
    });

    const body = {
      ok: true,
      mode: 'flash_call',
      phone: verifyPhone,
      session_token: row.id,
      mock: flash.mock,
      hint: FLASH_CALL_HINT,
    };
    if (flash.mock && flash.pin) {
      body.debug_code = flash.pin;
    }
    if (partnerCode) {
      body.partner_activation_code = partnerCode;
    }
    return body;
  }

  if (provider === 'mobile_id') {
    const aeroData = await sendMobileIdAuth(verifyPhone);
    const row = await insertVerifySession({
      provider: 'mobile_id',
      aeroId: aeroData.id,
      userId,
      accountPhone,
      verifyPhone,
      status: Number(aeroData.status) || 0,
      purpose,
      partnerCode,
    });

    const status = Number(aeroData.status) || 0;
    const body = {
      ok: true,
      mode: 'mobile_id',
      phone: verifyPhone,
      session_token: row.id,
      status,
      status_label: statusLabel(status),
      mock: false,
      hint:
        'На телефон может прийти запрос «Подтвердить» (SIM-PUSH) или SMS с кодом — это нормально.',
    };
    if (partnerCode) {
      body.partner_activation_code = partnerCode;
    }
    return body;
  }

  return { ok: false, mode: 'sms' };
}

async function fetchVerifySession(sessionToken, accountPhone, purpose = 'active_verify') {
  const { normalizePhone } = require('./phone');
  const result = await db.query(
    `
    SELECT id, aero_id, user_id, account_phone, verify_phone, status,
           partner_activation_code, purpose, provider, flash_key, flash_pin, created_at
    FROM mobile_id_sessions
    WHERE id = $1 AND account_phone = $2 AND purpose = $3
    `,
    [sessionToken, normalizePhone(accountPhone), purpose]
  );
  return result.rows[0] ?? null;
}

async function syncMobileIdSessionStatus(sessionRow) {
  if (!sessionRow || sessionRow.provider === 'flash_call') {
    return sessionRow?.status ?? null;
  }

  let status = Number(sessionRow.status);
  if (status === MOBILE_ID_STATUS.NEED_OTP || isTerminalStatus(status)) {
    return status;
  }

  try {
    const remote = await fetchMobileIdStatus(sessionRow.aero_id);
    status = Number(remote.status);
    await db.query(
      'UPDATE mobile_id_sessions SET status = $2, updated_at = NOW() WHERE id = $1',
      [sessionRow.id, status]
    );
  } catch (_) {}

  return status;
}

function buildPollPayload(sessionRow, status) {
  if (sessionRow.provider === 'flash_call') {
    return {
      status: 0,
      status_label: 'waiting_pin',
      needs_otp: true,
      verified: false,
      failed: false,
    };
  }

  const numericStatus = Number(status);
  return {
    status: numericStatus,
    status_label: statusLabel(numericStatus),
    needs_otp: numericStatus === MOBILE_ID_STATUS.NEED_OTP,
    verified: numericStatus === MOBILE_ID_STATUS.SUCCESS,
    failed: [MOBILE_ID_STATUS.FAILED, MOBILE_ID_STATUS.ERROR].includes(numericStatus),
  };
}

async function confirmVerifyCode(session, code) {
  const trimmedCode = String(code ?? '').trim();

  if (session.provider === 'flash_call') {
    if (!/^\d{4}$/.test(trimmedCode)) {
      return { ok: false, status: 400, error: 'Введите 4 цифры номера входящего звонка' };
    }

    if (session.flash_pin && session.flash_pin === trimmedCode) {
      return { ok: true };
    }

    try {
      await checkPlusofonFlashPin({ key: session.flash_key, pin: trimmedCode });
      return { ok: true };
    } catch (error) {
      const message = error.message || 'Неверный код';
      if (message.toLowerCase().includes('not found') || message.includes('не найден')) {
        return { ok: false, status: 400, error: 'Код истёк. Запросите звонок ещё раз.' };
      }
      return { ok: false, status: 400, error: 'Неверный код. Проверьте последние 4 цифры номера.' };
    }
  }

  if (!/^\d{4,8}$/.test(trimmedCode)) {
    return { ok: false, status: 400, error: 'Введите код из SMS' };
  }

  try {
    await verifyMobileIdOtp({ aeroId: session.aero_id, code: trimmedCode });
    const status = await syncMobileIdSessionStatus(session);
    if (Number(status) !== MOBILE_ID_STATUS.SUCCESS) {
      return { ok: false, status: 400, error: 'Код не принят. Попробуйте ещё раз' };
    }
    return { ok: true };
  } catch (error) {
    const message = error.message || 'Ошибка подтверждения';
    if (message.includes('invalid otp')) {
      return { ok: false, status: 400, error: 'Неверный код из SMS' };
    }
    throw error;
  }
}

module.exports = {
  MOBILE_ID_STATUS,
  resolveVerifyProvider,
  startPhoneVerification,
  fetchVerifySession,
  syncMobileIdSessionStatus,
  buildPollPayload,
  confirmVerifyCode,
  FLASH_CALL_HINT,
};
