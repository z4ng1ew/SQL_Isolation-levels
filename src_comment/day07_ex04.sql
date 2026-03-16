SELECT
    prs.name,
    COUNT(*) AS count_of_visits
FROM person_visits
    INNER JOIN person AS prs ON prs.id = person_visits.person_id
GROUP BY prs.name
HAVING COUNT(*) > 3;





SELECT
    prs.name,
    -- Выбираем имя человека из таблицы person (через алиас prs).
    -- Это единственный неагрегированный столбец в SELECT,
    -- поэтому он ОБЯЗАН быть в GROUP BY.

    COUNT(*) AS count_of_visits
    -- Агрегатная функция: считает количество строк в каждой группе.
    -- Группа = все визиты одного человека.
    -- AS count_of_visits — псевдоним столбца результата.

FROM person_visits
    -- Журнал посещений: каждая строка = один визит.
    -- Столбцы: id, person_id, pizzeria_id, visit_date.
    -- Имени человека тут нет — только числовой person_id.

    INNER JOIN person AS prs ON prs.id = person_visits.person_id
    -- Соединяем person_visits с таблицей person,
    -- чтобы получить имя человека.
    --
    -- ON — условие связи:
    --   person.id (первичный ключ) = person_visits.person_id (внешний ключ)
    --
    -- INNER JOIN — берёт только строки, где есть совпадение
    -- в обеих таблицах. Строки без пары отбрасываются.
    -- (в нашей базе все person_id валидны, так что ничего не потеряется)

GROUP BY prs.name
    -- Группируем по имени.
    -- Все визиты «Dmitriy» схлопываются в одну строку.
    -- COUNT(*) покажет, сколько раз он посещал пиццерии.
    --
    -- После GROUP BY в таблице столько строк,
    -- сколько уникальных имён.

HAVING COUNT(*) > 3;
    -- HAVING — фильтр, который работает ПОСЛЕ группировки.
    -- Оставляем только те группы, где COUNT(*) > 3.
    --
    -- КЛЮЧЕВОЙ МОМЕНТ: задание ЗАПРЕЩАЕТ WHERE.
    -- WHERE фильтрует строки ДО группировки (до GROUP BY).
    -- HAVING фильтрует группы ПОСЛЕ группировки (после GROUP BY).
    --
    -- WHERE не может содержать агрегатные функции (COUNT, SUM...),
    -- потому что на этапе WHERE группы ещё не существуют.
    -- HAVING — может, потому что группы уже сформированы.
    --
    -- Порядок выполнения:
    --   FROM → JOIN → (WHERE — запрещён) → GROUP BY → HAVING → SELECT
    --
    -- В нашей базе только Dmitriy имеет 4 визита (> 3).
    -- Все остальные: 3 или меньше — отсеиваются.
    --
    -- Результат:
    --   name     | count_of_visits
    --   Dmitriy  | 4
