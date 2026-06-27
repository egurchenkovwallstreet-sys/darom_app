#!/bin/bash
# Все миграции БД на сервере Timeweb (Linux).
# Запуск из папки проекта: bash backend/scripts/run_all_migrations.sh

set -e
cd "$(dirname "$0")/../.."

MIGRATIONS=(
  migrate_4b.sql
  migrate_super_donor.sql
  migrate_4c.sql
  migrate_4d.sql
  migrate_sms.sql
  migrate_photos.sql
  migrate_listing_extra_packs.sql
  migrate_favorites_chats.sql
  migrate_avatar.sql
  migrate_chat_reads.sql
  migrate_pin_auth.sql
  migrate_partners.sql
  migrate_partner_sequential_codes.sql
  migrate_partner_referral_365.sql
  migrate_partner_payout_period.sql
  migrate_admin.sql
  migrate_pickup_tiers.sql
  migrate_payments.sql
  migrate_real_phone_verify.sql
  migrate_mobile_id.sql
  migrate_partner_mobile_id.sql
  migrate_admin_mobile_id.sql
  migrate_fix_photo_urls.sql
  migrate_fix_founders.sql
  migrate_user_sessions.sql
  migrate_pin_lockout.sql
)

for file in "${MIGRATIONS[@]}"; do
  echo ">>> $file"
  docker exec -i darom_db psql -U darom -d darom < "backend/db/$file"
done

echo "Готово: все миграции применены."
