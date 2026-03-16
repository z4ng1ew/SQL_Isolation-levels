SELECT
    prs.name,
    COUNT(*) AS count_of_visits
FROM person_visits
    INNER JOIN person AS prs ON prs.id = person_visits.person_id
GROUP BY prs.name
ORDER BY 2 DESC, 1 ASC
LIMIT 4;


















SELECT
    prs.name,
    -- Выбираем имя человека из таблицы person (через алиас prs).
    -- В Ex00 мы выводили person_id (число), а теперь задание
    -- требует человекочитаемое имя — поэтому нужен JOIN с person.

    COUNT(*) AS count_of_visits
    -- Считаем количество строк в каждой группе.
    -- Группа = все визиты одного человека (с одинаковым prs.name).
    -- AS count_of_visits — псевдоним столбца результата.

FROM person_visits
    -- Основная таблица — журнал посещений.
    -- Каждая строка = один визит: person_id, pizzeria_id, visit_date.
    -- Имени человека тут НЕТ — только числовой person_id.
    -- Поэтому нужен JOIN ниже.

    INNER JOIN person AS prs ON prs.id = person_visits.person_id
    -- Соединяем person_visits с таблицей person.
    --
    -- INNER JOIN — берёт только строки, где есть совпадение
    -- в ОБЕИХ таблицах (person_visits.person_id = person.id).
    --
    -- AS prs — алиас (псевдоним) для таблицы person.
    -- Вместо длинного «person.name» пишем «prs.name».
    --
    -- ON prs.id = person_visits.person_id — условие связи:
    -- первичный ключ person.id = внешний ключ person_visits.person_id.
    --
    -- После JOIN каждая строка из person_visits «обогащается»
    -- данными из person: теперь у нас есть name, age, gender, address.

GROUP BY prs.name
    -- Группируем по имени человека.
    -- Все визиты «Dmitriy» схлопываются в одну строку,
    -- а COUNT(*) покажет, сколько раз он посещал пиццерии.
    --
    -- ПРАВИЛО SQL: всё в SELECT вне агрегатной функции
    -- ОБЯЗАНО быть в GROUP BY.
    -- prs.name в SELECT → prs.name в GROUP BY.
    --
    -- НЮАНС: если бы в базе было два человека с именем «Dmitriy»,
    -- их визиты СЛИЛИСЬ бы в одну группу.
    -- В нашей базе имена уникальны, поэтому это не проблема.

ORDER BY 2 DESC, 1 ASC
    -- Сортировка:
    --   2 DESC — по второму столбцу (count_of_visits) по убыванию.
    --           Самые активные посетители — первыми.
    --   1 ASC  — при равном количестве — по имени в алфавитном порядке.
    --
    -- Эта сортировка выполняется ДО LIMIT,
    -- поэтому LIMIT отрежет именно «хвост», оставив верхушку.

LIMIT 4;
    -- Оставляем только первые 4 строки из отсортированного результата.
    -- Порядок выполнения: FROM → JOIN → GROUP BY → SELECT → ORDER BY → LIMIT
    -- LIMIT работает ПОСЛЕДНИМ, поэтому мы получаем
    -- именно топ-4 самых активных посетителей.
    --
    -- Результат:
    --   name     | count_of_visits
    --   Dmitriy  | 4               ← лидер
    --   Denis    | 3               ← одинаковое количество (3)...
    --   Irina    | 3               ← ...отсортированы по алфавиту
    --   Nataly   | 3
