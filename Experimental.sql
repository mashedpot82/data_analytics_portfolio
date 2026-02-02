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
			SELECT a.account_id,
					start_date,
					end_date,
					churn_date,
                    industry,
                    a.plan_tier
			FROM subscriptions AS s
			LEFT JOIN churn_events AS c
			ON s.account_id = c.account_id
            LEFT JOIN accounts as a
            ON a.account_id = c.account_id
		),
        
        
-- calculate active customers each month
		active_customers_per_month AS(
			SELECT  m.month_start,
					s.industry,
                    s.plan_tier,
					COUNT(DISTINCT s.account_id)  AS active_customers
			FROM months as m
			LEFT JOIN subscriptions_churn as s
			ON s.start_date < m.month_start
			AND (s.churn_date IS NULL OR (s.churn_date >= m.month_start))
			GROUP BY m.month_start, s.industry, s.plan_tier
		),	
        
        
-- calculate churned customers each month
-- selecting relevant columns and joining relevant tables
	churned_customers_per_month AS(
		SELECT
			m.month_start,
            s.industry,
            s.plan_tier,
			COALESCE(COUNT(DISTINCT s.account_id), 0)  AS churned_customers
		FROM months AS m
		LEFT JOIN subscriptions_churn AS s
		ON s.churn_date >= m.month_start
		WHERE s.churn_date < DATE_ADD(m.month_start, INTERVAL 1 MONTH)
		GROUP BY m.month_start, s.industry, s.plan_tier
		ORDER BY m.month_start
	),
    
    
-- calculate customer churn rate (ccr)
	ccr_per_industry_plan_per_month AS(
		SELECT a.month_start, 
			   a.industry,
               a.plan_tier,
			   a.active_customers, 
               COALESCE(c.churned_customers, 0) AS churned_customers, 
               COALESCE(ROUND(c.churned_customers/a.active_customers*100, 2), 0) AS CCR
		FROM active_customers_per_month as a
		LEFT JOIN churned_customers_per_month as c
		ON a.month_start = c.month_start
	),
    
    ccr_per_month AS(
		SELECT  month_start,
				COALESCE(ROUND(churned_customers/active_customers*100, 2), 0) AS CCR
		FROM (SELECT cc.month_start, 
						sum(active_customers) AS active_customers,
					    sum(churned_customers) AS churned_customers
				FROM ccr_per_industry_plan_per_month as cc
                GROUP BY month_start
                ) AS s
		GROUP BY month_start
	),
    
	 ccr_per_industry_per_month AS(
		SELECT  month_start,
				industry,
				COALESCE(ROUND(churned_customers/active_customers*100, 2), 0) AS CCR
		FROM (SELECT month_start, industry, 
						sum(active_customers) AS active_customers,
					    sum(churned_customers) AS churned_customers
				FROM ccr_per_industry_plan_per_month as cc
                GROUP BY month_start, industry
                ) AS s
		GROUP BY month_start, industry
	),

	 ccr_per_plan AS(
		SELECT  plan_tier,
				COALESCE(ROUND(churned_customers/active_customers*100, 2), 0) AS CCR
		FROM (SELECT plan_tier, 
						sum(active_customers) AS active_customers,
					    sum(churned_customers) AS churned_customers
				FROM ccr_per_industry_plan_per_month as cc
                GROUP BY plan_tier
                ) AS s
		GROUP BY plan_tier
	)

SELECT *
FROM active_customers_per_month;

SHOW WARNINGS;