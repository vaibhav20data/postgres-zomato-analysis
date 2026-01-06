/* Q1: Find the top 5 most frequently ordered dishes by customer ID 11 in the last 6 months */

WITH custom_orders AS(
	SELECT 
		o.customer_id,
		c.customer_name,
		o.order_item,
		COUNT(o.order_id) AS order_count
	FROM orders o
	JOIN customers c
	ON o.customer_id = c.customer_id
	WHERE o.customer_id = 11 AND order_date >= CURRENT_DATE - INTERVAL '6 Months'
	GROUP BY o.customer_id, c.customer_name, o.order_item),
ranked_orders AS(
	SELECT
		customer_id,
		customer_name,
		order_item, 
		order_count,
		DENSE_RANK() OVER(ORDER BY order_count DESC) AS dish_rank
	FROM custom_orders)
SELECT
	customer_id,
	customer_name,
	order_item, 
	order_count,
	dish_rank
FROM ranked_orders
WHERE dish_rank <= 5
ORDER BY dish_rank;
	

/* Q2: Popular time slot: Identify time slots, where most orders are placed, 
based on 2 hour interval */

SELECT
	FLOOR(EXTRACT(HOUR FROM order_time) / 2) * 2 AS start_time,
	FLOOR(EXTRACT(HOUR FROM order_time) / 2) * 2 + 2 AS end_time,
	COUNT(*) AS Total_Orders
FROM orders
GROUP BY start_time, end_time
ORDER BY Total_Orders;

/* Q3: Find the average order value per customer who has placed more than 50 orders.
 Return customer_name, and Average Order Value */

SELECT 
	c.customer_name, 
	o.customer_id, 
	COUNT(o.order_id) as order_count, 
	AVG(o.total_amount) AS Avg_O_V
FROM orders o
	JOIN customers c
	ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.customer_name
HAVING COUNT(o.order_id) > 50
ORDER BY order_count DESC;

/* Q4. High value customers: List the customers who have spent more than 25K in total on food orders.
return customer_name, customer_id */

SELECT 
	c.customer_name, 
	o.customer_id, 
	SUM(o.total_amount) AS tot_o_v
FROM orders o
	JOIN customers c
	ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.customer_name
HAVING SUM(o.total_amount) > 25000
ORDER BY tot_o_v;

/* Q5: Orders without delivery
-- Question: Find orders that were placed but were not delivered
-- Return restaurant name, city, and number of orders not delivered */

SELECT 
	r.restaurant_name, 
	r.city, 
	o.order_status, 
	COUNT(o.order_id) AS not_del
FROM orders o
	JOIN restaurants r
	ON o.restaurant_id = r.restaurant_id
WHERE o.order_status != 'Delivered'
GROUP BY r.restaurant_name, r.city, o.order_status
ORDER BY not_del DESC;

/* Q6: Rank restaurants by their total revenue from the last year, including their name,
total revenue and rank in their city */


WITH unranked_results AS(
	SELECT 
		r.restaurant_name, 
		r.city, 
		SUM(o.total_amount) AS total_revenue
FROM orders o
	JOIN restaurants r
	ON o.restaurant_id = r.restaurant_id
	GROUP BY r.restaurant_name, r.city)
SELECT 
	restaurant_name, 
	city, 
	total_revenue, 
	RANK() OVER(PARTITION BY city ORDER BY total_revenue DESC) AS rank
FROM unranked_results;

/* Q7: Identify the most popular dish in each city based on the number of orders */

WITH popular_dishes AS(
	SELECT 
		r.city, 
		o.order_item, 
		COUNT(o.order_item) AS total_orders
FROM orders O
	JOIN restaurants r
	ON o.restaurant_id = r.restaurant_id
GROUP BY o.order_item, r.city), 
ranked_dishes AS(
	SELECT 
		city, 
		order_item, 
		total_orders, 
		RANK() OVER(PARTITION BY city ORDER BY total_orders DESC) AS rank_of_dish
FROM popular_dishes)
	SELECT 
		city, 
		order_item, 
		total_orders, 
		rank_of_dish
