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