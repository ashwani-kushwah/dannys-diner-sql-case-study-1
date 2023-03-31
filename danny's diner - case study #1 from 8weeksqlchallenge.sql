CREATE DATABASE dannys_diner

USE dannys_diner

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
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
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');



--Case Study Questions

--1.What is the total amount each customer spent at the restaurant?
--2. How many days has each customer visited the restaurant?
--3. What was the first item from the menu purchased by each customer?
--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
--5. Which item was the most popular for each customer?
--6. Which item was purchased first by the customer after they became a member?
--7. Which item was purchased just before the customer became a member?
--8. What is the total items and amount spent for each member before they became a member?
--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


--1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, sum (m.price) TotalSpend
FROM dannys_diner..sales s 
join dannys_diner..menu m 
on s.product_id = m.product_id
group by s.customer_id
order by s.customer_id


--2. How many days has each customer visited the restaurant?
SELECT s.customer_id, count(distinct (order_date)) No_of_days 
FROM dannys_diner..sales s
group by s.customer_id


--3. What was the first item from the menu purchased by each customer?
with cte as(
select customer_id, product_name, dense_rank() over (partition by customer_id
order by order_date) as rank
from dannys_diner..sales s
join dannys_diner..menu m 
on s.product_id = m.product_id)

select customer_id, product_name as First_Item
from cte
where rank = 1
group by customer_id, product_name


--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select top 1 count(s.product_id) as Selling_count, m.product_name
from dannys_diner..sales s
join dannys_diner..menu m
on s.product_id = m.product_id
group by m.product_name
order by Selling_count desc


--5. Which item was the most popular for each customer?
with cte as(
select customer_id, product_name, count(m.product_id) as order_count,
dense_rank() over (partition by s.customer_id order by count(s.customer_id) desc) as rank
from dannys_diner..sales s
join dannys_diner..menu m
on s.product_id = m.product_id
group by product_name, customer_id )

select customer_id, product_name, order_count
from cte
where rank = 1


--6. Which item was purchased first by the customer after they became a member?
WITH cte AS (
SELECT s.customer_id, s.product_id,
DENSE_RANK() OVER (PARTITION BY s.customer_id
ORDER BY s.order_date) AS rnk
FROM dannys_diner..sales s
JOIN dannys_diner..members ms
	ON s.customer_id = ms.customer_id
WHERE s.order_date >= ms.join_date
)
SELECT cte.customer_id, m.product_name 
FROM cte 
JOIN dannys_diner..menu m
	ON cte.product_id = m.product_id
WHERE rnk = 1
ORDER BY cte.customer_id


--7. Which item was purchased just before the customer became a member?
WITH before_member_cte AS
(
SELECT s.customer_id, s.product_id,
	DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rnk
FROM dannys_diner..sales s
JOIN dannys_diner..members ms 
	ON s.customer_id = ms.customer_id
WHERE s.order_date < ms. join_date
)
SELECT bmc.customer_id, m.product_name
FROM before_member_cte bmc
JOIN dannys_diner..menu m 
	ON bmc.product_id = m.product_id
WHERE rnk = 1
ORDER BY bmc.customer_id


--8. What is the total items and amount spent for each member before they became a member?
select mb.customer_id, count(s.product_id), sum(m.price)
from dannys_diner..sales s
join dannys_diner..menu m
	on s.product_id = m.product_id 
join dannys_diner..members mb
	on s.customer_id = mb.customer_id 
where s.order_date<mb.join_date
group by mb.customer_id
order by mb.customer_id


--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select s.customer_id,
sum(case when m.product_id = 1 then 20*m.price else 10*m.price end) as Loyalty_Points
from dannys_diner..sales s 
join dannys_diner..menu m
	on s.product_id = m.product_id
group by s.customer_id
order by s.customer_id


--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
--    how many points do customer A and B have at the end of January?
select s.customer_id,
sum(case when m.product_id=1 then 20*m.price
		when datepart(day, s.order_date) - datepart (day, mb.join_date) BETWEEN 0 AND 6 THEN 20*m.price
		else 10*m.price end) as Loyalty_Points
from dannys_diner..sales s
join dannys_diner..menu m
	on s.product_id = m.product_id
join dannys_diner..members mb
	on s.customer_id = mb.customer_id
group by s.customer_id
order by s.customer_id



