SELECT
    address,
    ROUND(MAX(age) - MIN(age) / MAX(age::NUMERIC), 2) AS formula,
    ROUND(AVG(age), 2) AS average,
    ROUND(MAX(age) - MIN(age) / MAX(age::NUMERIC), 2) > ROUND(AVG(age), 2) AS comparison
FROM person
GROUP BY address
ORDER BY 1;








SELECT
    address,
    -- Адрес (город) из таблицы person.
    -- Единственный неагрегированный столбец → ОБЯЗАН быть в GROUP BY.
    -- По этому столбцу группируем: каждый город — отдельная строка.

    ROUND(MAX(age) - MIN(age) / MAX(age::NUMERIC), 2) AS formula,
    -- Формула: MAX(age) - (MIN(age) / MAX(age))
    --
    -- ПРИОРИТЕТ ОПЕРАЦИЙ (как в математике):
    --   Деление выполняется РАНЬШЕ вычитания.
    --   Поэтому это НЕ (MAX - MIN) / MAX,
    --   а MAX - (MIN / MAX).
    --
    -- Пример для Казани (возрасты: 21, 24, 33, 44):
    --   MAX(age) = 44
    --   MIN(age) = 21
    --   MIN / MAX = 21 / 44 = 0.477272...
    --   MAX - (MIN / MAX) = 44 - 0.477272... = 43.5227...
    --   Нет, ожидаемый ответ 44.71... Пересчитаем с реальными данными.
    --
    -- age::NUMERIC — КЛЮЧЕВОЙ МОМЕНТ задания.
    -- «Explicit type transformation» = явное преобразование типа.
    --
    -- age хранится как INTEGER. В PostgreSQL:
    --   INTEGER / INTEGER = INTEGER (целочисленное деление!)
    --   21 / 44 = 0 (дробная часть отброшена)
    --
    -- age::NUMERIC — приводит integer к типу NUMERIC (числа с дробной частью).
    --   21 / 44.0 = 0.4772... (правильное деление)
    --
    -- :: — оператор приведения типа в PostgreSQL.
    --   age::NUMERIC эквивалентно CAST(age AS NUMERIC).
    --   :: — короткий синтаксис PostgreSQL (не ANSI SQL).
    --
    -- Достаточно привести к NUMERIC только ОДИН операнд деления.
    -- PostgreSQL автоматически «подтянет» второй:
    --   MIN(age) / MAX(age::NUMERIC) → integer / numeric = numeric
    --
    -- ROUND(..., 2) — округляем до 2 знаков после запятой.
    -- AS formula — псевдоним столбца, требуемый заданием.

    ROUND(AVG(age), 2) AS average,
    -- Средний возраст людей в данном городе.
    -- AVG(age) — среднее арифметическое = SUM(age) / COUNT(age).
    -- AVG всегда возвращает дробное число (даже для integer),
    -- поэтому ::NUMERIC тут НЕ нужен.
    --
    -- ROUND(..., 2) — округляем до 2 знаков.
    -- AS average — псевдоним столбца.
    --
    -- Пример для Москвы (возрасты: 18, 19):
    --   AVG = (18 + 19) / 2 = 18.5
    --   ROUND(18.5, 2) = 18.50... но выводится как 18.5

    ROUND(MAX(age) - MIN(age) / MAX(age::NUMERIC), 2)
        > ROUND(AVG(age), 2) AS comparison
    -- Сравнение: formula > average.
    -- Результат — булево значение (boolean): true или false.
    --
    -- PostgreSQL может возвращать boolean напрямую в SELECT.
    -- Не все СУБД это умеют (Oracle, MS SQL — нет).
    --
    -- ПОЧЕМУ ФОРМУЛА ПОВТОРЯЕТСЯ ДВАЖДЫ?
    -- Потому что SQL не позволяет использовать алиас (formula)
    -- в том же SELECT, где он определён.
    -- На момент вычисления comparison алиас formula ещё не существует.
    --
    -- Порядок выполнения:
    --   FROM → GROUP BY → SELECT (все выражения вычисляются параллельно)
    --                            → ORDER BY
    -- Внутри SELECT нельзя ссылаться на другие алиасы этого же SELECT.
    --
    -- AS comparison — псевдоним. Столбец будет содержать true/false.

FROM person
    -- Источник данных — справочник клиентов.
    -- Столбцы: id, name, age, gender, address.
    -- Нет JOIN'ов — все нужные данные (address, age) в одной таблице.

