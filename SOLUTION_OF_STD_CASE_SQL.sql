--Beginner questions and solutions

--(1)Retrieve all records
SELECT *
FROM std_infection_rates_in_america;

--(2)TOTAL STD CASES 
SELECT SUM("STD_Cases")
FROM std_infection_rates_in_america;

--(3)NUMBER OF UNIQUE DISEASE
SELECT COUNT(DISTINCT "Disease")
FROM std_infection_rates_in_america;

--(4)STATES WHERE STD's WHERE REPORTED
SELECT DISTINCT "State"
FROM std_infection_rates_in_america
WHERE "STD_Cases" >= 1; 

--(5)TOTAL NUMBER OF STD CASES IN YEAR 2000
SELECT SUM("STD_Cases")
FROM std_infection_rates_in_america
WHERE "Year" = 2000;

--(6)STATES WITH HIGHEST POPULATION
SELECT "State"
FROM std_infection_rates_in_america
ORDER BY "Population" DESC
LIMIT 1;

--(7)TOP 5 STD CASES BY YEARS
SELECT "Year", SUM("STD_Cases") AS Top_STD_Cases
FROM std_infection_rates_in_america
WHERE "STD_Cases" IS NOT NULL
GROUP BY "Year"
ORDER BY SUM("STD_Cases") DESC
LIMIT 5;

--(8)MOST REPORTED STD
SELECT "Disease", SUM("STD_Cases") AS STD_per_Disease
FROM std_infection_rates_in_america
WHERE "STD_Cases" IS NOT NULL
GROUP BY "Disease"
ORDER BY "Disease" DESC
LIMIT 1;

--(9)Records of STD Cases per Gender
SELECT "Gender", SUM("STD_Cases") AS STD_per_Gender
FROM std_infection_rates_in_america
WHERE "STD_Cases" IS NOT NULL
GROUP BY "Gender"
ORDER BY SUM("STD_Cases") DESC;

--(10)State by STD_Rate_Per_100k
SELECT "State", SUM("STD_Cases")/SUM("Population")* 100000 AS STD_Rate_Per_100k
FROM std_infection_rates_in_america
WHERE "STD_Cases" IS NOT NULL AND "Population" IS NOT NULL
GROUP BY "State"
ORDER BY STD_Rate_Per_100K DESC;




----Intermediate-Level SQL Questions using CTEs (Common Table Expressions) 

--(1)Find the total STD cases for each state and rank them
SELECT "State",
   SUM("STD_Cases") as total_cases,
   RANK() OVER (ORDER BY SUM("STD_Cases")DESC) AS rnk
FROM std_infection_rates_in_america
GROUP BY "State"
HAVING "State" is not null and SUM("STD_Cases") is not null;


--(2)Identify states where STD cases increased over consecutive years

WITH std_cases AS (
    SELECT 
        "State", 
        "Year", 
        SUM("STD_Cases") AS total_cases,
        LAG( SUM("STD_Cases")) OVER (PARTITION BY "State" ORDER BY "Year") AS previous_year_cases
    FROM 
        std_infection_rates_in_america
    GROUP BY 
        "State", "Year"
)
SELECT 
    "State",
    "Year",
    total_cases,
    previous_year_cases
FROM 
    std_cases
WHERE 
    total_cases > previous_year_cases;
  
  
--3. Calculate the average STD cases per year for each disease


WITH total_cases AS (

	SELECT
		"Year",
	    "Disease",
	     sum("STD_Cases") as total_std_cases,
	     AVG(sum("STD_Cases")) OVER(PARTITION BY"Disease" ORDER BY "Year") AS avg_std_cases
	FROM
	     std_infection_rates_in_america
	GROUP BY 	
		"Year",
	    "Disease"
	)
	
	SELECT
		total_std_cases,
		"Year",
	    "Disease",
	    avg_std_cases
    FROM 
    	total_cases
    WHERE
    	total_cases IS NOT NULL
 	      AND "Disease" IS NOT NULL
	;
	
	
