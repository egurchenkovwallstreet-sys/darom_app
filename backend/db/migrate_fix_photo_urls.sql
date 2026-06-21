-- Исправить старые URL фото (localhost → боевой домен) и синхронизировать photos_count
-- cat backend/db/migrate_fix_photo_urls.sql | docker exec -i darom_db psql -U darom -d darom

UPDATE listing_photos
SET url = 'https://darom-app.online/api/photos/listings/' || substring(url from '([^/?#]+)$')
WHERE url ~ '/api/photos/listings/';

UPDATE listings l
SET photos_count = (
  SELECT COUNT(*)::int FROM listing_photos p WHERE p.listing_id = l.id
);
