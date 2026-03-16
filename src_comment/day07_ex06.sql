SELECT
    pzr.name,
    COUNT(*) AS count_of_orders,
    ROUND(AVG(mn.price), 2) AS average_price,
    MAX(mn.price) AS max_price,
    MIN(mn.price) AS min_price
FROM person_order
    INNER JOIN menu AS mn ON person_order.menu_id = mn.id
    INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
GROUP BY pzr.name
ORDER BY 1;








SELECT
    pzr.name,
    -- Название пиццерии из справочника pizzeria (через алиас pzr).
    -- Единственный неагрегированный столбец → ОБЯЗАН быть в GROUP BY.

    COUNT(*) AS count_of_orders,
    -- Считает общее количество заказов в этой пиццерии.
    -- Каждая строка в person_order = один заказ одной пиццы.
    -- COUNT(*) считает ВСЕ строки в группе, включая NULL.
    -- AS count_of_orders — псевдоним столбца результата.

    ROUND(AVG(mn.price), 2) AS average_price,
    -- AVG(mn.price) — средняя цена заказанных пицц в этой пиццерии.
    -- AVG = average = среднее арифметическое.
    -- Пример: цены 700, 850, 800 → AVG = (700+850+800)/3 = 783.333...
    --
    -- ROUND(..., 2) — округляет до 2 знаков после запятой: 783.33.
    -- Без ROUND результат был бы 783.3333333333... (много знаков).
    --
    -- ВАЖНО: AVG игнорирует NULL значения.
    -- Если из 5 цен одна NULL, среднее считается по оставшимся 4.

    MAX(mn.price) AS max_price,
    -- Максимальная цена среди всех заказанных пицц в этой пиццерии.
    -- MAX тоже игнорирует NULL.

    MIN(mn.price) AS min_price
    -- Минимальная цена среди всех заказанных пицц в этой пиццерии.
    -- MIN тоже игнорирует NULL.
    --
    -- НЮАНС: это метрики по ЗАКАЗАННЫМ пиццам, а не по всему меню.
    -- Если пицца за 500 руб. есть в меню, но её никто не заказал —
    -- она НЕ попадёт в MIN.

FROM person_order
    -- Журнал заказов: каждая строка = один заказ.
    -- Столбцы: id, person_id, menu_id, order_date.
    -- Цены и названия пиццерий тут НЕТ — нужны JOIN'ы.

    INNER JOIN menu AS mn ON person_order.menu_id = mn.id
    -- Первый JOIN: person_order → menu.
    -- Подтягиваем столбцы из таблицы menu: price, pizza_name, pizzeria_id.
    --
    -- person_order хранит только menu_id (что заказали),
    -- а цена (price) лежит в таблице menu.
    --
    -- ON person_order.menu_id = mn.id — условие связи:
    --   menu_id (FK в person_order) = id (PK в menu).

    INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
    -- Второй JOIN: menu → pizzeria.
    -- Подтягиваем название пиццерии (pzr.name).
    --
    -- Цепочка: person_order → menu → pizzeria
    -- person_order не знает, в какой пиццерии заказ.
    -- menu знает — через pizzeria_id.
    -- pizzeria знает своё имя.
    --
    -- ON mn.pizzeria_id = pzr.id — условие связи:
    --   pizzeria_id (FK в menu) = id (PK в pizzeria).

GROUP BY pzr.name
    -- Группируем по названию пиццерии.
    -- Все заказы в «Dominos» схлопываются в одну строку.
    -- Агрегатные функции (COUNT, AVG, MAX, MIN) считают
    -- значения внутри каждой группы отдельно.
    --
    -- После GROUP BY:
    --   Best Pizza  → 5 заказов, цены: 700, 700, 850, 850, 800
    --   DinoPizza   → 5 заказов, цены: 800, 800, 1000, 1000, 800
    --   Dominos     → 6 заказов, цены: 800, 800, 900, 1000, 1100, 1000
    --   Papa Johns  → 2 заказа, цены: 950, 1000
    --   Pizza Hut   → 4 заказа, цены: 900, 900, 1200, 1500... (пример)

