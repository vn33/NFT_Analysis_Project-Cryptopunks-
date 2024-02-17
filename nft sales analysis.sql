USE cryptopunk;
-- let's do first analayze the data set
SHOW TABLES;
SELECT * FROM pricedata LIMIT 10;
SELECT * FROM cryptopunkdata WHERE wrapped_punk = "FALSE";

SELECT data_type FROM INFORMATION_SCHEMA.COLUMNS 
WHERE table_name = 'pricedata';

/* 
Question 1:
How many sales occurred during this time period? 
 */
-- SOLUTION: 
-- How many sales occurred during this time period(2018-2021)? 
SELECT COUNT(*) FROM pricedata where YEAR(event_date) BETWEEN 2018 AND 2021;
-- HOW many sales this Dataset contains
SELECT COUNT(*) FROM pricedata;

/*
Question 2: Return the top 5 most expensive transactions (by USD price) for this data set.
 Return the name, ETH price, and USD price, as well as the date.
 */
 -- SOLUTION:
SELECT name, eth_price,usd_price,event_date 
FROM pricedata
ORDER BY USD_price DESC
LIMIT 5;

/*
Question 3: Return a table with a row for each transaction with an event column, a USD price
column, and a moving average of USD price that averages the last 50 transactions.
*/
-- SOLUTION:
SELECT 
name,
usd_price,
event_date,
  AVG(usd_price) OVER (ORDER BY event_date ROWS BETWEEN 50 PRECEDING AND CURRENT ROW) AS moving_avg
FROM pricedata;

/*
Question 4:Return all the NFT names and their average sale price in USD.
Sort descending. Name the average column as average_price.
*/
-- SOLUTION:
SELECT name, AVG(usd_price) AS average_price FROM pricedata
GROUP BY name
ORDER BY average_price DESC;

/*
Question 5:Return each day of the week and the number of sales that occurred on
that day of the week, as well as the average price in ETH.
Order by the count of transactions in ascending order.
*/
-- SOLUTION:
SELECT 
DAYNAME(event_date) AS day_of_week,
COUNT(*) AS number_of_sales,
AVG(eth_price) AS average_eth_price
FROM pricedata
GROUP BY day_of_week
ORDER BY number_of_sales ASC;

/*
Question 6: Construct a column that describes each sale and is called summary.
The sentence should include who sold the NFT name, who bought the NFT, who sold the NFT, 
the date, and what price it was sold for in USD rounded to the nearest thousandth.
 Here’s an example summary:
 “CryptoPunk #1139 was sold for $194000 to 
 0x91338ccfb8c0adb7756034a82008531d7713009d from 
 0x1593110441ab4c5f2c133f21b0743b2b43e297cb on 2022-01-14”
 */
 -- SOLUTION:
SELECT CONCAT(
name," was sold for $",
ROUND(usd_price,-3),
" to ",
buyer_address,
" from ",
seller_address,
" on ",
event_date
) AS summary
FROM pricedata;

/* 
Question 7:Create a view called “1919_purchases” and contains any sales where 
“0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685” was the buyer.
*/
-- SOLUTION:
CREATE VIEW 1919_purchases AS
SELECT * FROM pricedata
WHERE buyer_address = "0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685";

SELECT * FROM 1919_purchases;

/*
Question 8:Create a histogram of ETH price ranges. Round to the nearest hundred value. 
*/
-- SOLUTION:
SELECT ROUND(eth_price,-2) AS bucket,
COUNT(*) AS count,
RPAD(' ',COUNT(*),'*') AS bar
FROM pricedata
GROUP BY bucket
ORDER BY bucket;

/* 
Question 9:Return a unioned query that contains the highest price each NFT was bought for 
and a new column called status saying “highest” with a query that has the lowest price 
each NFT was bought for and the status column saying “lowest”. 
The table should have a name column, a price column called price, and a status column. 
Order the result set by the name of the NFT, and the status, in ascending order. 
*/
-- SOLUTION:
-- Highest price for each NFT
SELECT
  name,
  MAX(usd_price) AS bought_price,
  'highest' AS status
FROM pricedata
GROUP BY name
UNION
-- Lowest price for each NFT
SELECT
  name,
  MIN(usd_price) AS bought_price,
  'lowest' AS status
FROM pricedata
GROUP BY name
ORDER BY name, status ASC;

/* 
Question 10:What NFT sold the most each month / year combination? Also, what was the name 
and the price in USD? Order in chronological format. 
*/
-- SOLUTION:
SELECT YEAR(event_date) AS year,
MONTH(event_date) AS month,
name,
usd_price,
DENSE_RANK() OVER(PARTITION BY YEAR(event_date),MONTH(event_date) ORDER BY usd_price DESC) AS NFT_sold_month_per_year
FROM pricedata;

/*
Question 11:Return the total volume (sum of all sales), round to the nearest 
hundred on a monthly basis (month/year).
*/
-- SOLUTION:
SELECT
  YEAR(event_date) AS sales_year,
  MONTH(event_date) AS sales_month,
  ROUND(SUM(usd_price), -2) AS total_volume
FROM
  pricedata
GROUP BY
  sales_year, sales_month
ORDER BY
  sales_year, sales_month;
  
  
/*
Question 12:Count how many transactions the wallet "0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685"had over this time period.
*/
-- SOLUTION:
SELECT COUNT(*) AS transaction_count
FROM pricedata
WHERE seller_address = "0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685" OR buyer_address = "0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685";

/*
Question 13: Create an “estimated average value calculator” that has a representative price of 
the collection every day based off of these criteria:
 - Exclude all daily outlier sales where the purchase price is below 10% of the daily average price
 - Take the daily average of remaining transactions
 a) First create a query that will be used as a subquery. Select the event date, the USD price, 
 and the average USD price for each day using a window function. Save it as a temporary table.
 b) Use the table you created in Part A to filter out rows where the USD prices is below 
 10% of the daily average and return a new estimated value which is just the daily 
 average of the filtered data
*/
-- SOLUTION:
CREATE TEMPORARY TABLE temp_daily_avg AS
SELECT
  event_date,
  usd_price,
  AVG(usd_price) OVER (PARTITION BY event_date) AS daily_avg
FROM pricedata;
 
SELECT event_date,
  AVG(usd_price) AS estimated_value
FROM temp_daily_avg
WHERE
  usd_price >= 0.1 * daily_avg
GROUP BY event_date
ORDER BY event_date;

/*
Question 14: Give a complete list ordered by wallet profitability 
(whether people have made or lost money)
*/
-- SOLUTION:
SELECT
  buyer_address,
  SUM(eth_price - usd_price) AS net_profit
FROM
  pricedata
GROUP BY
  buyer_address
ORDER BY
  net_profit DESC;



