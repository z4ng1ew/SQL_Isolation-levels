SELECT
    visits_stats.name,
    COALESCE(visits_stats.count, 0) + COALESCE(orders_stats.count, 0) AS total_count
FROM
    (
        SELECT
            pzr.name,
            COUNT(*) AS count
        FROM person_visits
            INNER JOIN pizzeria AS pzr ON pzr.id = person_visits.pizzeria_id
        GROUP BY pzr.name
    ) AS visits_stats
    FULL JOIN
    (
        SELECT
            pzr.name,
            COUNT(*) AS count
        FROM person_order
            INNER JOIN menu AS mn ON person_order.menu_id = mn.id
            INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
        GROUP BY pzr.name
    ) AS orders_stats ON visits_stats.name = orders_stats.name
ORDER BY 2 DESC, 1 ASC;

















SELECT
    visits_stats.name,
    -- Берём название пиццерии из подзапроса visits_stats.
    -- ВАЖНО: если пиццерия есть ТОЛЬКО в заказах (orders_stats),
    -- но НЕ в визитах, то visits_stats.name будет NULL.
    -- В текущей базе такого нет, но в общем случае безопаснее писать:
    -- COALESCE(visits_stats.name, orders_stats.name)

    COALESCE(visits_stats.count, 0) + COALESCE(orders_stats.count, 0) AS total_count
    -- Складываем количество визитов и заказов.
    -- COALESCE нужен, потому что FULL JOIN может дать NULL:
    --   • Пиццерия есть в визитах, но нет в заказах → orders_stats.count = NULL
    --   • Пиццерия есть в заказах, но нет в визитах → visits_stats.count = NULL
    -- Без COALESCE: 7 + NULL = NULL (потеряем данные!)
    -- С COALESCE:   7 + 0    = 7    (корректно)

FROM
    (
        -- ===== ПОДЗАПРОС 1: считаем визиты по каждой пиццерии =====
        SELECT
            pzr.name,
            -- Название пиццерии из справочника pizzeria

            COUNT(*) AS count
            -- Считаем количество строк в каждой группе = количество визитов

        FROM person_visits
            -- Таблица-журнал посещений (содержит person_id, pizzeria_id, visit_date)

            INNER JOIN pizzeria AS pzr ON pzr.id = person_visits.pizzeria_id
            -- Соединяем с таблицей pizzeria, чтобы получить название.
            -- INNER JOIN: берём только те визиты, у которых есть совпадение в pizzeria.
            -- (по факту — все, т.к. pizzeria_id — внешний ключ)

        GROUP BY pzr.name
        -- Группируем по названию пиццерии.
        -- Все строки с одинаковым pzr.name схлопываются в одну,
        -- а COUNT(*) показывает, сколько их было.

    ) AS visits_stats
    -- Даём подзапросу псевдоним visits_stats.
    -- Теперь это «виртуальная таблица» с двумя столбцами: name и count.
    -- Пример содержимого:
    --   name        | count
    --   Dominos     | 7
    --   DinoPizza   | 4
    --   Pizza Hut   | 4
    --   ...         | ...

    FULL JOIN
    -- FULL JOIN (полное соединение) — берём ВСЕ строки из ОБЕИХ сторон.
    -- Три сценария:
    --   1. Пиццерия есть в визитах И в заказах → обе стороны заполнены
    --   2. Пиццерия есть ТОЛЬКО в визитах → orders_stats.* = NULL
    --   3. Пиццерия есть ТОЛЬКО в заказах → visits_stats.* = NULL
    --
    -- Почему не INNER JOIN? — потерял бы сценарии 2 и 3.
    -- Почему не LEFT JOIN?  — потерял бы сценарий 3.

    (
        -- ===== ПОДЗАПРОС 2: считаем заказы по каждой пиццерии =====
        SELECT
            pzr.name,
            -- Название пиццерии

            COUNT(*) AS count
            -- Количество заказов

        FROM person_order
            -- Таблица-журнал заказов (содержит person_id, menu_id, order_date)

            INNER JOIN menu AS mn ON person_order.menu_id = mn.id
            -- Первый JOIN: person_order → menu.
            -- Нужен, потому что person_order хранит menu_id, а не pizzeria_id.
            -- Через menu мы получим pizzeria_id.

            INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
            -- Второй JOIN: menu → pizzeria.
            -- Теперь у нас есть название пиццерии.
            --
            -- Цепочка: person_order → menu → pizzeria
            -- (для визитов было проще: person_visits → pizzeria напрямую)

        GROUP BY pzr.name
        -- Группируем по названию пиццерии

    ) AS orders_stats
    -- Псевдоним подзапроса. Виртуальная таблица: name и count.
    -- Пример:
    --   name        | count
    --   Dominos     | 6
    --   Best Pizza  | 5
    --   DinoPizza   | 5
    --   ...         | ...

    ON visits_stats.name = orders_stats.name
    -- Условие соединения FULL JOIN:
    -- связываем две виртуальные таблицы по названию пиццерии.
    -- Если название совпадает — строки объединяются в одну.
    -- Если нет совпадения — одна сторона заполняется NULL.

