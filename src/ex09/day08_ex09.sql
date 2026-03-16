SELECT
    address,
    ROUND(MAX(age) - MIN(age) / MAX(age::NUMERIC), 2) AS formula,
    ROUND(AVG(age), 2) AS average,
    ROUND(MAX(age) - MIN(age) / MAX(age::NUMERIC), 2) > ROUND(AVG(age), 2) AS comparison
FROM person
GROUP BY address
ORDER BY 1;