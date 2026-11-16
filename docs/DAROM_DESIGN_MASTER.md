# Darom — Warm Soft Glass (MASTER)

Единый премиум-стиль на всех экранах. Референсы: glassmorphism + тёплый крем из ТЗ.

## Токены
- Фон: `#F9F6F0`, ambient `#FFF0E8` / `#E8F5F0`
- Primary `#FF5A36`, Secondary `#2D6A4F`
- Стекло: blur 18, fill 88%, border `#FFFFFF59`
- Карточки: radius 20, shadow `0 4 20 / 4%`

## Компоненты
- `GlassSurface` — карточки, меню, панели
- `MidnightGlowScreen` — фон + ambient пятна
- `ListingTileCard` — glass по умолчанию
- Кнопки: coral + `fabShadow`

## Этап 3 (далее)
Профиль, чаты, add_listing — заменить жёсткие `Border.all(accent)` на glass/тени.