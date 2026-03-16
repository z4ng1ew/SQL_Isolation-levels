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