ORDER BY 2 DESC, 1 ASC;
    -- Финальная сортировка результата:
    --   2 DESC — по второму столбцу (total_count) по убыванию (сначала самые популярные)
    --   1 ASC  — при равенстве total_count — по первому столбцу (name) по алфавиту
    --
    -- Результат:
    --   name        | total_count
    --   Dominos     | 13           (7 визитов + 6 заказов)
    --   DinoPizza   | 9            (4 визита  + 5 заказов)
    --   Best Pizza  | 8            (3 визита  + 5 заказов)
    --   Pizza Hut   | 8            (4 визита  + 4 заказа)
    --   Papa Johns  | 5            (3 визита  + 2 заказа)
    --   DoDo Pizza  | 1            (1 визит   + 0 заказов ← COALESCE сработал!)





















## Возможные вопросы на защите

**В: Зачем FULL JOIN, а не INNER JOIN или LEFT JOIN?**
О: Три типа JOIN дают разные результаты:

- `INNER JOIN` — только пиццерии, которые есть **в обеих** таблицах (и визиты, и заказы). Потеряем DoDo Pizza (у неё есть визиты, но нет заказов).
- `LEFT JOIN` — все пиццерии из левого подзапроса (визиты) + совпадения из правого (заказы). Потеряем пиццерии, у которых есть заказы, но нет визитов.
- `FULL JOIN` — **все** пиццерии из обоих подзапросов. Ничего не теряем. Именно это нужно по заданию.

**В: Зачем COALESCE?**
О: При `FULL JOIN` одна сторона может быть NULL. Арифметика с NULL заразна: `7 + NULL = NULL`. `COALESCE(NULL, 0)` превращает NULL в 0, и сложение работает корректно: `7 + 0 = 7`.

**В: Почему `visits_stats.name`, а не `orders_stats.name`?**
О: Хороший вопрос. Если пиццерия есть **только** в заказах, но не в визитах — `visits_stats.name` будет NULL, и мы потеряем имя. Безопаснее писать `COALESCE(visits_stats.name, orders_stats.name)`. В текущей базе все пиццерии имеют хотя бы один визит, поэтому проблемы нет, но в общем случае это баг.

**В: Зачем подзапросы? Нельзя ли проще?**
О: Можно. Альтернатива — `UNION ALL` + внешний `GROUP BY` с `SUM` (см. ниже). Подзапросы с `FULL JOIN` — более явный подход: сначала считаем визиты отдельно, заказы отдельно, потом объединяем.

**В: Почему `COUNT(*)` в подзапросах, а не в основном SELECT?**
О: Потому что `GROUP BY` происходит внутри подзапросов (по `pzr.name`). Основной SELECT работает уже с агрегированными результатами — он просто складывает два числа.

**В: Связан ли этот запрос с Ex02?**
О: Да. Задание говорит: «Можно использовать внутренний запрос из Задания 02 без ограничений на количество строк». То есть подзапросы здесь — те же, что в Ex02, но без `ORDER BY` и `LIMIT`. Мы берём **все** пиццерии, а не топ-3.

**В: Что если добавится новая пиццерия без визитов и без заказов?**
О: Она не появится в результате. Подзапросы строятся на `person_visits` и `person_order` через `INNER JOIN` с `pizzeria`. Если пиццерия ни разу не посещена и не имеет заказов — она не попадёт ни в один подзапрос, и `FULL JOIN` её не найдёт. Чтобы включить такие пиццерии, нужно начинать с таблицы `pizzeria` и делать `LEFT JOIN` на визиты и заказы.

**В: Что значит `ORDER BY 2 DESC, 1 ASC`?**
О: Сортировка по второму столбцу (`total_count`) по убыванию — самые популярные пиццерии первыми. При равном `total_count` — по первому столбцу (`name`) по алфавиту.

---

## Альтернативные варианты

