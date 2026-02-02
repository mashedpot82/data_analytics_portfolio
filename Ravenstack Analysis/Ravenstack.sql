USE ravenstack;

ALTER TABLE subscriptions
MODIFY COLUMN start_date DATE; 

UPDATE subscriptions
SET end_date = null
WHERE end_date = "";

ALTER TABLE subscriptions
MODIFY COLUMN end_date DATE
DEFAULT NULL;

ALTER TABLE churn_events
MODIFY COLUMN churn_date DATE;

-- CREATE cte of start months
-- used for calculating active customers at the start of each month
WITH RECURSIVE months AS(
		SELECT DATE('2023-01-01') AS month_start
    UNION ALL
    SELECT DATE_ADD(month_start, INTERVAL 1 MONTH)
    FROM months
    WHERE month_start < '2025-01-01'
	),
    
    
	subscriptions_churn AS(
			SELECT s.account_id,
					start_date,
					end_date,
					churn_date
			FROM subscriptions AS s
			LEFT JOIN churn_events AS c
			ON s.account_id = c.account_id
		),
        
        
-- calculate active customers each month
		active_customers_per_month AS(
			SELECT  m.month_start,
					COUNT(DISTINCT account_id) AS active_customers
			FROM months as m
			LEFT JOIN subscriptions_churn as s
			ON s.start_date < m.month_start
			AND (s.churn_date IS NULL OR (s.churn_date >= m.month_start))
			GROUP BY m.month_start
		),	
        
        
-- calculate churned customers each month
-- selecting relevant columns and joining relevant tables
	churned_customers_per_month AS(
		SELECT
			m.month_start,
			COALESCE(COUNT(DISTINCT c.account_id), 0) AS churned_customers
		FROM months AS m
		LEFT JOIN churn_events AS c
			ON c.churn_date >= m.month_start
		WHERE c.churn_date < DATE_ADD(m.month_start, INTERVAL 1 MONTH)
		GROUP BY m.month_start
		ORDER BY m.month_start
	),
    
    
-- calculate customer churn rate (ccr)
	ccr_per_month AS(
		SELECT a.month_start, 
			   a.active_customers, 
               COALESCE(c.churned_customers, 0) AS churned_customers, 
               COALESCE(ROUND(c.churned_customers/a.active_customers*100, 2), 0) AS CCR
		FROM active_customers_per_month as a
		LEFT JOIN churned_customers_per_month as c
		ON a.month_start = c.month_start
	)
    
    
SELECT  *
FROM ccr_per_month

<<<<<<< HEAD:Ravenstack.sql
=======
SHOW WARNINGS;
>>>>>>> 97f0c84e223dbdc0b88fe9704032a32c86b60cb3:Ravenstack Analysis/Ravenstack.sql
