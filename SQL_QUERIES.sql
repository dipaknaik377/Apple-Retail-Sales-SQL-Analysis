USE Apple_Retail_Sales

-- To View Data 

select * from stores
select * from category
select * from products
select * from sales
select * from warranty

--Exploratory Data Analysis 

select distinct repair_status from warranty;

select distinct store_name from stores;

select distinct category_name from category;

select distinct product_name from products;

select count(*) as [Total_QTY] from sales;

--"planning Time: 0.098 ms"
--"Execution time: 136.423 ms"
--explain analyze
select * from sales where product_id = 'P-40';

--Improve Query Performance 
create index sales_product_id on sales(product_id);

select * from sales where product_id = 'P-40';
--After creation of indexes query performance are increased to 
--"planning Time 0.118 ms"
--"Execution Time 6.324 ms"

create index sales_store_id on sales(store_id);

create index sales_quantity on sales(quantity);

create index sales_product_id_store_id on sales(product_id,store_id);

--Business Problems
/*=====================================================
--1. Find number of Stores in each country 
select * from stores --To get clear understanding about table before solving the question.
=====================================================*/

select 
Country,
count(store_id) as Total_Stores
from stores 
group by Country 
order by count(Store_ID) desc;

/*=====================================================
--2.calculate the total number of unit sold by each store.
=====================================================*/
select * from sales;

select 
s.store_id,
st.store_name,
SUM(s.quantity) as total_units_sold
from sales as s
join 
stores as st
on st.Store_id = s.store_id
group by s.store_id,st.Store_Name
order by total_units_sold desc;

/*=====================================================
--3.Identify how many sates occured in December 2023.
=====================================================*/

select
count(*) as total_sales 
from sales 
where year(sale_date)= 2023
 And  Month(sale_date) = 12

/*=====================================================	
--4.Determine how many stores have never had a warranty claim filed.
=====================================================*/
	
select count(*) from stores
where store_id not in (
select distinct store_id from sales as s
right join warranty as w on s.sale_id = w.sale_id);

/*=====================================================
--5.calculate the percentage of warranty claims narked as "Rejected".
=====================================================*/

select 
    ROUND(
          (count(claim_id) * 100.0) / (select COUNT(*) from warranty),
	      2
	      ) AS rejected_percentage
from warranty
where repair_status = 'Rejected';

/*=====================================================
--6. Identify which store had the highest total units sold in the last year.
=====================================================*/
	
SELECT TOP 1
    s.store_id,
    st.store_name,
    SUM(s.quantity) AS total_units_sold
FROM Sales AS s
JOIN Stores AS st
    ON s.store_id = st.store_id
WHERE s.sale_date >= DATEADD(
    YEAR,
    -1,
    (SELECT MAX(sale_date) FROM Sales)
)
GROUP BY
    s.store_id,
    st.store_name
ORDER BY
    total_units_sold DESC;

/*=====================================================
--7.Count the number of unique products sold in the last year.
=====================================================*/

select 
COUNT(distinct product_id) AS unique_products_sold
from sales 
where sale_date >= DATEADD(
      YEAR,
	  -1,
	  (select max(sale_date) from sales)
);

/*=====================================================
--8.Find the average price of products in each category.
=====================================================*/
	
SELECT
    c.category_id,
    c.category_name,
    ROUND(AVG(p.price), 2) AS average_price
FROM Products AS p
INNER JOIN Category AS c
    ON p.category_id = c.category_id
GROUP BY
    c.category_id,
    c.category_name
ORDER BY
    average_price DESC;

/*=====================================================
--9.How many warranty Claim were filed in 2024 ?.
=====================================================*/

select distinct year (claim_date) as year_part from warranty;
--To see distinct year data

select 
count(*)
from warranty 
where year(claim_date) as year_part = 2024

	/*=====================================================
--10.for each store, identify the best -selling day based on highest quantity sold?.
=====================================================*/
select * from 
(
    select 
	store_id,
	DATENAME(WEEKDAY, sale_date) as day_name,
	sum(quantity) as total_quantity_sold,
	rank() 
	over(partition by store_id order by sum(quantity) desc) as rnk 
	from sales
	group by store_id,
	DATENAME(WEEKDAY,sale_date)
	) as tbl1
	where rnk = 1;