--(4) Find the top 3 most affected age groups per disease
WITH ranked_cases AS (

	SELECT
		"Age",
		"Disease",
		SUM("STD_Cases") AS total_cases,
		RANK() OVER (PARTITION BY "Disease" ORDER BY SUM("STD_Cases")DESC) AS rank
	FROM
		std_infection_rates_in_america
		
	GROUP BY
		"Age","Disease"
)

	SELECT
		"Age",
		"Disease",
		total_cases,
		rank
	FROM
		ranked_cases
	WHERE
		rank < 4
	    AND total_cases is not null;
		
	
	--(5) Calculate the year-over-year percentage change in STD cases
	WITH current_year_change AS(
		SELECT 
			"Year",
			"Disease",
			SUM("STD_Cases") as current_year_cases
		FROM
			std_infection_rates_in_america
		GROUP BY
			"Year",
			"Disease"
	),
		present_year_change AS (
			SELECT
				"Year",
				"Disease",
			     current_year_cases,
			     lag(current_year_cases) OVER(partition by "Disease" order by "Year") as previous_year_cases
			FROM
				current_year_change
		
	)
	
SELECT
		"Year",
		"Disease",
	     current_year_cases,
		 previous_year_cases,
	     ((current_year_cases - previous_year_cases) / previous_year_cases) * 100 as percentage_change
FROM
			present_year_change
WHERE previous_year_cases IS NOT NULL 
;



--(6) Find states where the STD rate per 100K people is higher than the national average for a given year.
	

WITH national_rate AS (
	SELECT	
		"Year",
		(SUM ("STD_Cases") / SUM ("Population")) *100000 as national_average_std_rate
	FROM 
		std_infection_rates_in_america
	GROUP BY "Year"
),


state_rates AS (
  SELECT 
  	"State",
  	"Year",
  	(SUM ("STD_Cases") / SUM ("Population")) *100000 as state_std_rates
  	
  FROM
	std_infection_rates_in_america
  GROUP BY "State" , "Year"
 )
 
 
SELECT
 	sr."Year",
 	sr."State",
 	sr.state_std_rates,
 	nr.national_average_std_rate
 FROM national_rate AS nr
 JOIN state_rates AS sr 
 		ON nr."Year" = sr."Year"
 WHERE state_std_rates > national_average_std_rate
 ;
 		
 
 
 --(7)Find the most common STD by gender in each state
 
WITH std_case AS ( 
	SELECT
		"Disease",
		"Gender",
		"State",
		SUM("STD_Cases") as total_std_case,
		RANK() OVER ( PARTITION BY "Gender","State" ORDER BY SUM("STD_Cases")) DESC AS  most_common_std
	FROM 
		std_infection_rates_in_america
	GROUP BY
		"Disease",
		"Gender",
		"State"
)
SELECT
        "Disease",
		"Gender",
		"State",
	    total_std_case,
	   most_common_std
FROM 
 	std_case
 WHERE  most_common_std = 1 AND total_std_case IS NOT NULL ;


--(8)Calculate the cumulative number of STD cases per year

WITH yearly_cases AS (
SELECT
	SUM("STD_Cases") AS total_std_cases,
	"Year",
	"Disease"
 FROM
	std_infection_rates_in_america
 GROUP BY "Year", "Disease"
)
SELECT 
    "Year",
	"Disease",
    total_std_cases,
    SUM(total_std_cases) OVER (
        PARTITION BY "Disease" 
        ORDER BY "Year" 
    ) AS cumulative_cases
FROM yearly_cases
ORDER BY    "Year","Disease";



--10 Identify the first year when a state's STD cases exceeded its 10-year averag

WITH stdcases AS (
    SELECT
        "State",
        "Year",
        "STD_Cases",
        ROW_NUMBER() OVER (PARTITION BY "State" ORDER BY "Year") AS rn
    FROM std_infection_rates_in_america
),
ten_year_avg AS (
    SELECT
        "State",
        AVG("STD_Cases") AS avg_cases
    FROM stdcases
    WHERE rn <= 10
    GROUP BY "State"
),
combined AS (
    SELECT
        s."State",
        s."Year",
        s."STD_Cases",
        t.avg_cases
    FROM stdcases s
    JOIN ten_year_avg t ON s."State" = t."State"
    WHERE s."STD_Cases" > t.avg_cases
),
first_exceed_year AS (
    SELECT
        "State",
        MIN("Year") AS first_year_exceeded
    FROM combined
    GROUP BY "State"
)
SELECT *
FROM first_exceed_year
ORDER BY "State";




--intermediate-level SQL questions 


--1 Find the state with the highest number of STD cases in a given year(2015)
SELECT
	"State",
	"Year",
	SUM("STD_Cases") as highest_cases
 FROM std_infection_rates_in_america
 WHERE "Year" = 2005
 GROUP BY "State", "Year"
 ORDER BY highest_cases desc
 LIMIT 1;


