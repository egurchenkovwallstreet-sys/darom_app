-- Дополнительные индексы для geo-запросов (nearby/map).
-- GIST на location уже есть в init.sql — IF NOT EXISTS безопасен при повторном запуске.

CREATE INDEX IF NOT EXISTS listings_location_idx ON listings USING GIST (location);

CREATE INDEX IF NOT EXISTS listings_active_geo_idx
  ON listings (status)
  WHERE status IN ('active', 'reserved');
