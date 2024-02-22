### Project goals
This goals of this project are to design a database to store the provided data, create tables and optimise them for the given queries, load the data, and run a few queries on it. I use a Postgresql as the database and sql/plsql to perform the operations, and python for the last query.

### Problems with data
The data has some inconsistencies and errors which need to be cleaned. I clean the data during ingestion to ensure that the loaded data is clean.
* Duplicate rows
There are duplicate rows which can be identified by multiple entries in the key (symbol, report_date)
* Numeric data in different format
Numbers are in different formats. 5000 might be represented as 5,000 or 5000.
In some columns that are supposed to be integer values like free_float_cap, there are some numbers with decimal points.
* Wrong format for a column
In some columns which are supposed to be numerical, there are some values that are not numbers like `-`
* Strings can be the same word in lowercase or uppercase
* Some data is in the wrong column (ie:industry in the name column)

![My Image](/images/image3.png "Schema")

* Inconsistency in usage of `'&'` and `'AND'`

![My Image](/images/image5.png "Schema")

* Rows with missing values

![My Image](/images/image2.png "Schema")

### Design:

![My Image](/images/image1.png "Schema")

**Symbol** is used as the primary key for **company name** and **industry**. These tables are separated to reduce data redundancy because symbol has a 1-1 relationship with name, and a 1-many relationship with industry (eg: GRASIM has industries in textiles and cement). Company has primary key on (symbol), and is used as the table by which other tables refer their foreign keys to. Company_industry has primary key on (symbol, industry) and foreign key on (symbol). There are indexes on their primary keys to improve query performance.

**Stock_values** has the primary key(symbol, report_date) and stores all the numerical data because during loading there will always be numerical finance data added to the database, by consolidating all the numerical values into a table only 1 table needs to be updated. The data types of the table are chosen based on the storage requirements of each column's data to minimise storage space wastage. There is a primary key on (symbol, report_date), a foreign key on (symbol). To optimise performance of queries: the database is partitioned on report_date by year.

I considered added an index on (symbol, date) to speed up all time based queries (SMA, high, low, correlation), but the overhead of maintaining this index is too high.

**Index_duration** contains data on the duration that a stock has been inside the NIFTY index and has a primary key on (symbol). I store that starting date, ending date of a stock inside the index as well as the duration in months between these dates, the number months that it was part of the index with duration_present_months because stocks get placed in and taken out of the index, the last column indicates whether the stock was consecutively in the index (0 False, 1 True). I use smallint to store the data. There is a foreign key on (symbol). If there are errors in the months calculation, we do not need to update the stock_values table to fix them.

This design is normalised to 3NF by meeting the conditions: atomic values, no partial dependencies, no transitive dependencies.

### Database loading:
My code can be run with `run.sh` which creates the tables, loads the data into a staging table, cleans the data, and loads into their destination tables.

Data is loaded into staging with `load_stage.sql` with the numerical column data types as VARCHAR which preserves the exact values in the source data, so as to set a foundation for cleaning later on.

`load_main.sql` loads the data into the destination tables, it creates table company first since it is referred to be other tables.

**Company table**:

Rows with null in symbol or name are dropped and we assume that the right matching of symbol to name is in the remaining rows. Then I use fuzzy string mapping to match the closest name to the symbol to ensure correctness (look in image of TATAMOTORS above)
- Eliminate rows with null values in the symbol or name columns.
- Utilize fuzzy string matching (Levenshtein distance) and DISTINCT ON to find the closest symbol match for each name.

**Company_industry table**:
- Convert all first letters in every word of the industry column to uppercase and the rest to lowercase 
- replace '&' with 'AND'

**Stock_values table**:

There are many values of (symbol,report_date) so using a distinct will not be scalable. Instead I use a window function with row_count to eliminate duplicate rows.
- Replace all non-numerical values (e.g., '-') with NULL.
- Convert numeric values with commas (e.g., 5,000) to integer format.
- Create a cleaning function (convert_to_numeric) to handle numeric conversions for specific columns.

**Index_duration table**:

Eliminate duplicate rows with the same approach as above.
- Calculate the start and end dates, duration in months, and the count of present months for each symbol.
- Determine the consecutiveness of the data based on the calculated values.
- -1 is a possible value in `consistency` to detect calculate errors.

The steps in the data loading were designed to ensure cleanliness of the loaded data in the destination table, includes considerations for scaiability by dropping duplicate rows with scalable methods, and table optimisations to support query performance. **There were 50 duplicate rows detected and were not loaded because of these methods.**