--2 Calculate the yearly trend of STD cases
SELECT
	"Year",
	SUM("STD_Cases") AS std_cases
FROM std_infection_rates_in_america
WHERE "Year"  IS NOT NULL
GROUP BY "Year"
ORDER BY "Year";


--3. Find the most common STD by gender
SELECT
	"Gender",
	"Disease",
	SUM("STD_Cases") as most_common_std
FROM std_infection_rates_in_america
GROUP BY "Gender", "Disease";


--4 Find the top 3 states with the highest STD rate in a given year(2003)

SELECT 
	"State",
	(SUM("STD_Cases") / SUM("Population")) * 100000 as std_rate 
FROM std_infection_rates_in_america
WHERE "Year" = 2003
GROUP BY "State"
ORDER BY std_rate desc
LIMIT 3;

--5 . Identify states where STD cases increased the most year over year

SELECT *
FROM
	(SELECT
	    "State",
	 	"Year",
		SUM("STD_Cases") AS total_cases_this_year,
		lag(SUM("STD_Cases")) OVER (PARTITION BY "State" ORDER BY "Year") AS previous_change,
		SUM("STD_Cases") - LAG(SUM("STD_Cases")) OVER (PARTITION BY "State" ORDER BY "Year") AS change_in_cases
	FROM std_infection_rates_in_america
	GROUP BY "State", "Year") as sub
WHERE change_in_cases is not null and change_in_cases >1
ORDER BY change_in_cases desc;

--6. Find the gender distribution of STD cases over time
Question:
 How has the distribution of STD cases between males and females changed from 1996 to 2008?

 
 WITH yearly_gender_totals AS (
    SELECT 
        "Year",
        "Gender",
        SUM("STD_Cases") AS total_cases
    FROM 
       std_infection_rates_in_america
    WHERE "Year" < 2008
    GROUP BY 
        "Year", "Gender"
),
yearly_totals AS (
    SELECT 
        "Year",
        SUM(total_cases) AS year_total
    FROM 
        yearly_gender_totals
    GROUP BY 
        "Year"
)
SELECT 
    ygt."Year",
    ygt."Gender",
    ygt.total_cases,
   (ygt.total_cases * 100.0 / yt.year_total), 2 AS percentage
FROM 
    yearly_gender_totals ygt
JOIN 
    yearly_totals yt
ON 
    ygt."Year" = yt."Year"
ORDER BY 
    ygt."Year", ygt."Gender";
 
 
 --7.. Find the most affected age group for a specific disease
 
 SELECT 
 	"Age",
 	SUM("STD_Cases") as total_std_cases
FROM std_infection_rates_in_america
WHERE"Disease" = 'Gonorrhea'
GROUP BY "Age"
ORDER BY total_std_cases desc
LIMIT 1;
 	


--8. Compare the rate of STD cases in two different states

SELECT
	"State",
	"Year",
	(SUM("STD_Cases") / SUM("Population")) * 100000 as std_rate
FROM std_infection_rates_in_america
WHERE "State" in ('California', 'Texas')  and "Year" between 2000 and 2008
GROUP BY
	"State", "Year" ;


--9. Identify the states with the lowest STD cases but a high population

 WITH state_totals AS (
  SELECT
    "State",
    SUM("STD_Cases") AS total_std_cases,
    MAX("Population") AS population
  FROM std_infection_rates_in_america
  GROUP BY "State"
),  

 ranked_state AS (
	SELECT
		"State",
		population,
		Percent_rank() OVER(ORDER BY population DESC) AS highest_population,
		Percent_rank() OVER (ORDER BY total_std_cases ASC) AS lowest_std_cases
	FROM state_totals
	
)
SELECT
	"State",
	population,
	highest_population,
    lowest_std_cases
FROM ranked_state 
WHERE highest_population  <= 0.10  AND  lowest_std_cases  <= 0.10
ORDER BY population;


--10. Find the year with the highest rate of increase in STD cases
--Question:
-- Which year saw the largest percentage increase in STD cases compared to the previous year?



	SELECT 
		"Year",
		SUM("STD_Cases") as current_year_cases,
		LAG(current_year_cases) over(order by "Year" desc) as previous_year_case,
		
    FROM std_infection_rates_in_america
    GROUP BY "Year"
 