ORDER BY 1;
    -- Сортировка по первому столбцу (pzr.name) в алфавитном порядке.
    -- ASC по умолчанию: Best Pizza → DinoPizza → Dominos → ...
    --
    -- Результат:
    --   name        | count_of_orders | average_price | max_price | min_price
    --   Best Pizza  | 5               | 780           | 850       | 700
    --   DinoPizza   | 5               | 880           | 1000      | 800
    --   Dominos     | 6               | 933.33        | 1100      | 800
    --   Papa Johns  | 2               | 975           | 1000      | 950
    --   Pizza Hut   | 4               | 1125          | 1200      | 900
```

---

## Возможные вопросы на защите

**В: Почему два JOIN, а не один?**
О: Таблица `person_order` не связана с `pizzeria` напрямую. Связь идёт через промежуточную таблицу `menu`:
```
person_order.menu_id → menu.id → menu.pizzeria_id → pizzeria.id
```
Первый JOIN даёт цену (`mn.price`), второй — название пиццерии (`pzr.name`). Убрать любой из них нельзя.

**В: Чем `COUNT(*)` отличается от `COUNT(mn.price)`?**
О: `COUNT(*)` считает **все** строки, даже если какие-то столбцы содержат NULL. `COUNT(mn.price)` считает только строки, где `price` НЕ NULL. В нашей базе цены всегда заполнены — результат одинаковый. Но если бы была пицца с `price = NULL`, `COUNT(*)` посчитала бы её, а `COUNT(mn.price)` — нет.

**В: Зачем ROUND для AVG, но не для MAX и MIN?**
О: `MAX` и `MIN` возвращают **конкретное значение** из данных. Если цены — целые числа (700, 850...), то MAX и MIN тоже целые. `AVG` вычисляет **дробь** (сумма / количество), которая может быть бесконечной десятичной дробью: 933.333333... `ROUND` обрезает до нужной точности.

**В: Что считают метрики — все пиццы в меню или только заказанные?**
О: Только **заказанные**. Мы начинаем с `person_order` (журнал заказов) и подтягиваем цены. Если пицца есть в `menu`, но её никто не заказал — она не попадёт в результат. Чтобы учесть всё меню, нужно было бы начать с `menu` и делать `LEFT JOIN` на `person_order`.

**В: Может ли пиццерия отсутствовать в результате?**
О: Да. Если у пиццерии нет ни одного заказа (например, DoDo Pizza) — она не появится. `INNER JOIN` с `person_order` отбросит все пиццерии без заказов. Чтобы включить их, нужен другой подход (см. альтернативу 3).

**В: Почему GROUP BY по name, а не по id?**
О: Потому что в `SELECT` стоит `pzr.name`. Правило SQL: всё вне агрегатных функций ОБЯЗАНО быть в `GROUP BY`. Группировка по `pzr.id, pzr.name` тоже корректна и даже безопаснее (см. альтернативу 2).

**В: Что такое AVG с точки зрения математики?**
О: `AVG(price) = SUM(price) / COUNT(price)`. То есть сумма всех цен, делённая на количество непустых значений. Это среднее арифметическое.

**В: Что если одна и та же пицца заказана 3 раза?**
О: Её цена учитывается 3 раза во всех агрегатных функциях. `AVG` — сумма всех цен (включая повторы) / количество всех заказов. `COUNT(*)` = 3. `MAX`/`MIN` — от повторов не изменятся (максимум из трёх одинаковых чисел = это же число).

---

## Альтернативные варианты

```sql
-- Вариант 1: сортировка и группировка по имени столбца (нагляднее)
SELECT
    pzr.name,
    COUNT(*) AS count_of_orders,
    ROUND(AVG(mn.price), 2) AS average_price,
    MAX(mn.price) AS max_price,
    MIN(mn.price) AS min_price
FROM person_order
    INNER JOIN menu AS mn ON person_order.menu_id = mn.id
    INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