```

---

## Возможные вопросы на защите

**В: В чём разница между WHERE и HAVING?**
О: Порядок выполнения SQL-запроса:
```
FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
```
`WHERE` фильтрует **отдельные строки** ДО группировки. `HAVING` фильтрует **целые группы** ПОСЛЕ группировки. В `WHERE` нельзя использовать агрегатные функции (`COUNT`, `SUM`...), потому что группы ещё не существуют. В `HAVING` — можно, группы уже сформированы.

**В: Почему нельзя написать `HAVING count_of_visits > 3`?**
О: Потому что `count_of_visits` — это алиас, заданный в `SELECT`. А `SELECT` выполняется **после** `HAVING`. На этапе `HAVING` алиас ещё не существует. Нужно повторять выражение: `HAVING COUNT(*) > 3`. Исключение: PostgreSQL как нестандартное расширение **разрешает** алиасы в `HAVING`, но это не ANSI SQL и не переносимо на другие СУБД (субъектно — Система Управления Базами Данных).

**В: Можно ли решить эту задачу через WHERE?**
О: Задание запрещает `WHERE`. Но теоретически — да, через подзапрос:
```sql
SELECT * FROM (...GROUP BY...) AS sub WHERE count_of_visits > 3
```
Однако это нарушение условия задания.

**В: Почему нет ORDER BY?**
О: Задание не требует сортировки. В результате всего одна строка (Dmitriy, 4) — сортировать нечего. Если бы результатов было больше, порядок без `ORDER BY` был бы **недетерминированным** (то есть непредсказуемым — PostgreSQL не гарантирует порядок).

**В: Что будет, если написать `HAVING COUNT(*) >= 3`?**
О: Вернутся все люди с 3 и более визитами: Dmitriy (4), Denis (3), Irina (3), Nataly (3). Условие `> 3` строже — только Dmitriy.

**В: Можно ли в HAVING использовать несколько условий?**
О: Да, через `AND` / `OR`:
```sql
HAVING COUNT(*) > 3 AND COUNT(*) < 10
```
Или даже разные агрегатные функции:
```sql
HAVING COUNT(*) > 3 AND MAX(visit_date) > '2022-01-05'
```

**В: HAVING без GROUP BY — возможно ли?**
О: Да. Без `GROUP BY` вся таблица — одна группа. `HAVING` фильтрует эту единственную группу:
```sql
SELECT COUNT(*) FROM person_visits HAVING COUNT(*) > 10;
```
Вернёт одну строку, если всего визитов больше 10, иначе — пустой результат.

---

## Альтернативные варианты

```sql
-- Вариант 1: GROUP BY по id + name (безопаснее при неуникальных именах)
SELECT
    prs.name,
    COUNT(*) AS count_of_visits
FROM person_visits
    INNER JOIN person AS prs ON prs.id = person_visits.person_id
GROUP BY prs.id, prs.name
HAVING COUNT(*) > 3;
-- Если бы в базе было два «Dmitriy» с разными id,
-- GROUP BY prs.name слил бы их в одну группу.
-- GROUP BY prs.id, prs.name — каждый человек отдельно.
-- В нашей базе имена уникальны, но это хорошая привычка.


-- Вариант 2: подзапрос + WHERE (если бы WHERE был разрешён)
-- ВНИМАНИЕ: этот вариант НАРУШАЕТ условие задания!
-- Показываю только для понимания разницы подходов.
SELECT
    name,
    count_of_visits
FROM (
    SELECT
        prs.name,
        COUNT(*) AS count_of_visits
    FROM person_visits
        INNER JOIN person AS prs ON prs.id = person_visits.person_id
    GROUP BY prs.name
) AS visit_stats
WHERE count_of_visits > 3;
-- Логика: внутренний запрос считает визиты (без фильтрации),
-- внешний фильтрует результат через WHERE.
-- WHERE тут работает, потому что он фильтрует строки
-- уже ГОТОВОГО подзапроса, а не сырые данные.
-- Но задание ЗАПРЕЩАЕТ WHERE — поэтому только HAVING.


-- Вариант 3: CTE (WITH) + WHERE (тоже нарушает запрет WHERE)
-- Опять только для демонстрации — на защите НЕ предлагать как решение.
WITH visit_stats AS (
    SELECT
        prs.name,
        COUNT(*) AS count_of_visits
    FROM person_visits
        INNER JOIN person AS prs ON prs.id = person_visits.person_id
    GROUP BY prs.name
)
SELECT name, count_of_visits
FROM visit_stats
WHERE count_of_visits > 3;


-- Вариант 4: PostgreSQL-расширение — алиас в HAVING
-- (работает в PostgreSQL, но НЕ стандарт ANSI SQL)
SELECT
    prs.name,
    COUNT(*) AS count_of_visits
FROM person_visits
    INNER JOIN person AS prs ON prs.id = person_visits.person_id
GROUP BY prs.name
HAVING count_of_visits > 3;
-- PostgreSQL разрешает использовать алиас из SELECT в HAVING.
-- Другие СУБД (MySQL — да, Oracle — нет, MS SQL — нет) — по-разному.
-- Для переносимости лучше повторять выражение: HAVING COUNT(*) > 3.


-- Вариант 5: оконная функция (без GROUP BY и без WHERE)
-- Переусложнённо, но показывает знание оконных функций.
SELECT DISTINCT
    name,
    count_of_visits