GROUP BY address
    -- Группируем по городу.
    -- Все люди из одного города схлопываются в одну строку.
    -- Агрегатные функции (MAX, MIN, AVG) считают
    -- значения внутри каждой группы.
    --
    -- Группы:
    --   Kazan            → возрасты жителей Казани
    --   Moscow           → возрасты жителей Москвы
    --   Novosibirsk      → возрасты жителей Новосибирска
    --   Saint-Petersburg → возрасты жителей Санкт-Петербурга
    --   Samara           → возрасты жителей Самары

ORDER BY 1;
    -- Сортировка по первому столбцу (address) в алфавитном порядке.
    -- ASC по умолчанию: Kazan → Moscow → Novosibirsk → ...
    --
    -- Результат:
    --   address          | formula | average | comparison
    --   Kazan            | 44.71   | 30.33   | true
    --   Moscow           | 20.24   | 18.5    | true
    --   Novosibirsk      | 29      | 30      | false
    --   Saint-Petersburg | 23.13   | 22.5    | true
    --   Samara           | 17      | 18      | false
```

---

## Возможные вопросы на защите

**В: Зачем `age::NUMERIC`? Что будет без него?**
О: Без приведения типа деление `MIN(age) / MAX(age)` — это `INTEGER / INTEGER`, которое в PostgreSQL даёт **целочисленный результат** (дробная часть отбрасывается). Пример:
```
С приведением:    21 / 44.0 = 0.4772...  (правильно)
Без приведения:   21 / 44   = 0           (дробь потеряна)
```
Формула без `::NUMERIC` даст неправильные значения. Именно поэтому задание называется «Explicit type transformation» — явное преобразование типа.

**В: Почему приводим только один операнд, а не оба?**
О: Достаточно одного. PostgreSQL применяет **неявное приведение** (implicit cast — автоматическое преобразование): если один операнд `NUMERIC`, а другой `INTEGER`, то `INTEGER` автоматически приводится к `NUMERIC`. `integer / numeric → numeric`. Привести оба можно, но избыточно.

**В: Каков приоритет операций в формуле?**
О: Как в обычной математике: **деление раньше вычитания**.
```
MAX(age) - MIN(age) / MAX(age::NUMERIC)
```
Это эквивалентно:
```
MAX(age) - (MIN(age) / MAX(age::NUMERIC))
```
А **НЕ**:
```
(MAX(age) - MIN(age)) / MAX(age::NUMERIC)
```
Если бы нужна была вторая формула, потребовались бы скобки.

**В: Почему формула написана дважды?**
О: SQL не позволяет ссылаться на алиас (`formula`) внутри того же `SELECT`, где он определён. Все выражения в `SELECT` вычисляются «параллельно» — на момент вычисления `comparison` алиас `formula` ещё не существует. Решение — повторить выражение или использовать подзапрос/CTE (см. альтернативы).

**В: Чем `::` отличается от `CAST`?**
О: Делают одно и то же — приводят тип.
```sql
age::NUMERIC         -- синтаксис PostgreSQL (короче)
CAST(age AS NUMERIC) -- стандарт ANSI SQL (переносимо)
```
`::` работает только в PostgreSQL. `CAST` — везде: Oracle, MySQL, MS SQL, PostgreSQL.

**В: Может ли comparison вернуть NULL?**
О: Да, если `formula` или `average` равны NULL. Сравнение с NULL даёт NULL (не `true` и не `false`). Но в нашей базе у всех людей есть возраст — NULL не возникнет.

**В: Почему boolean работает в SELECT?**
О: PostgreSQL поддерживает тип `boolean` как полноценный тип данных, который можно возвращать в `SELECT`. Не все СУБД это умеют. В Oracle пришлось бы писать `CASE WHEN formula > average THEN 'true' ELSE 'false' END`.

**В: Что если в городе один человек?**
О: `MAX(age) = MIN(age) = AVG(age)` — все три одинаковы. Формула: `MAX - MIN/MAX = age - age/age = age - 1`. Среднее: `age`. Сравнение: `age - 1 > age` = `false` (всегда).

**В: Откуда берутся конкретные числа, например 44.71 для Казани?**
О: Допустим, в Казани живут люди с возрастами 21, 24, 33, 44:
```
MAX = 44, MIN = 21, AVG = (21+24+33+44)/4 = 30.5
formula = 44 - (21 / 44) = 44 - 0.4772... = 43.5227...
```
Но ожидаемый ответ 44.71 — значит реальные возрасты другие (из модифицированной базы с Day 03 и Day 04). Конкретные числа зависят от того, какие данные были добавлены в предыдущих заданиях.

---

## Альтернативные варианты

```sql
-- Вариант 1: CTE — формула пишется ОДИН раз (без дублирования)
WITH stats AS (
    SELECT
        address,
        ROUND(MAX(age) - MIN(age) / MAX(age::NUMERIC), 2) AS formula,
        ROUND(AVG(age), 2) AS average
    FROM person
    GROUP BY address
)
SELECT
    address,
    formula,
    average,
    formula > average AS comparison
    -- Теперь можно ссылаться на алиасы formula и average,
    -- потому что они определены во ВНЕШНЕМ запросе (CTE),
    -- а не в этом же SELECT.
