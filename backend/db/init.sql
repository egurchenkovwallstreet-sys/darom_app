-- Схема БД «Даром» (этап 3, шаг 1)
-- Выполняется автоматически при первом запуске Docker-контейнера.

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone         VARCHAR(20) NOT NULL UNIQUE,
  name          VARCHAR(100) NOT NULL,
  donor_level   VARCHAR(50) NOT NULL DEFAULT 'Новичок',
  rating        NUMERIC(2, 1) NOT NULL DEFAULT 5.0 CHECK (rating >= 1 AND rating <= 5),
  is_founder    BOOLEAN NOT NULL DEFAULT FALSE,
  items_given   INTEGER NOT NULL DEFAULT 0,
  items_taken   INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS listings (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title         VARCHAR(200) NOT NULL,
  description   TEXT NOT NULL,
  category      VARCHAR(50) NOT NULL,
  subcategory   VARCHAR(50) NOT NULL,
  photos_count  INTEGER NOT NULL DEFAULT 0 CHECK (photos_count >= 0),
  status        VARCHAR(20) NOT NULL DEFAULT 'active'
                CHECK (status IN ('active', 'reserved', 'given', 'hidden')),
  reserved_by_user_id UUID REFERENCES users(id),
  reserved_until    TIMESTAMPTZ,
  location      GEOGRAPHY(POINT, 4326) NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS listings_category_idx ON listings (category, subcategory);
CREATE INDEX IF NOT EXISTS listings_status_idx ON listings (status);
CREATE INDEX IF NOT EXISTS listings_location_idx ON listings USING GIST (location);

-- Тестовые данные (пока Flutter использует mock — потом заменим на API).
INSERT INTO users (phone, name, donor_level, rating)
VALUES
  ('+79001112233', 'Анна', 'Активный даритель', 4.7),
  ('+79004445566', 'Игорь', 'Новичок', 4.5),
  ('+79007778899', 'Мария', 'Щедрый', 4.9)
ON CONFLICT (phone) DO NOTHING;

INSERT INTO listings (user_id, title, description, category, subcategory, photos_count, location)
SELECT
  u.id,
  v.title,
  v.description,
  v.category,
  v.subcategory,
  v.photos_count,
  ST_SetSRID(ST_MakePoint(v.lng, v.lat), 4326)::geography
FROM users u
JOIN (
  VALUES
    ('+79001112233', 'Куртка мужская L', 'Лёгкая демисезонная куртка, без дыр и пятен.', 'Одежда', 'Мужская', 3, 37.6173, 55.7558),
    ('+79004445566', 'Джинсы 32 размер', 'Классические синие джинсы, носили один сезон.', 'Одежда', 'Мужская', 2, 37.6300, 55.7600),
    ('+79007778899', 'Свитер шерстяной', 'Тёплый свитер, цвет тёмно-синий.', 'Одежда', 'Мужская', 2, 37.6050, 55.7500)
) AS v(phone, title, description, category, subcategory, photos_count, lng, lat)
  ON u.phone = v.phone
WHERE NOT EXISTS (
  SELECT 1 FROM listings l
  WHERE l.title = v.title AND l.category = v.category AND l.subcategory = v.subcategory
);