FROM ranked_dishes
WHERE rank_of_dish = 1;

-- Q8 Find customers who didn't place an order in october

SELECT 
	c.customer_id, 
	c.customer_name 
FROM 
customers c
WHERE NOT EXISTS(
	SELECT 
		o.order_id
FROM orders o
WHERE o.customer_id = c.customer_id AND
EXTRACT(Month FROM order_date) = 10);


--Q9 Find customers who didn't place an order in october but did in September

SELECT 
	c.customer_id, 
	c.customer_name 
FROM 
customers c
WHERE EXISTS(
	SELECT 
		o.order_id
FROM orders o
WHERE
o.customer_id = c.customer_id AND
EXTRACT(Month FROM order_date) = 9) AND
NOT EXISTS(
	SELECT 
		o.order_id
FROM orders o
WHERE
o.customer_id = c.customer_id AND
EXTRACT(Month FROM order_date) = 10);

/* Q9 Determine each rider's average delivery time assuming that the order time is 
when the order was dispatched */

SELECT 
	r.rider_name, 
	ROUND(AVG (EXTRACT(EPOCH FROM (d.delivery_time - o.order_time))/60),2) AS A_D_T
FROM riders r
	JOIN deliveries d
	ON r.rider_id = d.rider_id
	JOIN orders o
	ON d.order_id = o.order_id
GROUP BY r.rider_name
ORDER BY A_D_T;

/* Q10 Calculate and compare the order cancellation rate for each restaurant
between first half & second half of the year */

SELECT
	rsm.restaurant_name, 
	rsm.year_half, 
	rsm.cancelled_orders::decimal / rsm.total_orders AS cancellation_rate
FROM
(SELECT 
	owh.restaurant_id, 
	owh.restaurant_name, 
	owh.year_half, COUNT(*) AS total_orders,
SUM(
	CASE
		WHEN owh.order_status = 'Cancelled' THEN 1
		ELSE 0
		END) AS cancelled_orders
FROM
(SELECT 
	order_id, 
	r.restaurant_id, 
	r.restaurant_name,
CASE 
	WHEN EXTRACT(Month from o.order_date) BETWEEN 1 AND 6 THEN 'H1'
	ELSE 'H2'
	END year_half, o.order_status
FROM orders o
	JOIN restaurants r
	ON 
	o.restaurant_id = r.restaurant_id
) AS owh
GROUP BY
owh.restaurant_id, owh.restaurant_name, owh.year_half
ORDER BY owh.restaurant_id) AS rsm;


/* Q11: Monthly restaurant Growth Ratio
Calculate each restaurant's growth ratio based on the total number of orders since its joining */

WITH Current_Month_Tab AS
	(SELECT 
		restaurant_id, 
		DATE_TRUNC('Month', order_date) AS order_month, 
		COUNT(*) AS cur_m_ord
	FROM orders
	GROUP BY restaurant_id, DATE_TRUNC('Month', order_date)),
	Prev_Month_Tab AS(
	SELECT 
		restaurant_id, 
		order_month, 
		cur_m_ord, 
	LAG(cur_m_ord) OVER(PARTITION BY restaurant_id ORDER BY order_month) AS pre_m_ord
	FROM Current_Month_Tab)
SELECT 
	restaurant_id, 
	cur_m_ord, 
	pre_m_ord,
CASE
	WHEN pre_m_ord IS NULL THEN NULL	
	ELSE ROUND(((cur_m_ord::numeric - pre_m_ord::numeric) / pre_m_ord) * 100, 2)
END AS growth_pct
FROM Prev_Month_Tab
ORDER BY restaurant_id, order_month;

/* Q12: Customer Segmentation:
Segment customers into Gold or Silver groups based on their total spending compared to the 
Average Total Sum Spent by people. Customer Spending > ATS = Gold otherwise Silver */

WITH cto AS(
	SELECT 
		customer_id, 
		SUM(total_amount) AS total_spent
	FROM orders
	GROUP BY customer_id), 
ato AS (
	SELECT 
		AVG(total_spent) AS avg_spent_all
	FROM cto)
