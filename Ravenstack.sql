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
			   COALESCE(c.churned_customers, 0) AS churned_customers,
			   a.active_customers, 
               COALESCE(ROUND(c.churned_customers/a.active_customers*100, 2), 0) AS CCR
		FROM active_customers_per_month as a
		LEFT JOIN churned_customers_per_month as c
		ON a.month_start = c.month_start
	),
    
    ccr_per_industry AS(
		SELECT c.industry, churned_customers, total_customers, churned_customers / total_customers * 100 AS CCR
        FROM (
			SELECT industry, count(*) AS churned_customers
            FROM accounts
			WHERE lower(churn_flag) = 'true'
            GROUP BY industry
           
        ) AS c
        LEFT JOIN
			(SELECT industry, count(*) AS total_customers
            FROM accounts
            GROUP BY industry) AS t
		ON c.industry = t.industry
    ),
    
    ccr_per_plan AS(
		SELECT c.plan_tier, churned_customers, total_customers, churned_customers / total_customers * 100 AS CCR
        FROM (
			SELECT plan_tier, count(*) AS churned_customers
            FROM accounts
			WHERE lower(churn_flag) = 'true'
            GROUP BY plan_tier
           
        ) AS c
        LEFT JOIN
			(SELECT plan_tier, count(*) AS total_customers
            FROM accounts
            GROUP BY plan_tier) AS t
		ON c.plan_tier = t.plan_tier
    )
    
SELECT  *
FROM ccr_per_month