```

---

## Возможные вопросы на защите

**В: Почему INNER JOIN, а не LEFT JOIN?**
О: INNER JOIN возвращает только строки, где есть совпадение в обеих таблицах. LEFT JOIN вернул бы ещё строки из person_visits, у которых нет совпадения в person. Но person_id — внешний ключ (foreign key), он всегда ссылается на существующую запись в person. Поэтому результат одинаковый, но INNER JOIN семантически точнее: мы явно говорим «нам нужны только совпавшие строки».

**В: Почему GROUP BY по name, а не по id?**
О: Потому что в SELECT стоит `prs.name`. Всё, что вне агрегатной функции, обязано быть в GROUP BY. Группировка по id тоже возможна, но тогда name надо либо тоже добавить в GROUP BY, либо обернуть в агрегатную функцию (например, `MAX(prs.name)`).

**В: Что будет без LIMIT?**
О: Запрос вернёт ВСЕХ людей с их количеством визитов. LIMIT 4 отрезает список до четырёх строк.

**В: Что если два человека с одинаковым именем?**
О: Их визиты объединятся в одну группу — GROUP BY не различает однофамильцев. Чтобы избежать этого, нужно группировать по `prs.id, prs.name`. В нашей базе имена уникальны, поэтому проблемы нет.

**В: Что такое алиас (AS)?**
О: Псевдоним — временное переименование. `person AS prs` — теперь вместо `person.name` пишем `prs.name`. `COUNT(*) AS count_of_visits` — столбец результата получает имя count_of_visits. Ключевое слово AS можно опустить: `person prs` тоже работает.

**В: Чем этот запрос отличается от Ex00?**
О: Две вещи: (1) вместо числового person_id выводим имя — для этого добавлен JOIN с таблицей person; (2) добавлен LIMIT 4 — берём только топ-4.

**В: Что такое `ORDER BY 2`? Можно ли иначе?**
О: Это ссылка по порядковому номеру столбца в SELECT. Альтернатива — `ORDER BY count_of_visits DESC, prs.name ASC`. По номеру — короче, по имени — понятнее.

---

## Альтернативные варианты

```sql
-- Вариант 1: сортировка по именам столбцов
-- (нагляднее при чтении, сразу видно — по чему сортируем)
SELECT
    prs.name,
    COUNT(*) AS count_of_visits
FROM person_visits
    INNER JOIN person AS prs ON prs.id = person_visits.person_id
GROUP BY prs.name
ORDER BY count_of_visits DESC, prs.name ASC
LIMIT 4;


-- Вариант 2: подзапрос — сначала считаем по id, потом подтягиваем имя
-- (может быть быстрее на больших данных: GROUP BY по числу, а не по строке)
SELECT
    prs.name,
    agg.count_of_visits
FROM (
    SELECT
        person_id,
        COUNT(*) AS count_of_visits
    FROM person_visits
    GROUP BY person_id
) AS agg
    INNER JOIN person AS prs ON prs.id = agg.person_id
ORDER BY agg.count_of_visits DESC, prs.name ASC
LIMIT 4;
-- Логика: внутренний подзапрос agg группирует по person_id (integer),
-- что быстрее, чем группировка по строке name.
-- Затем внешний JOIN подтягивает имя.
-- Результат идентичен.


-- Вариант 3: GROUP BY по id и name вместе
-- (безопаснее, если имена могут повторяться)
SELECT
    prs.name,
    COUNT(*) AS count_of_visits
FROM person_visits
    INNER JOIN person AS prs ON prs.id = person_visits.person_id
GROUP BY prs.id, prs.name
ORDER BY 2 DESC, 1 ASC
LIMIT 4;
-- GROUP BY prs.id, prs.name — группировка по первичному ключу + имени.
-- Даже если два человека — «Dmitriy» и «Dmitriy» — они будут
-- в разных группах, потому что id у них разный.
-- В PostgreSQL, если id в GROUP BY, то name можно не добавлять
-- (PostgreSQL знает, что name функционально зависит от id).
-- Но для ANSI SQL совместимости лучше указать оба.


-- Вариант 4: используя USING вместо ON
-- (короче, когда имена столбцов совпадают... но тут НЕ совпадают)
-- person.id ≠ person_visits.person_id, поэтому USING не подходит.
-- USING работает только когда столбцы называются ОДИНАКОВО:
--   INNER JOIN person USING (person_id) — только если бы в person
--   столбец назывался person_id, а не id.
-- Показываю для общего понимания:
--
-- SELECT prs.name, COUNT(*) AS count_of_visits
-- FROM person_visits
--     INNER JOIN person AS prs USING (person_id)  ← НЕ СРАБОТАЕТ
-- GROUP BY prs.name
-- ORDER BY 2 DESC, 1 ASC
-- LIMIT 4;
```

Для задания **вариант 1** (основной) — самый чистый. **Вариант 2** (с подзапросом) стоит упомянуть на защите, если спросят про производительность. **Вариант 3** — если спросят «а что если имена не уникальны?».