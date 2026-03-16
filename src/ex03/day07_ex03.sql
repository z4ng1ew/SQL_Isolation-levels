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