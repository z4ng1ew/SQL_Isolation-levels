SELECT
    pzr.name,
    COUNT(*) AS count_of_orders,
    ROUND(AVG(mn.price), 2) AS average_price,
    MAX(mn.price) AS max_price,
    MIN(mn.price) AS min_price
FROM person_order
    INNER JOIN menu AS mn ON person_order.menu_id = mn.id
    INNER JOIN pizzeria AS pzr ON mn.pizzeria_id = pzr.id
GROUP BY pzr.name
ORDER BY 1;