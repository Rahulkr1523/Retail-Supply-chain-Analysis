use retail;

# ======================================CUSTOMER - SEGMENTATION==============================================

# 1. Categorize customers into different age groups (18-25, 26-35, etc.) and count the number of customers in each group ?
SELECT 
    CASE 
        WHEN Timestampdiff(YEAR, birthdate, CURDATE())           < 18 THEN  '0-18'
        WHEN TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) BETWEEN 18 AND 25 THEN '18-25'
        WHEN TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) BETWEEN 26 AND 35 THEN '26-35'
        WHEN TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) BETWEEN 36 AND 45 THEN '36-45'
        WHEN TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) BETWEEN 46 AND 55 THEN '46-55'
	    WHEN TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) BETWEEN 56  AND 65 THEN '56-65'
        ELSE '65+' 
    END AS age_group, COUNT(customer_id) AS customer_count FROM Customers GROUP BY age_group ORDER BY age_group;
    
# 2. Count the number of male and female customers. Check if there is a gender imbalance ? 
select gender, count(*) as Gender_count from customers group by gender;

# 3.Find the top stores with the highest number of loyal customers
select * from customers;
select home_store, count(loyalty_card_number) as Loyal_customers from customers group by home_store
order by count(loyalty_card_number) desc;

# 4.Analyze customer retention trends by counting how many customers joined each year ?
SELECT YEAR(customer_since) AS join_year, COUNT(*) AS customer_count
FROM Customers GROUP BY join_year ORDER BY join_year;

# 5.Find the top 5 stores with the highest number of customers
SELECT home_store , COUNT(*) as customer_count from customers group by home_store order by count(*) desc limit 5;

# 6 Find the Top  5  most common email- domain used by the customers ?
select substring_index(customer_email,'@',-1) as email_domain, count(*) as domain_count from customers
group by email_domain order by count(*) desc  limit 5;

# 7.Analyze the loyalty card usage pattern across different age groups. Identify whether younger or older customers use loyalty cards more?
SELECT 
    CASE 
        WHEN Timestampdiff(YEAR, birthdate, CURDATE())           < 18 THEN  '0-18'
        WHEN TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) BETWEEN 18 AND 25 THEN '18-25'
        WHEN TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) BETWEEN 26 AND 35 THEN '26-35'
        WHEN TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) BETWEEN 36 AND 45 THEN '36-45'
        WHEN TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) BETWEEN 46 AND 55 THEN '46-55'
	    WHEN TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) BETWEEN 56  AND 65 THEN '56-65'
        ELSE '65+' 
    END AS age_group, COUNT(loyalty_card_number) AS loyalty_cards_count FROM Customers GROUP BY age_group ORDER BY loyalty_cards_count desc;
 
 # ===========================================INVENTORY - ANALYSIS ===========================================================
 
 
# 8.Analyze the current inventory levels to identify products that are running low and may require restocking ?   
select i.sales_outlet_id,P.product, i.start_of_day as current_stock from inventory i
join products P on i.product_id = P.product_id where start_of_day < 10;

# 9. Identify products that have high stock levels but low sales over time.
# These products may be overstocked and should be considered for discounts or promotions ?
SELECT 
    i.sales_outlet_id AS Store_Id, i.start_of_day AS Total_Stock, i.quantity_sold AS Total_Sales, p.product_id, p.product
FROM inventory i
INNER JOIN products p ON i.product_id = p.product_id
WHERE i.start_of_day > 40 -- More than 80% of max stock
AND i.quantity_sold < 10   -- Less than 120% of avg sales
ORDER BY i.start_of_day DESC;

/* 10.Identify products that have a high sales-to-stock ratio, meaning they are selling quickly compared to their available inventory.
These products are in high demand and may require frequent restocking to prevent stockouts ? */

