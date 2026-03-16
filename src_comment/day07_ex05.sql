SELECT DISTINCT
    prs.name
FROM person_order
    INNER JOIN person AS prs ON prs.id = person_order.person_id
ORDER BY 1;







SELECT DISTINCT
    -- DISTINCT — модификатор SELECT, убирает дубликаты из результата.
    -- Если человек сделал 5 заказов, без DISTINCT его имя
    -- появится 5 раз. С DISTINCT — только 1 раз.
    --
    -- DISTINCT работает на этапе после SELECT, но до ORDER BY:
    -- FROM → JOIN → SELECT → DISTINCT → ORDER BY

    prs.name
    -- Имя человека из таблицы person (через алиас prs).
    -- Единственный столбец в результате.
    -- DISTINCT применяется именно к нему:
    -- если бы столбцов было несколько, DISTINCT убирал бы
    -- дубликаты по КОМБИНАЦИИ всех столбцов, а не по одному.

FROM person_order
    -- Журнал заказов: каждая строка = один заказ.
    -- Столбцы: id, person_id, menu_id, order_date.
    -- Имени тут нет — только числовой person_id.
    -- Человек с несколькими заказами создаёт несколько строк.

    INNER JOIN person AS prs ON prs.id = person_order.person_id
    -- Соединяем person_order с таблицей person,
    -- чтобы получить имя человека.
    --
    -- INNER JOIN — берёт только строки, где есть совпадение
    -- в обеих таблицах.
    --
    -- ON prs.id = person_order.person_id — условие связи:
    --   person.id (первичный ключ, PK) =
    --   person_order.person_id (внешний ключ, FK)
    --
    -- После JOIN: если Dmitriy сделал 3 заказа,
    -- у нас 3 строки с name = 'Dmitriy'.

ORDER BY 1;
    -- Сортировка по первому (и единственному) столбцу — name.
    -- ASC по умолчанию = алфавитный порядок (A → Z, А → Я).
    --
    -- ORDER BY выполняется ПОСЛЕ DISTINCT,
    -- поэтому сортируются уже уникальные имена.
    --
    -- Результат:
    --   name
    --   --------
    --   Andrey
    --   Anna
    --   Denis
    --   Dmitriy
    --   Elvira
    --   Irina
    --   Kate
    --   Nataly
    --   Peter
```

---

## Возможные вопросы на защите

**В: Почему DISTINCT, а не GROUP BY?**
О: Задание **запрещает** `GROUP BY` и любые операции с множествами (`UNION`, `INTERSECT`, `EXCEPT`). `DISTINCT` — единственный оставшийся способ убрать дубликаты. По сути `SELECT DISTINCT name` и `SELECT name ... GROUP BY name` дают одинаковый результат, но задание проверяет знание именно `DISTINCT`.

**В: Чем DISTINCT отличается от GROUP BY?**
О: Два ключевых отличия:

- `GROUP BY` создаёт группы, к которым можно применить агрегатные функции (`COUNT`, `SUM`, `AVG`...). `DISTINCT` просто удаляет повторяющиеся строки — агрегацию не поддерживает.
- `GROUP BY` **обязателен**, если в SELECT есть и обычные столбцы, и агрегатные функции. `DISTINCT` нужен, когда агрегации нет, а дубликаты убрать надо.

Короткое правило: нужны агрегаты → `GROUP BY`. Нужна только уникальность → `DISTINCT`.

**В: DISTINCT убирает дубликаты по одному столбцу или по всем?**
О: По **комбинации всех** столбцов в SELECT. Если бы было `SELECT DISTINCT name, age`, то строки `('Anna', 21)` и `('Anna', 21)` — дубликат (уберётся), а `('Anna', 21)` и `('Anna', 30)` — нет (останутся обе). В нашем запросе столбец один (`name`), поэтому дубликаты определяются только по имени.

**В: Что если человек есть в person, но не делал заказов?**
О: Он **не попадёт** в результат. `INNER JOIN` отбрасывает строки без совпадений. Если бы нужны были все люди (включая тех, кто не заказывал), потребовался бы `RIGHT JOIN` или начать с `person` и сделать `LEFT JOIN` на `person_order`.

**В: Что такое `ORDER BY 1`?**
О: Ссылка на первый столбец в SELECT — `name`. Альтернатива — `ORDER BY prs.name` или `ORDER BY name`. Число — просто короче.

**В: Зачем вообще JOIN, если можно взять person_id из person_order?**
О: Потому что задание требует **имена**, а `person_order` хранит только числовой `person_id`. Без JOIN мы получим `SELECT DISTINCT person_id` — числа, а не имена.

**В: Может ли DISTINCT повлиять на производительность?**
О: Да. `DISTINCT` требует сортировки или хеширования, чтобы найти дубликаты. На больших таблицах это дорого. Но для нашей маленькой учебной базы — незаметно.

**В: Почему нельзя UNION для решения?**
О: Задание явно запрещает: «**Запрещено:** any type (UNION,...) working with sets» — любые операции с множествами. `UNION`, `INTERSECT`, `EXCEPT` — всё запрещено. Остаётся только `DISTINCT`.

---

## Альтернативные варианты

```sql
-- Вариант 1: ORDER BY по имени столбца (нагляднее)
SELECT DISTINCT
    prs.name