/*=====================================================
--11.identify the least selling product in each country for each year based on total units sold.
=====================================================*/

WITH product_rank AS
(
    SELECT
        st.country,
        YEAR(s.sale_date) AS sales_year,
        p.product_name,
        SUM(s.quantity) AS total_units_sold,
        RANK() OVER
        (
            PARTITION BY st.country, YEAR(s.sale_date)
            ORDER BY SUM(s.quantity) ASC
        ) AS least_sold_product
    FROM Sales AS s
    INNER JOIN Stores AS st
        ON s.store_id = st.store_id
    INNER JOIN Products AS p
        ON s.product_id = p.product_id
    GROUP BY
        st.country,
        YEAR(s.sale_date),
        p.product_name
)

SELECT *
FROM product_rank
WHERE least_sold_product = 1
ORDER BY country, sales_year;

/*=====================================================
--12.calculate how many warranty claims were filed within 180 days of a product sale.
=====================================================*/
select 
count(*) as total_claims
from warranty as w 
left join sales as s
on w.sale_id = s.sale_id
where DATEDIFF(day, s.sale_date,w.claim_date) between 1 and 180;

/*=====================================================
--13. Determine how many warranty claims were filed for products launched in the last two years.
=====================================================*/

SELECT
    p.product_name,
    COUNT(w.claim_id) AS total_warranty_claims,
    COUNT(s.sale_id) AS total_sales
FROM Warranty AS w
INNER JOIN Sales AS s
    ON w.sale_id = s.sale_id
INNER JOIN Products AS p
    ON p.product_id = s.product_id
WHERE p.launch_date >= DATEADD(
    YEAR,
    -2,
    (SELECT MAX(launch_date) FROM Products)
)
GROUP BY
    p.product_name
HAVING COUNT(w.claim_id) > 0
ORDER BY
    total_warranty_claims DESC;

/*=====================================================
--14. List the months in the last three years where states exceeded units in the USA.
=====================================================*/
	
SELECT
    YEAR(s.sale_date) AS sales_year,
    MONTH(s.sale_date) AS sales_month,
    SUM(s.quantity) AS total_units_sold
FROM Sales AS s
JOIN Stores AS st
    ON s.store_id = st.store_id
WHERE st.country = 'United States'
  AND s.sale_date >= DATEADD(
        YEAR,
        -3,
        (SELECT MAX(sale_date) FROM Sales)
    )
GROUP BY
    YEAR(s.sale_date),
    MONTH(s.sale_date)
HAVING
    SUM(s.quantity) > 5000
ORDER BY
    sales_year,
    sales_month;

/*=====================================================
--15.identify the product category with the most warranty claims filed in the last two years.
=====================================================*/

SELECT TOP 1
    c.category_name,
    COUNT(w.claim_id) AS total_claims
FROM Warranty AS w
INNER JOIN Sales AS s
    ON w.sale_id = s.sale_id
INNER JOIN Products AS p
    ON s.product_id = p.product_id
INNER JOIN Category AS c
    ON p.category_id = c.category_id
WHERE w.claim_date >= DATEADD(
        YEAR,
        -2,
        (SELECT MAX(claim_date) FROM Warranty)
)
GROUP BY
    c.category_name
ORDER BY
    total_claims DESC;

/*=====================================================
--16. Determine the percentage chance of receiving warranty claims after each purchase for rach country.
=====================================================*/
	
SELECT
    st.country,
    COUNT(s.sale_id) AS total_sales,
    COUNT(w.claim_id) AS total_warranty_claims,
    ROUND(
        COUNT(w.claim_id) * 100.0 / COUNT(s.sale_id),
        2
    ) AS warranty_claim_percentage
FROM Sales AS s
INNER JOIN Stores AS st
    ON s.store_id = st.store_id
LEFT JOIN Warranty AS w
    ON s.sale_id = w.sale_id
GROUP BY
    st.country
ORDER BY
    warranty_claim_percentage DESC;

/*=====================================================
--17.Analyze the year by year growth ratio for each store.
=====================================================*/

