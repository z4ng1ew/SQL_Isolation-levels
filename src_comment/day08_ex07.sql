UPDATE pizzeria
SET rating = 5
WHERE name = 'Pizza Hut';

UPDATE pizzeria
SET rating = 4.6
WHERE name = 'Dominos';


-- Session #1

BEGIN;

UPDATE pizzeria
SET rating = 4
WHERE name = 'Dominos';

UPDATE pizzeria
SET rating = 4
WHERE name = 'Pizza Hut';

COMMIT;


-- Session #2

BEGIN;

UPDATE pizzeria
SET rating = 4
WHERE name = 'Pizza Hut';

UPDATE pizzeria
SET rating = 4
WHERE name = 'Dominos';

COMMIT;