SELECT DISTINCT
    prs.name
FROM person_order
    INNER JOIN person AS prs ON prs.id = person_order.person_id
ORDER BY 1;