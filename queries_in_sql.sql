
-- Write query to get year wise number of stocks per industry
WITH a AS (
SELECT
    a.symbol,
    a.industry,
    EXTRACT(YEAR FROM report_date) AS year
FROM
    company_industry a
    INNER JOIN stock_values b ON a.symbol = b.symbol
)

SELECT
    year,
    industry,
    COUNT(DISTINCT(symbol)) AS symbol_count
FROM
    a
GROUP BY
    year, industry;

-- Stocks that were part of index for longest and shortest duration
WITH a as (
SELECT
    MAX(duration_present_months) as max,
    MIN(duration_present_months) as min
FROM index_duration
)
SELECT
    symbol, duration_present_months
FROM index_duration
WHERE duration_present_months = (select max from a)
    OR duration_present_months = (select min from a)
ORDER BY duration_present_months desc, symbol
;

-- Calculate moving averate for Equity capital of tickers 6 months window. Window size should be adjustable
DROP FUNCTION IF EXISTS moving_average;

CREATE OR REPLACE FUNCTION moving_average(months INT) 
RETURNS TABLE (
    symbol VARCHAR(255),
    report_date DATE,
    equity_cap BIGINT,
    moving_average NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH MA AS (SELECT
                stock_values.symbol,
                stock_values.report_date,
                stock_values.equity_cap,
                AVG(stock_values.equity_cap) OVER (PARTITION BY stock_values.symbol
                                                    ORDER BY stock_values.symbol ASC, 
                                                    stock_values.report_date ASC ROWS 
                                                    BETWEEN months-1 PRECEDING AND CURRENT ROW) AS moving_average
                FROM stock_values
                ORDER BY symbol ASC, report_date ASC)
    SELECT * FROM MA;
END;

$$ LANGUAGE plpgsql;
SELECT * FROM moving_average(6); -- function call on MA 6 months


-- Calculate year wise high and low Equity Capital for each stock
SELECT
symbol,
EXTRACT(YEAR FROM report_date) AS year,
MIN(equity_cap) AS year_low_equity,
MAX(equity_cap) AS year_high_equity
FROM stock_values
GROUP BY symbol, year
ORDER BY symbol, year;


-- Find tickers with highest and highest inverse correlation of price movement
-- I was unable to do this in SQL and did an implementation of Q3-5 in Python

/*
Loop over stock symbols
Create pivot table first
Calculate correlation
Get table with columns stock_1, stock_2, correlation

https://www.postgresql.org/docs/current/plpgsql-control-structures.html#PLPGSQL-CONTROL-STRUCTURES-LOOPS
https://www.postgresql.org/docs/current/plpgsql-control-structures.html#PLPGSQL-RECORDS-ITERATING
https://www.postgresql.org/docs/current/tablefunc.html
*/