SELECT i.sales_outlet_id AS Store_Id, p.product_id, p.product, i.start_of_day AS Total_Stock, i.quantity_sold AS Total_Sales
FROM inventory i INNER JOIN products p ON i.product_id = p.product_id WHERE i.quantity_sold > (i.start_of_day * 0.8)  
AND i.start_of_day < (SELECT AVG(start_of_day) FROM inventory) ORDER BY i.quantity_sold DESC;

#  11. Identify products that have high sales fluctuations based on different time periods (e.g., months or quarters)?
SELECT i.product_id, d.Month_Name, SUM(i.quantity_sold) AS total_sales FROM inventory i
JOIN dates d ON i.transaction_date = d.transaction_date GROUP BY i.product_id, d.Month_Name
ORDER BY i.product_id, total_sales DESC;

# 12.Calculate the Inventory Turnover Ratio for each product. This ratio helps determine how efficiently inventory is being sold and replaced ?
SELECT 
    P.product, i.product_id, SUM(i.quantity_sold) AS Total_sale, AVG(i.start_of_day) AS Avg_inventory, 
    SUM(i.quantity_sold) / AVG(i.start_of_day) AS Turnover_ratio  FROM inventory i 
INNER JOIN Products P ON i.product_id = P.product_id GROUP BY P.product, i.product_id;

# ============================================= SALES- ANALYSIS =======================================================


# 13. Identify the top 5 best-selling products based on total quantity sold ?
select i.Product_id,P.Product, sum(i.Quantity_sold) as Total_Quantity_Sold from inventory  i inner join
Products P on i.product_id = P.product_id Group by i.product_id, P.Product order by sum(i.Quantity_sold) desc limit 5;

# 14.Analyze the weekly sales trend for April by calculating total sales for each week.
select D.Week_ID, D.Month_Name, sum(i.quantity_sold) As Total_Sale from dates D inner join inventory i
on D.transaction_date = i.transaction_date Group by  D.Week_ID, D.Month_Name;

#   15.Identify the top 3 weeks with the highest sales in April ?
select D.Week_ID, D.Month_Name, sum(i.quantity_sold) As Total_Sale from dates D inner join inventory i
on D.transaction_date = i.transaction_date Group by  D.Week_ID, D.Month_Name order by Total_Sale desc limit 3;

# 16. Determine the percentage contribution of each product to the total sales in April ?
SELECT P.product_id, P.product, SUM(I.quantity_sold) AS Total_Sales, 
(SUM(I.quantity_sold) / (SELECT SUM(quantity_sold) FROM inventory) * 100) AS Sales_Percentage FROM inventory I
INNER JOIN Products P ON I.product_id = P.product_idn GROUP BY P.product_id, P.product ORDER BY Sales_Percentage DESC;

# 16. Identify the product with the highest sales in each week of April ? 
SELECT Week_ID, product_id, product, Total_Sales FROM (
SELECT D.Week_ID, P.product_id, P.product, SUM(I.quantity_sold) AS Total_Sales,
RANK() OVER (PARTITION BY D.Week_ID ORDER BY SUM(I.quantity_sold) DESC) AS rnk
FROM inventory I INNER JOIN Products P ON I.product_id = P.product_id
INNER JOIN dates D ON I.transaction_date = D.transaction_date
GROUP BY D.Week_ID, P.product_id, P.product ) RankedSales WHERE rnk = 1;

# 17. Identify the top 3 sales outlets (stores) with the highest total purchases (quantity sold) in April.
 Select S.Sales_outlet_id as Store_ID, sum(i.quantity_sold) as Total_sale , D.Month_Name from inventory i
 Inner Join Sales_outlet S on i.Sales_outlet_id = S.Sales_outlet_id
 Inner Join Dates D on i.transaction_date = D.transaction_date where D.Month_Name = "April"
 group by S.Sales_outlet_id , D.Month_Name order by Total_sale desc Limit 3;
 
# 18. "Determine the top-selling product category for each sales outlet by analyzing total sales.
       # Identify which sales outlet specializes in which category based on the highest sales ?      