SELECT 
	cto.customer_id, 
	cto.total_spent, 
	ato.avg_spent_all,
CASE
	WHEN cto.total_spent > ato.avg_spent_all THEN 'Gold'
	ELSE 'Silver'
END AS customer_class
FROM cto
CROSS JOIN ato
ORDER BY customer_id;

/* Q13: Rider monthly earning. 
Calculate each rider's total monthly earning, assuming they earn 8% of each order's amount */

WITH tov_t AS(
	SELECT 
		d.rider_id, 
		DATE_TRUNC('Month', order_date) AS month_of_earning, 
		SUM(o.total_amount) AS total_order_value
	FROM orders o
		JOIN deliveries d
		ON o.order_id = d.order_id
	GROUP BY d.rider_id, month_of_earning)
SELECT 
	tov_t.rider_id, 
	tov_t.month_of_earning, 
	tov_t.total_order_value::decimal * 8 /100 AS rider_earning
FROM tov_t
ORDER BY tov_t.rider_id, tov_t.month_of_earning;

/* Q14: Rider rating analysis
Find the number of 5,4,3 star rating each rider has
Riders recieve rating based on delivery time
If ordered is deliverd in less than 150 minutes of order time then 5 star, if between 150 and 300 minutes then 4 star
all other situation 3 stars */

WITH min_take AS(
	SELECT 
		o.order_id, 
		d.rider_id, 
		ROUND(EXTRACT(EPOCH FROM (d.delivery_time - o.order_time)) / 60,2) AS minutes_taken
	FROM orders o
	JOIN deliveries d
		ON o.order_id = d.order_id),
t_r AS (
	SELECT 
		rider_id, 
		order_id,
	CASE
		WHEN minutes_taken < 150 THEN '5 Star'
		WHEN minutes_taken BETWEEN 150 AND 300 THEN '4 Star'
		ELSE '3 Star'
	END AS rider_rating
FROM min_take)
SELECT 
	t_r.rider_id, 
	t_r.rider_rating, 
	COUNT(t_r.rider_rating)
FROM t_r
GROUP BY t_r.rider_id, t_r.rider_rating
ORDER BY t_r.rider_id;

/* Q15: Order frequency by day:
Analyze order frequency per day of the week and identify the peak day for each restaurant */

WITH d_n AS(
	SELECT 
		o.restaurant_id, 
		r.restaurant_name, 
		o.order_id, 
		TO_CHAR(o.order_date, 'Day') AS day_name
FROM orders o
JOIN restaurants r
	ON o.restaurant_id = r.restaurant_id),
c_o AS(
	SELECT 
		d_n.restaurant_id, 
		d_n.restaurant_name, 
		d_n.day_name, 
		COUNT(d_n.day_name) AS num_of_orders
	FROM d_n
	GROUP BY d_n.restaurant_id, d_n.restaurant_name, d_n.day_name),
rank_ord AS (
	SELECT 
		c_o.restaurant_id, 
		c_o.restaurant_name, 
		c_o.day_name, 
		c_o.num_of_orders,
		DENSE_RANK() OVER(PARTITION BY c_o.restaurant_id ORDER BY c_o.num_of_orders DESC) AS peak_day
	FROM c_o)
SELECT 
	rank_ord.restaurant_id, 
	rank_ord.restaurant_name, 
	rank_ord.day_name, 
	rank_ord.num_of_orders, 
	rank_ord.peak_day
FROM rank_ord
WHERE rank_ord.peak_day = 1;

/* Q16: Customer lifetime value 
Calculate the total revenue generated by each customer over all their orders. */

SELECT o.customer_id, c.customer_name, SUM(o.total_amount) AS lifetime_revenue
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.customer_name
ORDER BY o.customer_id;

/* Q17: Monthly sales trend:
Identify sales trends by comparing each month's total revenue to previous month */

WITH o_m AS(
	SELECT 
		order_id, 
		total_amount, 
		TO_CHAR(order_date, 'Month') AS month_name,
		EXTRACT('Month' FROM order_date) AS month_num
	FROM orders),
