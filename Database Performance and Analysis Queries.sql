-- Number of sales reps with over 5 accounts --
WITH tab1 as (SELECT COUNT (a.id) as NO_of_Accounts, s.id
			  FROM accounts a
			  JOIN sales_reps s
			  ON a.sales_rep_id = s.id
			  GROUP BY s.id
			  HAVING COUNT (a.id) > 5)
SELECT COUNT (*) count_of_Accts
FROM tab1;


-- Number of accounts with over 20 Orders --
WITH tab2 as (SELECT COUNT (o.id) as NO_of_Orders, a.id
			  FROM accounts a
			  JOIN orders o
			  ON a.id = o.account_id
			  GROUP BY a.id
			  HAVING COUNT (o.id) > 20)



SELECT COUNT (*) count_of_Orders
FROM tab2;

SELECT DATE_PART('month', occurred_at) AS month,
		COUNT(*) AS counter
FROM orders o
GROUP BY 1
ORDER BY 2 DESC;

SELECT id,
		account_id,
		CASE WHEN standard_qty = 0 THEN 0 
		ELSE standard_amt_usd/standard_qty END AS unit_price
FROM orders

SELECT DATE_TRUNC('day', occurred_at) AS day,
		COUNT(id) AS NO_of_events, channel
FROM web_events
GROUP BY 1, 3
ORDER BY 1 ASC;

SELECT *
	FROM (SELECT DATE_TRUNC('day', occurred_at) AS day,
			COUNT(id) AS NO_of_events, channel
			FROM web_events
			GROUP BY 1, 3
			ORDER BY 1 ASC) sub
			

SELECT channel, AVG (NO_of_events) AS Avg_Events
	FROM (SELECT DATE_TRUNC('day', occurred_at) AS day,
			COUNT(id) AS NO_of_events, channel
			FROM web_events
			GROUP BY 1, 3
			ORDER BY 1 ASC) sub
GROUP BY 1
ORDER BY 2;


WITH tab1 AS 	(SELECT s.name sales_rep, r.name region,
						SUM(o.total_amt_usd) sum_total
				FROM orders o
				JOIN accounts a
				ON o.account_id = a.id
				JOIN sales_reps s
				ON a.sales_rep_id = s.id
				JOIN region r
				ON s.region_id = r.id
				GROUP BY 1, 2),
				
	tab2 AS 	(SELECT MAX(sum_total) as Max_Sum
						FROM tab1
						GROUP BY 1),
						
	tab3 AS 	(SELECT Max_Sum FROM tab2)

SELECT *
FROM tab1
JOIN tab3
ON 
WHERE sum_total IN tab3;

SELECT r.name, SUM(o.total_amt_usd), COUNT(o.total)
FROM region r
JOIN sales_reps s
ON r.id = s.region_id
JOIN accounts a
ON s.id = a.sales_rep_id
JOIN orders o
ON a.id = o.account_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;


-- 3
WITH tab1 AS   (SELECT a.name, SUM(o.total)
				FROM accounts a
				JOIN orders o
				ON a.id = o.account_id
				GROUP BY 1
				HAVING SUM(o.total) > 
							(SELECT total_orders 
							 FROM
								(SELECT a.name AS acct_name, SUM(o.standard_qty),
								 SUM(o.total) as total_orders
								 FROM accounts a
								 JOIN orders o
								 ON a.id = o.account_id
								 GROUP BY 1
								 ORDER BY 2 DESC
								  LIMIT 1)sub ))
								  
SELECT COUNT(*) FROM tab1;


--4
SELECT a.name AS customer_name, 
	a.id, w.channel, COUNT(w.id)					 
FROM accounts a
JOIN web_events w
ON a.id = w.account_id
WHERE a.name = 
		(SELECT customer_name
			FROM
			(SELECT a.name AS customer_name, 
					SUM(o.total_amt_usd)						 
				FROM accounts a
				JOIN orders o
				ON a.id = o.account_id
				GROUP BY 1
				ORDER BY 2 DESC
				LIMIT 1)sub)