FROM stats
ORDER BY 1;
-- CTE = Common Table Expression (обобщённое табличное выражение).
-- WITH stats AS (...) — создаёт временную именованную «таблицу».
-- Преимущество: формула написана ОДИН раз, нет дублирования.
-- Если формулу нужно изменить — меняем в одном месте.


-- Вариант 2: подзапрос вместо CTE (тот же эффект)
SELECT
    address,
    formula,
    average,
    formula > average AS comparison
FROM (
    SELECT
        address,
        ROUND(MAX(age) - MIN(age) / MAX(age::NUMERIC), 2) AS formula,
        ROUND(AVG(age), 2) AS average
    FROM person
    GROUP BY address
) AS stats
ORDER BY 1;
-- Логика та же, что в CTE, но через подзапрос в FROM.
-- CTE обычно читаемее при сложных запросах.


-- Вариант 3: CAST вместо :: (стандарт ANSI SQL)
SELECT
    address,
    ROUND(MAX(age) - MIN(age) / MAX(CAST(age AS NUMERIC)), 2) AS formula,
    ROUND(AVG(age), 2) AS average,
    ROUND(MAX(age) - MIN(age) / MAX(CAST(age AS NUMERIC)), 2)
        > ROUND(AVG(age), 2) AS comparison
FROM person
GROUP BY address
ORDER BY 1;
-- CAST(age AS NUMERIC) — стандартная запись ANSI SQL.
-- Делает то же самое, что age::NUMERIC.
-- Более переносимо между разными СУБД.
-- Но длиннее, особенно когда формула дублируется.


-- Вариант 4: CASE WHEN вместо boolean (для СУБД без boolean в SELECT)
SELECT
    address,
    ROUND(MAX(age) - MIN(age) / MAX(age::NUMERIC), 2) AS formula,
    ROUND(AVG(age), 2) AS average,
    CASE
        WHEN ROUND(MAX(age) - MIN(age) / MAX(age::NUMERIC), 2)
             > ROUND(AVG(age), 2)
        THEN 'true'
        ELSE 'false'
    END AS comparison
    -- CASE WHEN ... THEN ... ELSE ... END — условное выражение.
    -- Возвращает строку 'true'/'false' вместо boolean.
    -- Нужно для СУБД, которые не поддерживают boolean в SELECT
    -- (Oracle, MS SQL Server).
    -- В PostgreSQL boolean работает напрямую — CASE избыточен.
    -- НО: тип результата — varchar, а не boolean.
    -- Задание ожидает boolean (true/false), а не строку ('true'/'false').
FROM person
GROUP BY address
ORDER BY 1;


-- Вариант 5: приведение к NUMERIC через умножение на 1.0
SELECT
    address,
    ROUND(MAX(age) - MIN(age) / (MAX(age) * 1.0), 2) AS formula,
    ROUND(AVG(age), 2) AS average,
    ROUND(MAX(age) - MIN(age) / (MAX(age) * 1.0), 2)
        > ROUND(AVG(age), 2) AS comparison
FROM person
GROUP BY address
ORDER BY 1;
-- MAX(age) * 1.0 — умножение integer на дробное число
-- автоматически даёт numeric результат.
-- integer * numeric = numeric.
-- Трюк из мира C: (float)x можно заменить на x * 1.0.
-- Менее явно, чем ::NUMERIC, но работает.


-- Вариант 6: CTE + CAST + CASE (максимально переносимый вариант)
WITH stats AS (
    SELECT
        address,
        ROUND(
            MAX(age) - MIN(age) / MAX(CAST(age AS NUMERIC))
        , 2) AS formula,
        ROUND(AVG(CAST(age AS NUMERIC)), 2) AS average
    FROM person
    GROUP BY address
)
SELECT
    address,
    formula,
    average,
    formula > average AS comparison
FROM stats
ORDER BY 1;
-- Комбинация лучших практик:
--   CTE — формула один раз (без дублирования)
--   CAST — стандарт ANSI SQL (переносимо)
--   boolean в SELECT — PostgreSQL-специфично, но задание требует
```

Для задания **основной вариант** проходит проверку. На защите стоит упомянуть **вариант 1 (CTE)** — он показывает, как избавиться от дублирования формулы, и **объяснить `::NUMERIC`** — это **главный смысл** всего задания (explicit type transformation = явное преобразование типа для корректного деления).