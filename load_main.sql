DELETE FROM index_duration;
DELETE FROM stock_values;
DELETE FROM company_industry;
DELETE FROM company;

-- Load company table
/*
No null rows
Fuzzy string closest symbol to name match
Install levenshtein addon: create extension fuzzystrmatch
https://www.postgresql.org/docs/current/fuzzystrmatch.html#FUZZYSTRMATCH-LEVENSHTEIN
https://www.postgresql.org/docs/current/sql-select.html
*/
INSERT INTO company (symbol, name)
SELECT DISTINCT ON (symbol) -- only one row for each symbol is returned
    symbol,
    name
FROM staging
WHERE symbol IS NOT NULL
    AND name IS NOT NULL
ORDER BY symbol, levenshtein(name, symbol) ASC
;

-- Load name table
/*
Convert all first letter in every word to uppercase and rest of word to lowercase
https://www.postgresql.org/docs/9.1/functions-string.html
*/
INSERT INTO company_industry(symbol, industry)
SELECT DISTINCT
    symbol,
    INITCAP(REPLACE(industry, '&', 'AND')) as industry
FROM staging
WHERE symbol IS NOT NULL
AND industry IS NOT NULL
;

--Load numerical table
/*
Replace all non numerical values such as '-' with NULL
Convert all 5,000 -> 5000
Create a function
https://www.postgresql.org/docs/current/plpgsql-declarations.html
https://www.postgresql.org/docs/current/sql-alterfunction.html
*/
-- Drop and create cleaning function for numeric data
DROP FUNCTION IF EXISTS convert_to_numeric;
CREATE OR REPLACE FUNCTION convert_to_numeric(input VARCHAR) RETURNS NUMERIC AS $$
DECLARE result NUMERIC;
BEGIN
    -- Try to cast input value to numeric, if an exception occurs set result to null
    BEGIN
        result := input::NUMERIC;
    EXCEPTION
        WHEN OTHERS THEN
            result := NULL;
    END;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;
-- pass ownership
ALTER FUNCTION convert_to_numeric(varchar) OWNER TO user_1;
-- Not scalable to use distinct (entire row) to drop duplicate rows during load
-- This approach uses window function on key( symbol, reporting_date)
INSERT INTO stock_values 
(symbol, report_date, equity_cap, free_float_cap, beta, volatility_per, monthly_return, weightage, r2, avg_impact)
WITH rowcounts_staging AS (
    SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY (symbol, report_date::DATE)) as row_count
    FROM staging
)
SELECT
    symbol,
    report_date::DATE as report_date,
    -- This column contains ints with and without , separators
    NULLIF(REPLACE(equity_cap, ',', '')::NUMERIC::BIGINT , NULL) as equity_cap,
    NULLIF(REPLACE(free_float_cap, ',', '')::NUMERIC::INT, NULL) as free_float_cap,
    -- These columns have non numeric data in them, the cleaning steps are in the above function
    convert_to_numeric(beta) as beta,
    convert_to_numeric(volatility_per) as volatility_per,
    convert_to_numeric(monthly_return) as monthly_return,
    convert_to_numeric(weightage) as weightage,
    convert_to_numeric(r2) as r2,
    convert_to_numeric(avg_impact) as avg_impact
FROM rowcounts_staging
WHERE row_count = 1
;

-- Load duration table
/*
https://www.postgresqltutorial.com/postgresql-date-functions/postgresql-extract/
*/

INSERT INTO index_duration(symbol, start_date, end_date, duration_months, duration_present_months, consecutive)
WITH rowcounts_staging AS (
    SELECT 
    symbol,
    report_date,
    ROW_NUMBER() OVER (PARTITION BY (symbol, report_date::DATE)) as row_count
    FROM staging
),
index_duration_intermediate AS (
    SELECT
    symbol,
    MIN(report_date::DATE) as start_date,
    MAX(report_date::DATE) as end_date,
    12*(EXTRACT(YEAR FROM MAX(report_date::DATE)) - EXTRACT(YEAR FROM MIN(report_date::DATE))) +
    (EXTRACT(MONTH FROM MAX(report_date::DATE)) - EXTRACT(MONTH FROM MIN(report_date::DATE))) 
    + 1 as duration_months,
    COUNT(*) as duration_present_months
    FROM rowcounts_staging
    WHERE row_count = 1
    GROUP BY symbol
)
select *,
CASE 
    WHEN duration_present_months < duration_months THEN 0
    WHEN duration_present_months = duration_months THEN 1
    ELSE -1 -- to catch errors where (duration_present_months > duration_months)
END AS consecutive
FROM index_duration_intermediate
;