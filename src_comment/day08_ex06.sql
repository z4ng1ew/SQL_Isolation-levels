UPDATE pizzeria
SET rating = 1
WHERE name = 'Pizza Hut';


-- Session #1

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT SUM(rating)
FROM pizzeria;

SELECT SUM(rating)
FROM pizzeria;

COMMIT;

SELECT SUM(rating)
FROM pizzeria;


-- Session #2

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

UPDATE pizzeria
SET rating = 5
WHERE name = 'Pizza Hut';

COMMIT;

SELECT SUM(rating)
FROM pizzeria;