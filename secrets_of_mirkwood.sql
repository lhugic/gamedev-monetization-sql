/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Васильев Арсений
 * Дата: 28.03.2026
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
SELECT
	COUNT(id) AS total_users,
	SUM(payer) AS paying_users,
	SUM(payer) / COUNT(id)::float AS percent
FROM fantasy.users;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
SELECT
	r.race AS race_name,
	SUM(u.payer) AS paying_users,
	COUNT(u.id) AS total_users,
	SUM(u.payer) / COUNT(u.id)::float AS percent
FROM fantasy.users AS u
LEFT JOIN fantasy.race AS r USING(race_id)
GROUP BY r.race
ORDER BY percent DESC;

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
SELECT
	COUNT(amount) AS total_events,
	SUM(amount) AS sum_amount,
	MIN(amount) AS min_amount,
	MAX(amount) AS max_amount,
	AVG(amount) AS avg_amount,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount,
	STDDEV(amount) AS stddev_amount
FROM fantasy.events
--добавил статистику без нулевых покупок
UNION
SELECT
	COUNT(amount) AS total_events,
	SUM(amount) AS sum_amount,
	MIN(amount) AS min_amount,
	MAX(amount) AS max_amount,
	AVG(amount) AS avg_amount,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount,
	STDDEV(amount) AS stddev_amount
FROM fantasy.events
WHERE amount > 0;

-- 2.2: Аномальные нулевые покупки:
SELECT
	(SELECT COUNT(*)
	FROM fantasy.events
	WHERE amount = 0) AS count_zero,
	COUNT(*) AS count_total,
	(SELECT COUNT(*)
	FROM fantasy.events
	WHERE amount = 0) / COUNT(*)::float AS percent
FROM fantasy.events;

-- 2.3: Популярные эпические предметы:
SELECT
	i.game_items AS item_name,
	COUNT(e.transaction_id) AS count_events,
	COUNT(e.transaction_id) /
		(SELECT COUNT(*)
		FROM fantasy.events
		WHERE amount > 0)::float AS percent_item,
	COUNT(DISTINCT e.id) AS count_users,
	COUNT(DISTINCT e.id) /
		(SELECT COUNT(DISTINCT id)
		FROM fantasy.events
		WHERE amount > 0)::float AS percent_users
FROM fantasy.events AS e
LEFT JOIN fantasy.items AS i USING(item_code)
WHERE e.amount > 0
GROUP BY i.game_items
ORDER BY percent_users DESC;

-- Часть 2. Решение ad hoc-задачи
-- Задача: Зависимость активности игроков от расы персонажа:
WITH stats AS (
    SELECT
        id,
        COUNT(*) AS count_events,
        SUM(amount) AS total_amount
    FROM fantasy.events
    WHERE amount > 0
    GROUP BY id
)
SELECT
    r.race AS race_name,
    COUNT(u.id) AS total_users,
    COUNT(s.id) AS paying_users,
    ROUND((COUNT(s.id)::numeric / COUNT(u.id)), 4) AS users_percent,
    ROUND((SUM(CASE WHEN u.payer = 1 AND s.id IS NOT NULL THEN 1 ELSE 0 END)::numeric / COUNT(s.id)), 4) AS payer_percent,
    ROUND(AVG(s.count_events)::numeric, 2) AS avg_events,
    ROUND((SUM(s.total_amount)::numeric / SUM(s.count_events)), 2) AS avg_amount,
    ROUND(AVG(s.total_amount)::numeric, 2) AS avg_total_amount
FROM fantasy.users u
LEFT JOIN fantasy.race r ON u.race_id = r.race_id
LEFT JOIN stats s ON u.id = s.id
GROUP BY r.race_id, r.race
ORDER BY r.race;