FROM (
    SELECT
        prs.name,
        COUNT(*) OVER (PARTITION BY prs.name) AS count_of_visits
        -- OVER (PARTITION BY ...) — оконная функция.
        -- Считает COUNT для каждой «партиции» (группы по name),
        -- НО не схлопывает строки (в отличие от GROUP BY).
        -- Поэтому нужен DISTINCT снаружи.
    FROM person_visits
        INNER JOIN person AS prs ON prs.id = person_visits.person_id
) AS windowed
-- Формально тут нет ни WHERE, ни HAVING, ни GROUP BY.
-- Фильтрация ниже — это WHERE на внешнем подзапросе,
-- что по условию задания запрещено.
-- Показываю только как концепцию.
-- WHERE count_of_visits > 3;
-- ← раскомментировать нельзя из-за запрета WHERE.
```

Для задания **единственный корректный вариант — основной** (с `HAVING`). Вся суть упражнения — показать, что `HAVING` фильтрует группы после агрегации, и это **невозможно** заменить на `WHERE` в рамках одного запроса без подзапросов.






















*1 


## HAVING

Это **фильтр для групп**, который работает ПОСЛЕ `GROUP BY`. По сути — аналог `WHERE`, но для агрегированных данных.

### Ключевая разница с WHERE

```
WHERE  — фильтрует СТРОКИ    ДО   группировки
HAVING — фильтрует ГРУППЫ    ПОСЛЕ группировки
```

Порядок выполнения SQL-запроса:

```
FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
              ↑                   ↑
              строки              группы
              ещё не сгруппированы   уже сгруппированы
```

### Простой пример

Задача: найти города, в которых живёт **больше 2** человек.

```sql
SELECT address, COUNT(*) AS people_count
FROM person
GROUP BY address
HAVING COUNT(*) > 2;
```

Что происходит пошагово:

```
1. FROM person         → берём все строки (9 человек)
2. GROUP BY address    → группируем по городу:
     Kazan            → 4 человека
     Moscow           → 2 человека
     Novosibirsk      → 2 человека
     Saint-Petersburg → 3 человека  (пример)
     Samara           → 2 человека
3. HAVING COUNT(*) > 2 → оставляем только группы с count > 2:
     Kazan            → 4  ✓
     Moscow           → 2  ✗ (отброшено)
     Novosibirsk      → 2  ✗ (отброшено)
     Saint-Petersburg → 3  ✓
     Samara           → 2  ✗ (отброшено)
```

### Почему WHERE не подходит

```sql
-- ЭТО НЕ СРАБОТАЕТ:
SELECT address, COUNT(*) AS people_count
FROM person
GROUP BY address
WHERE COUNT(*) > 2;
-- Ошибка! WHERE выполняется ДО GROUP BY,
-- а COUNT(*) существует только ПОСЛЕ группировки.
-- На этапе WHERE группы ещё не созданы — считать нечего.
```

### Аналогия из Си

Если представить GROUP BY как цикл, то:

```c
// WHERE — фильтр ПЕРЕД группировкой (на уровне элементов)
for (int i = 0; i < rows; i++) {
    if (row[i].age > 18)        // ← это WHERE
        add_to_group(row[i]);
}

// HAVING — фильтр ПОСЛЕ группировки (на уровне групп)
for (int g = 0; g < groups; g++) {
    if (group[g].count > 2)     // ← это HAVING
        output(group[g]);
}
```

### Можно ли использовать оба вместе?

Да. `WHERE` отсеивает строки до группировки, `HAVING` — группы после:

```sql
SELECT address, COUNT(*) AS people_count
FROM person
WHERE age > 20              -- сначала убираем молодёжь (до группировки)
GROUP BY address
HAVING COUNT(*) > 1;        -- потом оставляем города с 2+ взрослыми (после)
```

### Коротко

`HAVING` — это `WHERE` для групп. Используй `HAVING`, когда нужно отфильтровать результат агрегатных функций (`COUNT`, `SUM`, `AVG`, `MAX`, `MIN`).