m_r AS (
	SELECT 
		o_m.month_name, 
		o_m.month_num, 
		SUM(o_m.total_amount) AS cur_m_rev
	FROM o_m
	GROUP BY o_m.month_name, o_m.month_num), 
p_r AS(
	SELECT 
		m_r.month_name, 
		m_r.cur_m_rev, 
		m_r.month_num, 
	LAG(m_r.cur_m_rev) OVER(ORDER BY m_r.month_num) AS prev_m_rev
	FROM m_r)
SELECT 
	p_r.month_name, 
	p_r.cur_m_rev, 
	p_r.prev_m_rev, 
	(p_r.cur_m_rev - p_r.prev_m_rev) AS month_on_month_difference
FROM p_r;

/* Q18: Rider efficiency: 
Determine average delivery times and identify those with highest and lowest average. 
Assume difference between order time and delivery time is the time taken for delivery by rider */

WITH d_t AS(
	SELECT 
		d.rider_id, 
		r.rider_name, 
		o.order_id, 
		ROUND(EXTRACT(EPOCH FROM (d.delivery_time - o.order_time))/60,2) AS time_taken_del
	FROM orders o
	JOIN deliveries d
		ON o.order_id = d.order_id
	JOIN riders r
		ON d.rider_id = r.rider_id),
a_t AS(
	SELECT 
		d_t.rider_id, 
		d_t.rider_name, 
		AVG(d_t.time_taken_del) AS avg_del_time
	FROM d_t
	GROUP BY d_t.rider_id, d_t.rider_name),
rank_del AS(
	SELECT 
		a_t.rider_id, 
		a_t.rider_name, 
		a_t.avg_del_time,
		RANK() OVER(ORDER BY a_t.avg_del_time ASC) AS fastest_del,
		RANK() OVER(ORDER BY a_t.avg_del_time DESC) AS slowest_del
	FROM a_t)
SELECT 
	rank_del.rider_id, 
	rank_del.rider_name, 
	rank_del.avg_del_time, 
	rank_del.fastest_del, 
	rank_del.slowest_del
FROM rank_del
WHERE fastest_del = 1 OR slowest_del = 1;

/* Q19: Order item popularity:
Track the popularity of order item "Chicken BIRYANI " 
over time and identify in which month the demand was the most */

WITH o_m AS(
	SELECT 
		order_item, 
		DATE_TRUNC('month', order_date) AS month_start, 
		COUNT(*) AS order_times
	FROM orders
	GROUP BY order_item, DATE_TRUNC('month', order_date))
SELECT 
	o_m.order_item, 
	o_m.order_times, 
	TO_CHAR(month_start, 'Mon YYYY') AS month_of_order
FROM o_m
WHERE order_item ILIKE '%chicken biryani%'
ORDER BY o_m.order_times DESC;

/* Q20: Monthly restaurant growth ratio
Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining */

WITH monthly_orders AS (
    SELECT 
        restaurant_id,
        DATE_TRUNC('month', order_date) AS month_start,  
        COUNT(*) AS cur_m_ord
    FROM orders
    GROUP BY restaurant_id, DATE_TRUNC('month', order_date)   
),
with_prev AS (
    SELECT
        restaurant_id,
        month_start,
        cur_m_ord,
        LAG(cur_m_ord) OVER (
            PARTITION BY restaurant_id 
            ORDER BY month_start              
        ) AS prev_m_ord
    FROM monthly_orders
),
with_diff AS (
    SELECT
        restaurant_id,
        month_start,
        cur_m_ord,
        prev_m_ord,
        cur_m_ord - prev_m_ord AS ord_dif
    FROM with_prev
)
SELECT
    restaurant_id,
    TO_CHAR(month_start, 'Mon YYYY') AS order_month,
    cur_m_ord,
    prev_m_ord,
    ord_dif,
    CASE 
        WHEN prev_m_ord IS NULL OR prev_m_ord = 0 THEN NULL
        ELSE ROUND(ord_dif::numeric / prev_m_ord::numeric * 100, 2)
    END AS percentage_change
FROM with_diff
ORDER BY restaurant_id, month_start;