select s.sales_outlet_id as Store_ID, P.product_category, sum(i.quantity_sold) as Total_Sale 
from Products P Inner join  inventory i on p.product_id = i.product_id
Inner join  sales_outlet s on s.sales_outlet_id = i.sales_outlet_id  group by  s.sales_outlet_id , P.product_category;     

# 19 Identify Top 5 products with the highest wastage to help improve inventory management and minimize losses ?
select P.product_id, P.product_category , p.product , sum(i.quantity_sold) as Total_sale, sum(i.waste) as Total_waste from inventory i
Inner Join Products P on i.product_id = P.product_id group by P.product_id, P.product_category , p.product 
order by Total_waste desc ;


# ================================================ 	STORE - ANALYSIS ===============================================================

# 20. Identify the top-performing sales outlets based on total quantity sold. Determine which stores contribute the most to overall sales ?
SELECT S.SALES_OUTLET_ID AS STORE_ID , S.SALES_OUTLET_TYPE AS STORE_TYPE , SUM(I.QUANTITY_SOLD) AS TOTAL_SALE,
(SUM(I.QUANTITY_SOLD) * 100.0) / (SELECT SUM(QUANTITY_SOLD) FROM INVENTORY) AS Sales_Percentage FROM INVENTORY I
INNER JOIN SALES_OUTLET S ON I.SALES_OUTLET_ID = S.SALES_OUTLET_ID GROUP BY  S.SALES_OUTLET_ID , S.SALES_OUTLET_TYPE 
ORDER BY TOTAL_SALE DESC ;

# 21. Analyze sales performance across different store types and determine which type sells the most?
SELECT S.SALES_OUTLET_ID AS STORE_ID , S.SALES_OUTLET_TYPE AS STORE_TYPE , SUM(I.QUANTITY_SOLD) AS TOTAL_SALE,
(SUM(I.QUANTITY_SOLD) * 100.0) / (SELECT SUM(QUANTITY_SOLD) FROM INVENTORY) AS Sales_Percentage FROM INVENTORY I
INNER JOIN SALES_OUTLET S ON I.SALES_OUTLET_ID = S.SALES_OUTLET_ID GROUP BY  S.SALES_OUTLET_ID , S.SALES_OUTLET_TYPE 
ORDER BY TOTAL_SALE DESC limit 1;

# 22. Determine which sales outlets generate the highest average quantity sold per transaction to identify efficient stores with high-volume sales ?
SELECT S.SALES_OUTLET_ID, S.SALES_OUTLET_TYPE, SUM(I.QUANTITY_SOLD) AS TOTAL_SALE, 
COUNT(DISTINCT I.TRANSACTION_DATE) AS TOTAL_TRANSACTIONS,   SUM(I.QUANTITY_SOLD) / COUNT(DISTINCT I.TRANSACTION_DATE) AS AVERAGE_SALES_PER_TRANSACTION  
FROM INVENTORY I INNER JOIN SALES_OUTLET S ON I.SALES_OUTLET_ID = S.SALES_OUTLET_ID 
GROUP BY S.SALES_OUTLET_ID, S.SALES_OUTLET_TYPE 
ORDER BY AVERAGE_SALES_PER_TRANSACTION DESC LIMIT 1;

# 23. Identify stores with the highest sales variability to determine which stores have the most inconsistent sales patterns ?
SELECT S.SALES_OUTLET_ID AS STORE_ID, S.SALES_OUTLET_TYPE AS STORE_TYPE , stddev(I.QUANTITY_SOLD) AS SALES_VARIABILITY FROM INVENTORY I
INNER JOIN  SALES_OUTLET S ON I.SALES_OUTLET_ID = S.SALES_OUTLET_ID GROUP BY S.SALES_OUTLET_ID , S.SALES_OUTLET_TYPE ORDER BY SALES_VARIABILITY DESC;

# =============================================  DONE  =============================================================================================