FROM person_order
    INNER JOIN person AS prs ON prs.id = person_order.person_id
ORDER BY prs.name;
-- Вместо ORDER BY 1 — явное имя столбца.
-- Читаемее, но длиннее.


-- Вариант 2: GROUP BY (если бы был разрешён)
-- ВНИМАНИЕ: нарушает условие задания!
SELECT
    prs.name
FROM person_order
    INNER JOIN person AS prs ON prs.id = person_order.person_id
GROUP BY prs.name
ORDER BY 1;
-- GROUP BY автоматически убирает дубликаты:
-- все строки с одинаковым name схлопываются в одну группу.
-- Агрегатная функция не обязательна — GROUP BY работает
-- и без неё, просто как «уникализатор».
-- Но задание ЗАПРЕЩАЕТ GROUP BY.


-- Вариант 3: подзапрос с DISTINCT внутри
SELECT name
FROM (
    SELECT DISTINCT prs.name
    FROM person_order
        INNER JOIN person AS prs ON prs.id = person_order.person_id
) AS unique_names
ORDER BY 1;
-- Избыточно: DISTINCT в подзапросе, потом внешний SELECT.
-- Результат тот же. Показывает, что DISTINCT можно
-- использовать в подзапросах.


-- Вариант 4: EXISTS (без JOIN, без GROUP BY, без UNION)
SELECT
    prs.name
FROM person AS prs
WHERE EXISTS (
    SELECT 1
    FROM person_order AS po
    WHERE po.person_id = prs.id
)
ORDER BY 1;
-- Логика: для каждого человека проверяем —
-- СУЩЕСТВУЕТ ли хотя бы один заказ с его id?
-- EXISTS возвращает true/false.
-- SELECT 1 — не важно что выбираем, важен сам факт
-- наличия хотя бы одной строки.
--
-- Нет JOIN, нет GROUP BY, нет UNION, нет DISTINCT.
-- Но... используется WHERE, который в этом задании
-- формально НЕ запрещён (запрещены GROUP BY и UNION).
--
-- Преимущество EXISTS: не создаёт дубликатов изначально,
-- поэтому DISTINCT не нужен. На больших данных может быть
-- быстрее, потому что EXISTS останавливается
-- при первом найденном совпадении (не сканирует всю таблицу).


-- Вариант 5: IN (похож на EXISTS, другой синтаксис)
SELECT
    prs.name
FROM person AS prs
WHERE prs.id IN (
    SELECT person_id
    FROM person_order
)
ORDER BY 1;
-- IN проверяет: есть ли prs.id в списке всех person_id
-- из person_order.
-- Результат тот же, что и EXISTS.
-- На больших данных EXISTS обычно быстрее IN,
-- потому что EXISTS останавливается при первом совпадении,
-- а IN сначала строит весь список.
```

Для задания **единственно верный вариант — основной** (с `DISTINCT`). На защите стоит упомянуть **вариант 4 (EXISTS)** — он показывает глубокое понимание SQL и не использует ни одну запрещённую конструкцию. **Вариант 2 (GROUP BY)** — показать как пример того, что делает то же самое, но запрещён условием.