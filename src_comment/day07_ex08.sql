SELECT
    prs.address,
    pzr.name,
    COUNT(*) AS count_of_orders
FROM person_order
    INNER JOIN menu AS mn ON person_order.menu_id = mn.id
    INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
    INNER JOIN person AS prs ON prs.id = person_order.person_id
GROUP BY prs.address, pzr.name
ORDER BY 1, 2;




SELECT
    prs.address,
    -- Адрес человека из таблицы person (через алиас prs).
    -- В нашей базе address хранит название города: Kazan, Moscow и т.д.
    -- Задание предполагает: человек заказывает только в пиццериях своего города.
    -- Поэтому address = «местоположение ресторана».

    pzr.name,
    -- Название пиццерии из справочника pizzeria (через алиас pzr).
    -- Вместе с address формирует уникальную пару для группировки:
    -- «в каком городе, в какой пиццерии».

    COUNT(*) AS count_of_orders
    -- Количество заказов для каждой пары (адрес + пиццерия).
    -- Каждая строка в person_order = один заказ.
    -- COUNT(*) считает все строки в группе.
    -- AS count_of_orders — псевдоним, требуемый заданием.

FROM person_order
    -- Журнал заказов — основная таблица запроса.
    -- Столбцы: id, person_id, menu_id, order_date.
    -- Отсюда начинаем, потому что нас интересуют именно заказы.
    -- Ни адреса, ни названия пиццерии тут нет — нужны три JOIN'а.

    INNER JOIN menu AS mn ON person_order.menu_id = mn.id
    -- Первый JOIN: person_order → menu.
    -- Зачем: person_order хранит menu_id, а не pizzeria_id.
    -- Через menu мы получим pizzeria_id (в каком заведении эта пицца).
    --
    -- ON person_order.menu_id = mn.id — условие связи:
    --   menu_id (FK в person_order) = id (PK в menu).

    INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
    -- Второй JOIN: menu → pizzeria.
    -- Зачем: из menu берём pizzeria_id, из pizzeria — name.
    --
    -- Цепочка для имени пиццерии:
    --   person_order → menu → pizzeria
    --   (заказ)       (меню)  (название)

    INNER JOIN person AS prs ON prs.id = person_order.person_id
    -- Третий JOIN: person_order → person.
    -- Зачем: из person берём address (город клиента).
    --
    -- ON prs.id = person_order.person_id — условие связи:
    --   id (PK в person) = person_id (FK в person_order).
    --
    -- Итого три JOIN'а, три цели:
    --   menu    → получить pizzeria_id (путь к пиццерии)
    --   pizzeria → получить name        (название пиццерии)
    --   person   → получить address     (город клиента)

GROUP BY prs.address, pzr.name
    -- Группируем по ПАРЕ (адрес, название пиццерии).
    -- Каждая уникальная комбинация = отдельная строка в результате.
    --
    -- Пример групп:
    --   ('Kazan', 'Best Pizza')    → все заказы казанцев в Best Pizza
    --   ('Kazan', 'DinoPizza')     → все заказы казанцев в DinoPizza
    --   ('Moscow', 'Dominos')      → все заказы москвичей в Dominos
    --
    -- ПРАВИЛО: оба неагрегированных столбца из SELECT
    -- (prs.address и pzr.name) ОБЯЗАНЫ быть в GROUP BY.

ORDER BY 1, 2;
    -- Сортировка по двум столбцам:
    --   1 = address (ASC по умолчанию, алфавит: Kazan → Moscow → ...)
    --   2 = name    (ASC по умолчанию, алфавит внутри каждого города)
    --
    -- Результат:
    --   address          | name        | count_of_orders
    --   Kazan            | Best Pizza  | 4
    --   Kazan            | DinoPizza   | 4
    --   Kazan            | Dominos     | 1
    --   Moscow           | Dominos     | 2
    --   Moscow           | Pizza Hut   | 2
    --   Novosibirsk      | Dominos     | 1
    --   Novosibirsk      | Papa Johns  | 1
    --   Saint-Petersburg | Dominos     | 2
    --   Saint-Petersburg | Papa Johns  | 1
    --   Saint-Petersburg | Pizza Hut   | 2
    --   Samara           | Best Pizza  | 1
    --   Samara           | DinoPizza   | 1
```

---

## Возможные вопросы на защите

**В: Зачем три JOIN'а?**
О: Каждый JOIN подтягивает данные из отдельной таблицы:
```
person_order  →  menu      →  pizzeria
(menu_id)       (pizzeria_id)  (name)
     ↓
   person
  (address)