GROUP BY pzr.name
ORDER BY pzr.name;
-- ORDER BY pzr.name вместо ORDER BY 1.
-- Читаемее — сразу видно, по чему сортируем.


-- Вариант 2: GROUP BY по id + name (безопаснее)
SELECT
    pzr.name,
    COUNT(*) AS count_of_orders,
    ROUND(AVG(mn.price), 2) AS average_price,
    MAX(mn.price) AS max_price,
    MIN(mn.price) AS min_price
FROM person_order
    INNER JOIN menu AS mn ON person_order.menu_id = mn.id
    INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
GROUP BY pzr.id, pzr.name
ORDER BY 1;
-- GROUP BY pzr.id, pzr.name — группировка по первичному ключу + имени.
-- Если бы две пиццерии назывались одинаково (например, два «Dominos»
-- в разных городах), GROUP BY pzr.name слил бы их в одну строку.
-- GROUP BY pzr.id, pzr.name — каждая пиццерия отдельно.
-- В PostgreSQL: если id в GROUP BY, name можно не указывать
-- (PostgreSQL знает, что name зависит от id).
-- Но для ANSI SQL совместимости лучше указать оба.


-- Вариант 3: включить пиццерии БЕЗ заказов (через LEFT JOIN)
SELECT
    pzr.name,
    COUNT(po.id) AS count_of_orders,
    -- COUNT(po.id) вместо COUNT(*):
    -- COUNT(*) посчитает 1 даже для пиццерии без заказов (NULL-строка).
    -- COUNT(po.id) вернёт 0, если po.id = NULL (нет заказов).
    ROUND(AVG(mn.price), 2) AS average_price,
    MAX(mn.price) AS max_price,
    MIN(mn.price) AS min_price
FROM pizzeria AS pzr
    LEFT JOIN menu AS mn ON mn.pizzeria_id = pzr.id
    LEFT JOIN person_order AS po ON po.menu_id = mn.id
GROUP BY pzr.name
ORDER BY 1;
-- Начинаем с pizzeria (все пиццерии) и делаем LEFT JOIN.
-- LEFT JOIN сохраняет ВСЕ строки из левой таблицы (pizzeria),
-- даже если совпадений нет.
-- DoDo Pizza появится с count_of_orders = 0 и NULL-ценами.
-- В текущем задании это НЕ требуется, но на защите можно упомянуть.


-- Вариант 4: с дополнительной метрикой — размах цен (spread)
SELECT
    pzr.name,
    COUNT(*) AS count_of_orders,
    ROUND(AVG(mn.price), 2) AS average_price,
    MAX(mn.price) AS max_price,
    MIN(mn.price) AS min_price,
    MAX(mn.price) - MIN(mn.price) AS price_spread
    -- price_spread (размах цен) — разница между самой дорогой
    -- и самой дешёвой заказанной пиццей.
    -- Не требуется заданием, но показывает,
    -- что агрегатные функции можно комбинировать в выражениях.
FROM person_order
    INNER JOIN menu AS mn ON person_order.menu_id = mn.id
    INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
GROUP BY pzr.name
ORDER BY 1;


-- Вариант 5: CAST вместо ROUND (другой подход к форматированию)
SELECT
    pzr.name,
    COUNT(*) AS count_of_orders,
    CAST(AVG(mn.price) AS NUMERIC(10,2)) AS average_price,
    -- CAST(...AS NUMERIC(10,2)) — приводим к типу с 2 знаками после запятой.
    -- NUMERIC(10,2) означает: всего до 10 цифр, из них 2 после точки.
    -- Результат тот же, что и ROUND(..., 2), но через приведение типа.
    MAX(mn.price) AS max_price,
    MIN(mn.price) AS min_price
FROM person_order
    INNER JOIN menu AS mn ON person_order.menu_id = mn.id
    INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
GROUP BY pzr.name
ORDER BY 1;
```

Для задания **основной вариант** — самый чистый. На защите стоит упомянуть **вариант 2** (GROUP BY по id) если спросят про безопасность при неуникальных именах, и **вариант 3** (LEFT JOIN) если спросят «а что с пиццериями без заказов?».