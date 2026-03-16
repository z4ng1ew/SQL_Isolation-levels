(
    SELECT
        pzr.name,
        COUNT(*) AS count,
        'visit' AS action_type
    FROM person_visits
        INNER JOIN pizzeria AS pzr ON pzr.id = person_visits.pizzeria_id
    GROUP BY pzr.name
    ORDER BY 2 DESC
    LIMIT 3
)
UNION
(
    SELECT
        pzr.name,
        COUNT(*) AS count,
        'order' AS action_type
    FROM person_order
        INNER JOIN menu AS mn ON person_order.menu_id = mn.id
        INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
    GROUP BY pzr.name
    ORDER BY 2 DESC
    LIMIT 3
)
ORDER BY 3, 2 DESC;








(
    -- ===== ПОДЗАПРОС 1: топ-3 пиццерии по ВИЗИТАМ =====
    -- Скобки обязательны! Без них ORDER BY и LIMIT
    -- применились бы ко всему UNION, а не к этому подзапросу отдельно.

    SELECT
        pzr.name,
        -- Название пиццерии из справочника pizzeria

        COUNT(*) AS count,
        -- Количество визитов в эту пиццерию.
        -- COUNT(*) считает все строки в каждой группе.

        'visit' AS action_type
        -- Литеральная (буквальная) строка 'visit' — одинаковая для всех строк.
        -- Это «метка», чтобы в итоговом результате отличить
        -- откуда строка: из визитов или из заказов.
        -- Не берётся из таблицы — просто вручную заданная константа.

    FROM person_visits
        -- Журнал посещений: каждая строка = один визит в пиццерию

        INNER JOIN pizzeria AS pzr ON pzr.id = person_visits.pizzeria_id
        -- Соединяем с pizzeria, чтобы получить название (name).
        -- person_visits хранит только pizzeria_id (числовой ключ),
        -- а нам нужно человекочитаемое имя.

    GROUP BY pzr.name
        -- Группируем по названию пиццерии.
        -- Все визиты в «Dominos» схлопнутся в одну строку,
        -- а COUNT(*) покажет, сколько их было (например, 7).

    ORDER BY 2 DESC
        -- Сортируем по второму столбцу (count) по убыванию.
        -- Сначала самые посещаемые пиццерии.

    LIMIT 3
        -- Берём только первые 3 строки = топ-3 по визитам.
        -- LIMIT отрабатывает ПОСЛЕ ORDER BY, поэтому
        -- мы гарантированно получаем тройку лидеров.
        --
        -- Результат этого подзапроса:
        --   name       | count | action_type
        --   Dominos    | 7     | visit
        --   DinoPizza  | 4     | visit
        --   Pizza Hut  | 4     | visit
)

UNION
-- Объединяет результаты двух SELECT в один набор строк.
-- Требования к UNION:
--   1. Оба SELECT должны возвращать ОДИНАКОВОЕ количество столбцов
--   2. Типы столбцов должны быть совместимы
--
-- UNION vs UNION ALL:
--   UNION     — удаляет полные дубликаты (строки, где ВСЕ столбцы совпадают)
--   UNION ALL — оставляет всё как есть (быстрее)
-- Здесь дубликатов не будет: action_type разный ('visit' vs 'order'),
-- поэтому оба варианта дают одинаковый результат.

(
    -- ===== ПОДЗАПРОС 2: топ-3 пиццерии по ЗАКАЗАМ =====

    SELECT
        pzr.name,
        -- Название пиццерии

        COUNT(*) AS count,
        -- Количество заказов в этой пиццерии

        'order' AS action_type
        -- Метка 'order' — отличает эти строки от визитов

    FROM person_order
        -- Журнал заказов: каждая строка = один заказ пиццы

        INNER JOIN menu AS mn ON person_order.menu_id = mn.id
        -- Первый JOIN: person_order → menu.
        -- person_order хранит menu_id, а НЕ pizzeria_id.
        -- Через таблицу menu мы доберёмся до pizzeria_id.

        INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
        -- Второй JOIN: menu → pizzeria.
        -- Теперь у нас есть название пиццерии.
        --
        -- Почему два JOIN, а не один (как в визитах)?
        --   person_visits → pizzeria       (прямая связь через pizzeria_id)
        --   person_order  → menu → pizzeria (непрямая: сначала узнаём что заказали,
        --                                    потом — в какой пиццерии это продаётся)

    GROUP BY pzr.name
        -- Группируем по названию пиццерии

    ORDER BY 2 DESC
        -- Сортируем по количеству заказов (убывание)

    LIMIT 3
        -- Топ-3 по заказам.
        --
        -- Результат этого подзапроса:
        --   name        | count | action_type
        --   Dominos     | 6     | order
        --   Best Pizza  | 5     | order
        --   DinoPizza   | 5     | order
)

