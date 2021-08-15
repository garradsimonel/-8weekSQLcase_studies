CREATE DATABASE dannys_diner;
#DROP DATABASE dannys_diner;
#SET search_path = dannys_diner;

USE dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 
 SELECT * FROM sales;

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
  SELECT * FROM menu;

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  SELECT * FROM members;
  
  
  -- 1. What is the total amount each customer spent at the restaurant?
  
  SELECT s.customer_id, SUM(m.price) as amount_spent FROM sales s
  JOIN  menu m ON s.product_id=m.product_id
  GROUP BY s.customer_id;
  
  -- 2. How many days has each customer visited the restaurant?
  SELECT customer_id,COUNT(DISTINCT(order_date)) as days_visited FROM sales 
  GROUP BY customer_id;
  
  -- 3. What was the first item from the menu purchased by each customer?
 CREATE TEMPORARY TABLE temp_sales1 
 SELECT customer_id,ROW_NUMBER() over 
 (PARTITION BY customer_id) as product_rank,
 product_id
 FROM sales;
 
 SELECT * FROM temp_sales1;
 DROP TABLE temp_sales1;
 
 SELECT customer_id, product_id FROM temp_sales1
 WHERE product_rank =1;
  
  -- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
  
  SELECT product_id,COUNT(product_id) as count FROM sales
  GROUP BY product_id
  ORDER BY count DESC;
  
  SELECT COUNT(customer_id) ,product_id FROM sales
  WHERE product_id=3;
  
  -- 5. Which item was the most popular for each customer?
  
  CREATE TEMPORARY TABLE temp_2
  SELECT customer_id,product_id,COUNT(product_id) as count FROM sales
  GROUP BY customer_id,product_id;
  
  SELECT * FROM temp_2;
  DROP TABLE temp_2;
  
 CREATE TEMPORARY TABLE temp_popular_item
 SELECT customer_id, RANK() over (PARTITION BY customer_id ORDER BY count DESC ) as rank1,
 product_id FROM temp_2;
 
  DROP TABLE temp_popular_item;
 
SELECT DISTINCT(customer_id),product_id FROM temp_popular_item
WHERE rank1=1;
  
  SELECT * FROM members;
  SELECT * FROM menu;
  SELECT * FROM sales;
  
  
  -- 6.Which item was purchased first by the customer after they became a member?
  WITH ranked AS(
     SELECT RANK() OVER(PARTITION BY customer_id ORDER BY order_date ASC) as ranking,
     customer_id,
     product_name
FROM (
     SELECT sales.customer_id,product_name,order_date
     FROM sales JOIN members 
	 ON sales.customer_id=members.customer_id
	 JOIN menu
	 ON menu.product_id = sales.product_id
     WHERE order_date >= join_date) AS complete_table )
     
SELECT customer_id,product_name FROM ranked 
WHERE ranking=1;
     
  -- 7.Which item was purchased just before the customer became a member?
  WITH ranked AS(
     SELECT RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC) as ranking,
     customer_id,
     product_name
FROM (
	SELECT sales.customer_id,product_name,order_date
	FROM sales JOIN members 
	ON sales.customer_id=members.customer_id
	JOIN menu
	ON menu.product_id = sales.product_id
	WHERE order_date < join_date) AS complete_table )
     
SELECT customer_id,product_name FROM ranked 
WHERE ranking=1;
  
 -- 8.What is the total items and amount spent for each member before they became a member?
 SELECT s.customer_id,COUNT(me.product_id) as total_items,SUM(me.price) as Amount FROM menu me
 JOIN sales s ON s.product_id = me.product_id
 JOIN members m ON m.customer_id=s.customer_id
 WHERE DATE(s.order_date) < DATE(m.join_date)
 GROUP BY s.customer_id
 ORDER BY s.customer_id;
 
 -- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id,
      SUM(CASE
              WHEN product_name='sushi' THEN 20*price
              ELSE 10*price
		  END) AS points
FROM sales JOIN menu
ON sales.product_id=menu.product_id
GROUP BY customer_id
ORDER BY points DESC;

-- 10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi
-- how many points do customer A and B have at the end of January?

SELECT sales.customer_id,
	   SUM(CASE 
              WHEN product_name='sushi' THEN 20*price
              WHEN order_date BETWEEN join_date AND join_date +7 THEN 20*price
              ELSE 10*price
		   END) AS points
FROM members JOIN sales
ON sales.customer_id=members.customer_id
JOIN menu ON menu.product_id=sales.product_id
WHERE order_date<= '2021-01-31'
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

-- BONUS QUESTIONS 

-- JOIN ALL THINGS

SELECT s.customer_id,
       s.order_date,
       me.product_name,
       me.price,
       CASE 
           WHEN s.order_date >= members.join_date THEN 'Y'
           ELSE 'N'
	   END AS member
FROM sales s 
JOIN menu me ON me.product_id= s.product_id
LEFT JOIN members ON members.customer_id=s.customer_id
ORDER BY s.customer_id;


-- RANK ALL THINGS for members only, non member purchases will be null

SELECT *,
       CASE 
           WHEN member='Y' THEN RANK() OVER(PARTITION BY customer_id,member ORDER BY order_date)
           ELSE NULL
	   END AS ranking
FROM (SELECT s.customer_id,
       s.order_date,
       me.product_name,
       me.price,
       CASE 
           WHEN s.order_date >= members.join_date THEN 'Y'
           ELSE 'N'
	   END AS member
FROM sales s 
JOIN menu me ON me.product_id= s.product_id
LEFT JOIN members ON members.customer_id=s.customer_id
ORDER BY s.customer_id) AS total;
           
           


 
  
  
  
  
  
  