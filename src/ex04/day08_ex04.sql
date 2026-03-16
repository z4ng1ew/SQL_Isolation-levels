SELECT
    prs.name,
    COUNT(*) AS count_of_visits
FROM person_visits
    INNER JOIN person AS prs ON prs.id = person_visits.person_id
GROUP BY prs.name
HAVING COUNT(*) > 3;