ORDER BY 3, 2 DESC;
-- Финальная сортировка ОБЪЕДИНЁННОГО результата (после UNION).
-- Этот ORDER BY применяется ко ВСЕМ 6 строкам (3 + 3).
--
--   3     — третий столбец (action_type), по возрастанию (ASC по умолчанию).
--           'order' < 'visit' в алфавитном порядке,
--           поэтому сначала идут заказы, потом визиты.
--
--   2 DESC — при одинаковом action_type сортируем
--            по второму столбцу (count) по убыванию.
--
-- Итоговый результат:
--   name        | count | action_type
--   -----------------------------------
--   Dominos     | 6     | order        ← сначала order (алфавит)
--   Best Pizza  | 5     | order
--   DinoPizza   | 5     | order
--   Dominos     | 7     | visit        ← потом visit
--   DinoPizza   | 4     | visit
--   Pizza Hut   | 4     | visit
--
-- Обрати внимание: Dominos появляется ДВАЖДЫ —
-- один раз как лидер по заказам (6), второй — по визитам (7).
-- Это нормально: UNION не удалит эти строки,
-- потому что action_type у них разный (не полный дубликат).

















## Возможные вопросы на защите

**В: Зачем скобки вокруг каждого SELECT?**
О: В PostgreSQL без скобок `ORDER BY` и `LIMIT` применятся ко всему `UNION` целиком, а не к каждому подзапросу отдельно. Нам нужен топ-3 **из каждой** категории отдельно — поэтому скобки обязательны. Последний `ORDER BY 3, 2 DESC` уже без скобок — он сортирует финальный объединённый результат.

**В: Почему UNION, а не UNION ALL?**
О: `UNION` удаляет полные дубликаты (строки, где ВСЕ столбцы совпадают). `UNION ALL` оставляет всё. Здесь дубликатов быть не может — третий столбец `action_type` всегда разный (`'visit'` vs `'order'`). Поэтому оба дадут одинаковый результат, но `UNION ALL` чуть быстрее, потому что не тратит время на проверку дубликатов.

**В: Почему для заказов два JOIN, а для визитов — один?**
О: Разная структура связей в базе. `person_visits` хранит `pizzeria_id` напрямую — один JOIN до `pizzeria`. А `person_order` хранит `menu_id`, не `pizzeria_id`. Поэтому цепочка длиннее: `person_order → menu → pizzeria`.

**В: Что значит `ORDER BY 3, 2 DESC`?**
О: Сортировка по двум столбцам. `3` — третий столбец (`action_type`), по возрастанию (ASC по умолчанию). В алфавитном порядке `'order'` < `'visit'`, поэтому заказы идут первыми. `2 DESC` — при одинаковом `action_type` сортируем по второму столбцу (`count`) по убыванию.

**В: Что такое `'visit' AS action_type`?**
О: Это литеральная строка — константа, одинаковая для всех строк. Не берётся из таблицы, а задаётся вручную. Работает как «метка», чтобы в объединённом результате различать, откуда строка: из визитов или заказов.

**В: Может ли одна пиццерия попасть в результат дважды?**
О: Да. Dominos — лидер и по визитам (7), и по заказам (6). Она появляется в обеих «тройках». `UNION` не удалит эти строки, потому что `action_type` у них разный — это не полные дубликаты.

**В: Что если у двух пиццерий одинаковый count на границе топ-3?**
О: `LIMIT 3` жёстко отрежет до трёх строк. Если на третьем и четвёртом месте одинаковый count — четвёртая строка пропадёт. Какая именно из двух попадёт в топ-3 — зависит от внутреннего порядка PostgreSQL (не детерминировано). Для гарантированного поведения нужен дополнительный критерий сортировки, например `ORDER BY 2 DESC, 1 ASC`.