```
Без любого из трёх запрос не получит нужные столбцы. `menu` — мост между заказом и пиццерией (в `person_order` нет прямого `pizzeria_id`). `person` — источник адреса. `pizzeria` — источник названия.

**В: Почему GROUP BY по двум столбцам?**
О: Нам нужна статистика для каждой **комбинации** «город + пиццерия». Если группировать только по `address` — все пиццерии в одном городе слипнутся. Если только по `pzr.name` — Dominos из Москвы и Dominos из Казани сольются. Группировка по паре — даёт каждую уникальную комбинацию.

**В: Правда ли, что address = город пиццерии?**
О: Это **допущение** задания. В базе нет прямой информации о расположении пиццерий. Задание говорит: «предположим, что человек посещает только пиццерии в своём городе». Поэтому `address` клиента используется как косвенный показатель местоположения ресторана. В реальной системе у пиццерии был бы свой столбец `city`.

**В: Почему INNER JOIN, а не LEFT JOIN?**
О: Нас интересуют только заказы, у которых есть вся цепочка: клиент → заказ → меню → пиццерия. `INNER JOIN` отбрасывает строки без совпадений. `LEFT JOIN` сохранил бы «висячие» заказы (без меню или без клиента), но таких в нашей базе нет — внешние ключи гарантируют целостность.

**В: Влияет ли порядок JOIN'ов на результат?**
О: Нет. SQL-оптимизатор (query planner — планировщик запросов) сам решает, в каком порядке физически соединять таблицы. Можно написать `FROM person AS prs INNER JOIN person_order ... INNER JOIN menu ... INNER JOIN pizzeria ...` — результат будет тот же. Порядок записи влияет только на читаемость.

**В: Что если один человек живёт в Казани, но заказал пиццу из московской пиццерии?**
О: В текущей модели данных это невозможно проверить — у пиццерии нет столбца `city`. Задание **предполагает**, что все заказы локальные. Если бы пиццерия имела свой адрес, можно было бы добавить `WHERE prs.address = pzr.city` для фильтрации.

**В: Что значит `ORDER BY 1, 2` без DESC/ASC?**
О: По умолчанию сортировка `ASC` (ascending — по возрастанию). Строки сортируются в алфавитном порядке. `ORDER BY 1, 2` = `ORDER BY 1 ASC, 2 ASC` = `ORDER BY prs.address ASC, pzr.name ASC`.

---

## Альтернативные варианты

```sql
-- Вариант 1: сортировка и группировка по именам столбцов (нагляднее)
SELECT
    prs.address,
    pzr.name,
    COUNT(*) AS count_of_orders
FROM person_order
    INNER JOIN menu AS mn ON person_order.menu_id = mn.id
    INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
    INNER JOIN person AS prs ON prs.id = person_order.person_id
GROUP BY prs.address, pzr.name
ORDER BY prs.address, pzr.name;
-- ORDER BY по именам столбцов вместо номеров.
-- Читаемее — сразу видно, по чему сортируем.


-- Вариант 2: другой порядок JOIN (начинаем с person)
SELECT
    prs.address,
    pzr.name,
    COUNT(*) AS count_of_orders
FROM person AS prs
    INNER JOIN person_order AS po ON po.person_id = prs.id
    INNER JOIN menu AS mn ON po.menu_id = mn.id
    INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
GROUP BY prs.address, pzr.name
ORDER BY 1, 2;
-- Начинаем с person (источник адреса), потом подтягиваем заказы.
-- Логика чтения: «берём человека → его заказы → меню → пиццерию».
-- Результат идентичен — оптимизатор PostgreSQL сам выберет
-- лучший порядок выполнения независимо от порядка записи.


-- Вариант 3: GROUP BY по id-шникам (теоретически быстрее)
SELECT
    prs.address,
    pzr.name,
    COUNT(*) AS count_of_orders
FROM person_order
    INNER JOIN menu AS mn ON person_order.menu_id = mn.id
    INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
    INNER JOIN person AS prs ON prs.id = person_order.person_id
GROUP BY prs.address, pzr.id, pzr.name
ORDER BY 1, 2;
-- GROUP BY pzr.id, pzr.name — добавляем id пиццерии.
-- Группировка по integer-ключу быстрее, чем по строке.
-- PostgreSQL: если pzr.id в GROUP BY, то pzr.name можно
-- не указывать (функциональная зависимость — name определяется по id).
-- Но для ANSI SQL указываем оба.
-- address не связан с id, поэтому его отдельно нельзя убрать.


-- Вариант 4: CTE (WITH) для разделения логики
WITH order_details AS (
    -- Сначала собираем все данные в одну «плоскую» таблицу
    SELECT
        prs.address,
        pzr.name AS pizzeria_name
    FROM person_order
        INNER JOIN menu AS mn ON person_order.menu_id = mn.id
        INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
        INNER JOIN person AS prs ON prs.id = person_order.person_id
)
-- Потом группируем и считаем
SELECT
    address,
    pizzeria_name AS name,
    COUNT(*) AS count_of_orders
FROM order_details
GROUP BY address, pizzeria_name
ORDER BY 1, 2;
-- CTE = Common Table Expression (обобщённое табличное выражение).
-- Разделяет «сборку данных» и «агрегацию» на два читаемых шага.
-- Результат идентичен, но на больших данных CTE может быть
-- чуть медленнее (PostgreSQL иногда материализует CTE в память).


-- Вариант 5: с дополнительным столбцом — доля заказов в городе
SELECT
    prs.address,
    pzr.name,
    COUNT(*) AS count_of_orders,
    ROUND(
        COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER (PARTITION BY prs.address) * 100
    , 1) AS pct_in_city
    -- pct_in_city (percent in city — процент в городе):
    -- доля заказов этой пиццерии среди всех заказов города.
    --
    -- COUNT(*) — заказы в этой пиццерии
    -- SUM(COUNT(*)) OVER (PARTITION BY address) — все заказы в городе
    -- Деление * 100 = процент
    --
    -- OVER (PARTITION BY ...) — оконная функция поверх агрегата.
    -- Не требуется заданием, но показывает продвинутое владение SQL.
FROM person_order
    INNER JOIN menu AS mn ON person_order.menu_id = mn.id
    INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
    INNER JOIN person AS prs ON prs.id = person_order.person_id
GROUP BY prs.address, pzr.name
ORDER BY 1, 2;
```

Для задания **основной вариант** — оптимален. На защите стоит упомянуть **вариант 2** (другой порядок JOIN) чтобы показать, что порядок записи не влияет на результат, и **допущение** про `address = город пиццерии`, если спросят про логику задания.