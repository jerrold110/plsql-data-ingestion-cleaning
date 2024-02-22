DROP TABLE index_duration;
DROP TABLE stock_values;
DROP TABLE company_industry;
DROP TABLE company;
DROP TABLE staging;

CREATE TABLE IF NOT EXISTS staging (
    symbol VARCHAR(100),
    name VARCHAR(255),  
    industry VARCHAR(255),  
    equity_cap VARCHAR(255),    --numeric
    free_float_cap VARCHAR(255),     --numeric
    weightage VARCHAR(255),
    beta VARCHAR(255),
    r2 VARCHAR(255),
    volatility_per VARCHAR(255),
    monthly_return VARCHAR(255),    --numeric
    avg_impact VARCHAR(255),
    report_date DATE
);
-- company (primary key table to be used as foreign keys in other tables)
-- index on symbol
CREATE TABLE IF NOT EXISTS company (
    symbol VARCHAR(100),
    name VARCHAR(200),
    PRIMARY KEY (symbol)
);
CREATE INDEX idx_company_symbol ON company(symbol);

CREATE TABLE IF NOT EXISTS company_industry (
    symbol VARCHAR(100),
    industry VARCHAR(200),
    PRIMARY KEY (symbol, industry),
    FOREIGN KEY (symbol) REFERENCES company(symbol)
);
CREATE INDEX idx_industry ON company_industry(symbol, industry);

-- stock_values
-- partition on report_date, index on symbol, date
/*
To create a unique or primary key constraint on a partitioned table, the partition keys must not include any expressions or function calls and the constraint's columns must include all of the partition key columns. This limitation exists because the individual indexes making up the constraint can only directly enforce uniqueness within their own partitions; therefore, the partition structure itself must guarantee that there are not duplicates in different partitions.
*/
CREATE TABLE IF NOT EXISTS stock_values (
    symbol VARCHAR(100),
    report_date DATE,
    equity_cap BIGINT,
    free_float_cap INT,
    beta NUMERIC(8,5),
    volatility_per NUMERIC(8,5),
    monthly_return NUMERIC(8,5),
    weightage NUMERIC(5,2),
    r2 NUMERIC(8,5),
    avg_impact NUMERIC(5,2),
    FOREIGN KEY (symbol) REFERENCES company(symbol)
) PARTITION BY RANGE (report_date);
CREATE TABLE stock_values_2008 PARTITION OF stock_values
    FOR VALUES FROM ('2008-01-01') TO ('2009-01-01');
CREATE TABLE stock_values_2009 PARTITION OF stock_values
    FOR VALUES FROM ('2009-01-01') TO ('2010-01-01');
CREATE TABLE stock_values_2010 PARTITION OF stock_values
    FOR VALUES FROM ('2010-01-01') TO ('2011-01-01');
CREATE TABLE stock_values_2011 PARTITION OF stock_values
    FOR VALUES FROM ('2011-01-01') TO ('2012-01-01');
CREATE TABLE stock_values_2012 PARTITION OF stock_values
    FOR VALUES FROM ('2012-01-01') TO ('2013-01-01');
CREATE TABLE stock_values_2013 PARTITION OF stock_values
    FOR VALUES FROM ('2013-01-01') TO ('2014-01-01');
CREATE TABLE stock_values_2014 PARTITION OF stock_values
    FOR VALUES FROM ('2014-01-01') TO ('2015-01-01');
CREATE TABLE stock_values_2015 PARTITION OF stock_values
    FOR VALUES FROM ('2015-01-01') TO ('2016-01-01');
CREATE TABLE stock_values_2016 PARTITION OF stock_values
    FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');
CREATE TABLE stock_values_2017 PARTITION OF stock_values
    FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');
CREATE TABLE stock_values_2018 PARTITION OF stock_values
    FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');
CREATE TABLE stock_values_2019 PARTITION OF stock_values
    FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');
CREATE TABLE stock_values_2020 PARTITION OF stock_values
    FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');
ALTER TABLE stock_values ADD PRIMARY KEY (symbol, report_date);

-- index_duration
-- index on symbol
CREATE TABLE IF NOT EXISTS index_duration (
    symbol VARCHAR(100),
    start_date DATE,
    end_date DATE,
    duration_months SMALLINT,
    duration_present_months SMALLINT,
    consecutive SMALLINT,
    PRIMARY KEY (symbol),
    FOREIGN KEY (symbol) REFERENCES company(symbol)
);
CREATE INDEX idx_index_duration_symbol ON index_duration(symbol);