**В: Почему нельзя решить одним запросом без UNION?**
О: Можно, но сложнее. Нужна оконная функция `RANK()` или `ROW_NUMBER()` — см. альтернативу ниже.

---

## Альтернативные варианты

```sql
-- Вариант 1: UNION ALL вместо UNION
-- (быстрее, результат тот же — дубликатов всё равно нет)
(
    SELECT pzr.name, COUNT(*) AS count, 'visit' AS action_type
    FROM person_visits
        INNER JOIN pizzeria AS pzr ON pzr.id = person_visits.pizzeria_id
    GROUP BY pzr.name
    ORDER BY 2 DESC
    LIMIT 3
)
UNION ALL
(
    SELECT pzr.name, COUNT(*) AS count, 'order' AS action_type
    FROM person_order
        INNER JOIN menu AS mn ON person_order.menu_id = mn.id
        INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
    GROUP BY pzr.name
    ORDER BY 2 DESC
    LIMIT 3
)
ORDER BY 3, 2 DESC;


-- Вариант 2: сортировка по именам столбцов
-- (нагляднее при чтении)
(
    SELECT pzr.name, COUNT(*) AS count, 'visit' AS action_type
    FROM person_visits
        INNER JOIN pizzeria AS pzr ON pzr.id = person_visits.pizzeria_id
    GROUP BY pzr.name
    ORDER BY count DESC
    LIMIT 3
)
UNION
(
    SELECT pzr.name, COUNT(*) AS count, 'order' AS action_type
    FROM person_order
        INNER JOIN menu AS mn ON person_order.menu_id = mn.id
        INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
    GROUP BY pzr.name
    ORDER BY count DESC
    LIMIT 3
)
ORDER BY action_type, count DESC;


-- Вариант 3: через CTE (WITH) — вынести подзапросы в именованные блоки
-- CTE = Common Table Expression = обобщённое табличное выражение
-- (более читаемо, логика та же)
WITH top_visits AS (
    SELECT pzr.name, COUNT(*) AS count, 'visit' AS action_type
    FROM person_visits
        INNER JOIN pizzeria AS pzr ON pzr.id = person_visits.pizzeria_id
    GROUP BY pzr.name
    ORDER BY count DESC
    LIMIT 3
),
top_orders AS (
    SELECT pzr.name, COUNT(*) AS count, 'order' AS action_type
    FROM person_order
        INNER JOIN menu AS mn ON person_order.menu_id = mn.id
        INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
    GROUP BY pzr.name
    ORDER BY count DESC
    LIMIT 3
)
SELECT * FROM top_visits
UNION ALL
SELECT * FROM top_orders
ORDER BY action_type, count DESC;


-- Вариант 4: без UNION — через оконную функцию ROW_NUMBER()
-- (продвинутый вариант, показывает знание оконных функций)
SELECT name, count, action_type
FROM (
    SELECT
        name,
        count,
        action_type,
        ROW_NUMBER() OVER (
            PARTITION BY action_type
            ORDER BY count DESC
        ) AS rn
        -- ROW_NUMBER() — присваивает порядковый номер внутри каждой группы.
        -- PARTITION BY action_type — группируем: отдельная нумерация
        --   для 'visit' и отдельная для 'order'.
        -- ORDER BY count DESC — нумеруем от наибольшего count.
    FROM (
        SELECT pzr.name, COUNT(*) AS count, 'visit' AS action_type
        FROM person_visits
            INNER JOIN pizzeria AS pzr ON pzr.id = person_visits.pizzeria_id
        GROUP BY pzr.name

        UNION ALL

        SELECT pzr.name, COUNT(*) AS count, 'order' AS action_type
        FROM person_order
            INNER JOIN menu AS mn ON person_order.menu_id = mn.id
            INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
        GROUP BY pzr.name
    ) AS combined
) AS ranked
WHERE rn <= 3
-- Берём только строки с номером 1, 2, 3 в каждой группе = топ-3.
ORDER BY action_type, count DESC;
-- Преимущество: один проход по данным вместо двух отдельных LIMIT.
-- Недостаток: сложнее читать, оконные функции — тема следующих дней.
```

Для задания лучше всего подходит **основной вариант** или **вариант 3 (CTE)** — оба чистые и читаемые. **Вариант 4** с оконными функциями стоит упомянуть на защите, если спросят «а как без UNION/LIMIT в подзапросах?».