WITH yearly_sales AS
(
    SELECT
        s.store_id,
        st.store_name,
        YEAR(s.sale_date) AS sales_year,
        SUM(p.price * s.quantity) AS total_sales
    FROM Sales AS s
    INNER JOIN Products AS p
        ON s.product_id = p.product_id
    INNER JOIN Stores AS st
        ON s.store_id = st.store_id
    GROUP BY
        s.store_id,
        st.store_name,
        YEAR(s.sale_date)
),

growth_data AS
(
    SELECT
        store_id,
        store_name,
        sales_year,
        total_sales,
        LAG(total_sales) OVER
        (
            PARTITION BY store_id
            ORDER BY sales_year
        ) AS previous_year_sales
    FROM yearly_sales
)

SELECT
    store_name,
    sales_year,
    previous_year_sales,
    total_sales AS current_year_sales,
    ROUND(
        ((total_sales - previous_year_sales) * 100.0)
        / previous_year_sales,
        2
    ) AS growth_percentage
FROM growth_data
WHERE previous_year_sales IS NOT NULL
ORDER BY
    store_name,
    sales_year;

/*=====================================================
--18.Calculate the correlation between product price and warranty claims for products sold in the tast five years, segmented by price range.
=====================================================*/
	
SELECT
    CASE
        WHEN p.price < 500 THEN 'Low Cost'
        WHEN p.price BETWEEN 500 AND 1000 THEN 'Moderate Cost'
        ELSE 'High Cost'
    END AS price_segment,
    COUNT(w.claim_id) AS total_warranty_claims
FROM Warranty AS w
INNER JOIN Sales AS s
    ON w.sale_id = s.sale_id
INNER JOIN Products AS p
    ON s.product_id = p.product_id
WHERE s.sale_date >= DATEADD(
        YEAR,
        -5,
        (SELECT MAX(sale_date) FROM Sales)
)
GROUP BY
    CASE
        WHEN p.price < 500 THEN 'Low Cost'
        WHEN p.price BETWEEN 500 AND 1000 THEN 'Moderate Cost'
        ELSE 'High Cost'
    END
ORDER BY
    total_warranty_claims DESC;

/*=====================================================
--19.Identify the store with the highest percentage of "Completed" claims relative to total claims filed
=====================================================*/

WITH completed_claims AS
(
    SELECT
        s.store_id,
        COUNT(w.claim_id) AS completed_claims
    FROM Sales AS s
    INNER JOIN Warranty AS w
        ON s.sale_id = w.sale_id
    WHERE w.repair_status = 'Completed'
    GROUP BY s.store_id
),

total_claims AS
(
    SELECT
        s.store_id,
        COUNT(w.claim_id) AS total_claims
    FROM Sales AS s
    INNER JOIN Warranty AS w
        ON s.sale_id = w.sale_id
    GROUP BY s.store_id
)

SELECT TOP 1
    st.store_name,
    tc.total_claims,
    cc.completed_claims,
    ROUND(
        (cc.completed_claims * 100.0) / tc.total_claims,
        2
    ) AS completed_percentage
FROM total_claims AS tc
INNER JOIN completed_claims AS cc
    ON tc.store_id = cc.store_id
INNER JOIN Stores AS st
    ON tc.store_id = st.store_id
ORDER BY completed_percentage DESC;

/*=====================================================
--20.Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period.
=====================================================*/
	
WITH monthly_sales AS
(
    SELECT
        s.store_id,
        st.store_name,
        YEAR(s.sale_date) AS sales_year,
        MONTH(s.sale_date) AS sales_month,
        SUM(p.price * s.quantity) AS total_sales
    FROM Sales AS s
    INNER JOIN Products AS p
        ON s.product_id = p.product_id
    INNER JOIN Stores AS st
        ON s.store_id = st.store_id
    WHERE s.sale_date >= DATEADD(
            YEAR,
            -4,
            (SELECT MAX(sale_date) FROM Sales)
    )
    GROUP BY
        s.store_id,
        st.store_name,
        YEAR(s.sale_date),
        MONTH(s.sale_date)
)

SELECT
    store_id,
    store_name,
    sales_year,
    sales_month,
    total_sales,
    SUM(total_sales) OVER
    (
        PARTITION BY store_id
        ORDER BY sales_year, sales_month
        ROWS UNBOUNDED PRECEDING
    ) AS running_total_sales
FROM monthly_sales
ORDER BY
    store_id,
    sales_year,
    sales_month;