```sql
-- Вариант 1: UNION ALL + SUM (проще, без FULL JOIN)
-- Объединяем все строки в одну кучу, потом группируем и суммируем
SELECT
    name,
    SUM(count) AS total_count
FROM (
    SELECT pzr.name, COUNT(*) AS count
    FROM person_visits
        INNER JOIN pizzeria AS pzr ON pzr.id = person_visits.pizzeria_id
    GROUP BY pzr.name

    UNION ALL
    -- UNION ALL обязателен! UNION удалил бы строки,
    -- где name и count случайно совпали в обоих подзапросах.

    SELECT pzr.name, COUNT(*) AS count
    FROM person_order
        INNER JOIN menu AS mn ON person_order.menu_id = mn.id
        INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
    GROUP BY pzr.name
) AS combined
GROUP BY name
ORDER BY total_count DESC, name ASC;
-- Преимущество: нет FULL JOIN, нет COALESCE — проще читать.
-- SUM автоматически обрабатывает случай, когда пиццерия
-- встречается только в одном подзапросе (сумма одного числа = оно само).


-- Вариант 2: исправленная версия с COALESCE для name
-- (защита от случая, когда пиццерия есть только в заказах)
SELECT
    COALESCE(visits_stats.name, orders_stats.name) AS name,
    -- Берём имя из той стороны, где оно НЕ NULL.
    -- Если пиццерия есть в визитах — берём оттуда.
    -- Если только в заказах — берём из orders_stats.

    COALESCE(visits_stats.count, 0) + COALESCE(orders_stats.count, 0) AS total_count
FROM
    (
        SELECT pzr.name, COUNT(*) AS count
        FROM person_visits
            INNER JOIN pizzeria AS pzr ON pzr.id = person_visits.pizzeria_id
        GROUP BY pzr.name
    ) AS visits_stats
    FULL JOIN
    (
        SELECT pzr.name, COUNT(*) AS count
        FROM person_order
            INNER JOIN menu AS mn ON person_order.menu_id = mn.id
            INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
        GROUP BY pzr.name
    ) AS orders_stats ON visits_stats.name = orders_stats.name
ORDER BY 2 DESC, 1 ASC;


-- Вариант 3: CTE (WITH) — вынести подзапросы для читаемости
WITH visits_stats AS (
    SELECT pzr.name, COUNT(*) AS count
    FROM person_visits
        INNER JOIN pizzeria AS pzr ON pzr.id = person_visits.pizzeria_id
    GROUP BY pzr.name
),
orders_stats AS (
    SELECT pzr.name, COUNT(*) AS count
    FROM person_order
        INNER JOIN menu AS mn ON person_order.menu_id = mn.id
        INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
    GROUP BY pzr.name
)
SELECT
    COALESCE(vs.name, os.name) AS name,
    COALESCE(vs.count, 0) + COALESCE(os.count, 0) AS total_count
FROM visits_stats AS vs
    FULL JOIN orders_stats AS os ON vs.name = os.name
ORDER BY 2 DESC, 1 ASC;
-- CTE = Common Table Expression (обобщённое табличное выражение).
-- WITH ... AS (...) — создаёт именованные «временные таблицы».
-- Логика та же, но запрос читается сверху вниз, а не изнутри наружу.


-- Вариант 4: начинаем с таблицы pizzeria (включает даже пиццерии без активности)
SELECT
    pzr.name,
    COALESCE(vs.count, 0) + COALESCE(os.count, 0) AS total_count
FROM pizzeria AS pzr
    LEFT JOIN (
        SELECT pizzeria_id, COUNT(*) AS count
        FROM person_visits
        GROUP BY pizzeria_id
    ) AS vs ON vs.pizzeria_id = pzr.id
    LEFT JOIN (
        SELECT mn.pizzeria_id, COUNT(*) AS count
        FROM person_order
            INNER JOIN menu AS mn ON person_order.menu_id = mn.id
        GROUP BY mn.pizzeria_id
    ) AS os ON os.pizzeria_id = pzr.id
ORDER BY 2 DESC, 1 ASC;
-- Начинаем с полного справочника pizzeria.
-- LEFT JOIN гарантирует: даже если у пиццерии 0 визитов
-- и 0 заказов — она всё равно появится в результате (с total_count = 0).
-- Группировка по pizzeria_id (integer) вместо name (string) —
-- теоретически быстрее.
-- В текущей базе результат тот же, но этот подход устойчивее.
```

Для задания лучше всего **основной вариант** (проходит проверку) или **вариант 1 (UNION ALL + SUM)** — он проще и элегантнее. На защите стоит упомянуть **вариант 2** как исправление потенциального бага с `visits_stats.name`, и **вариант 4**, если спросят «а что если пиццерия вообще без активности?».