GROUP BY 3, 2,1
ORDER BY 4 DESC;


-- 5
WITH tab1 AS  (	SELECT account_id AS customer_id, 
					SUM(total_amt_usd) AS total_sum						 
				FROM orders o
				GROUP BY 1
				ORDER BY 2 DESC
				LIMIT 10)

SELECT AVG(total_sum) FROM tab1;


-- 6


-- 1 27/07
SELECT account_id, occurred_at,
	   standard_qty,
	   NTILE(4) OVER (PARTITION BY account_id ORDER BY standard_qty) AS standard_quartile
FROM orders
ORDER BY account_id DESC;

-- 2 
SELECT account_id, occurred_at,
	   gloss_qty,
	   NTILE(2) OVER (PARTITION BY account_id ORDER BY gloss_qty) AS gloss_half
FROM orders
ORDER BY account_id DESC;

-- 3
SELECT account_id, occurred_at,
	   total_amt_usd,
	   NTILE(100) OVER (PARTITION BY account_id ORDER BY total_amt_usd) AS total_percentile
FROM orders
ORDER BY account_id DESC;

-- 4 Top 5 accnts fro each channel
WITH direct AS(		SELECT a.name, SUM(o.total_amt_usd), w.channel	
					FROM orders o
					JOIN accounts a
					ON a.id = o.account_id
					JOIN web_events w
					ON a.id = w.account_id
					WHERE w.channel = 'direct'
					GROUP BY 1,3
					ORDER BY 2 DESC LIMIT 5),
					
	 twitter AS(	SELECT a.name, SUM(o.total_amt_usd), w.channel	
					FROM orders o
					JOIN accounts a
					ON a.id = o.account_id
					JOIN web_events w
					ON a.id = w.account_id
					WHERE w.channel = 'twitter'
					GROUP BY 1,3
					ORDER BY 2 DESC LIMIT 5),
					
	 facebook AS(	SELECT a.name, SUM(o.total_amt_usd), w.channel	
					FROM orders o
					JOIN accounts a
					ON a.id = o.account_id
					JOIN web_events w
					ON a.id = w.account_id
					WHERE w.channel = 'facebook'
					GROUP BY 1,3
					ORDER BY 2 DESC LIMIT 5),
					
		 adwords AS(	SELECT a.name, SUM(o.total_amt_usd), w.channel	
					FROM orders o
					JOIN accounts a
					ON a.id = o.account_id
					JOIN web_events w
					ON a.id = w.account_id
					WHERE w.channel = 'adwords'
					GROUP BY 1,3
					ORDER BY 2 DESC LIMIT 5),
					
	 banner AS(		SELECT a.name, SUM(o.total_amt_usd), w.channel	
					FROM orders o
					JOIN accounts a
					ON a.id = o.account_id
					JOIN web_events w
					ON a.id = w.account_id
					WHERE w.channel = 'banner'
					GROUP BY 1,3
					ORDER BY 2 DESC LIMIT 5)
					
SELECT * FROM direct
UNION 
SELECT * FROM twitter
UNION 
SELECT * FROM facebook
UNION  
SELECT * FROM adwords
UNION 
SELECT * FROM banner
ORDER BY 3;

WITH RankedAccounts AS (
    SELECT a.name,
           SUM(o.total_amt_usd) AS total_amount,
           w.channel,
           ROW_NUMBER() OVER (PARTITION BY w.channel ORDER BY SUM(o.total_amt_usd) DESC) AS rn
    FROM orders o
    JOIN accounts a ON a.id = o.account_id
    JOIN web_events w ON a.id = w.account_id
    WHERE w.channel IN ('direct', 'twitter')
    GROUP BY a.name, w.channel
)
SELECT name, total_amount, channel
FROM RankedAccounts
WHERE rn <= 5
ORDER BY channel, total_amount DESC;

