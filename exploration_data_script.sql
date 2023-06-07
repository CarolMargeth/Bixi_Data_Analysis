/**********************
BIXI DATA ANALYSIS
Author: Carol Calderon
Date: Jan 29, 2023

Objetive: use what I learned about SQL to dig into the Bixi dataset.
The goal is to gain a high-level understanding of how people use Bixi bikes, 
what factors influence the volume of usage, popular stations, and overall 
business growth.
***********************/

-- Use the proper schema is being used at the start
USE bixi; 

/***********************************
 1 - Usage Overview: First, we will attempt to gain an overall view of the volume of usage of Bixi Bikes and what 
factors influence it.
***********************************/

-- 1.1 The total number of trips for the year of 2016.

-- Queries to have a general view of the table, including the date format.
SELECT * 
FROM trips 
ORDER BY start_date ASC 
LIMIT 10;

SELECT count(*) 
FROM trips; 

-- Query to find the table of 2016 trips according the start_date. 
SELECT start_date 
FROM trips 
WHERE start_date >'2015-12-31' AND start_date <'2017-01-01'  
ORDER BY start_date 
DESC LIMIT 10;

-- Number of trips done in 2016
SELECT count(start_date) as total_trips_2016 
FROM trips 
WHERE start_date >'2015-12-31' AND start_date <'2017-01-01';

-- Number of trips done in 2016 (optimized query)
SELECT count(start_date) as total_trips_2016 
FROM trips 
WHERE YEAR(start_date) = 2016;


-- 1.2 The total number of trips for the year of 2017.
 
SELECT count(start_date) as total_trips_2017
FROM trips 
WHERE YEAR(start_date) = 2017;

-- 1.3 The total number of trips for the year of 2016 broken down by month: I used the month() function to extract the month from the dates given.

SELECT month(start_date) as Month_, count(month(start_date)) as Num_Trips
FROM trips 
WHERE YEAR(start_date) = 2016 
GROUP BY (month(start_date)) 
ORDER BY month(start_date) ASC;

-- 1.4 The total number of trips for the year of 2017 broken down by month. Same process, I just changed the date parameter. 

SELECT month(start_date) as Month_, count(month(start_date)) as Num_Trips
FROM trips 
WHERE YEAR(start_date) = 2017
GROUP BY (month(start_date)) 
ORDER BY month(start_date) ASC;

-- 1.5 The average number of trips a day for each year-month combination in the dataset.

-- First, I am going to create a table to see all the trips according day, month and year. 

SELECT 
	day(start_date) as day_trip,
    month(start_date) as month_trip, 
    year(start_date) as year_trip
    FROM trips;

-- Now I am going to count trips per day

SELECT 
	year_trip, month_trip, day_trip, count(day_trip) 
FROM 
(SELECT 
	day(start_date) as day_trip,
    month(start_date) as month_trip, 
    year(start_date) as year_trip
    FROM trips
    ) as date_trip
GROUP BY date_trip.year_trip, date_trip.month_trip, date_trip.day_trip;

/** Now I want the avg per day in the combination month-year: I realized I can calculate the avg in 2 different ways: 
-- Average daily trips over the days that have trips or Daily trips over 30 days as standard measure of months. **/

-- Average daily trips over the days that have trips:
SELECT 
    summarize.year_trip,
    summarize.month_trip,
    AVG(summarize.sum_of_day_trips)   
FROM
    (SELECT 
		year_trip,
		month_trip,
		day_trip,
		COUNT(day_trip) AS sum_of_day_trips
	FROM
		(SELECT 
			DAY(start_date) AS day_trip,
			MONTH(start_date) AS month_trip,
			YEAR(start_date) AS year_trip
		FROM
			trips
		) AS date_trip
	GROUP BY date_trip.year_trip , date_trip.month_trip , date_trip.day_trip) as summarize
GROUP BY summarize.month_trip, summarize.year_trip;

-- Divising by 30 days, to have an standard in the comparison:
SELECT 
    summarize.year_trip,
    summarize.month_trip,
    sum(summarize.sum_of_day_trips)/30 as avg_trips_per_months  
FROM
    (SELECT 
		year_trip,
		month_trip,
		day_trip,
		COUNT(day_trip) AS sum_of_day_trips
	FROM
		(SELECT 
			DAY(start_date) AS day_trip,
			MONTH(start_date) AS month_trip,
			YEAR(start_date) AS year_trip
		FROM
			trips
		) AS date_trip
	GROUP BY date_trip.year_trip , date_trip.month_trip , date_trip.day_trip) summarize
GROUP BY summarize.month_trip, summarize.year_trip;
	 
-- 1.6 - Save your query results from the previous question (Q1.5) by creating a table called working_table1.
-- Note that I decided to keep the query that calculate monthly average trips per day over 30.

CREATE TABLE working_table1
SELECT 
    summarize.year_trip,
    summarize.month_trip,
    sum(summarize.sum_of_day_trips)/30 as avg_trips_per_months  
FROM
    (SELECT 
		year_trip,
		month_trip,
		day_trip,
		COUNT(day_trip) AS sum_of_day_trips
	FROM
		(SELECT 
			DAY(start_date) AS day_trip,
			MONTH(start_date) AS month_trip,
			YEAR(start_date) AS year_trip
		FROM
			trips
		) AS date_trip
	GROUP BY date_trip.year_trip , date_trip.month_trip , date_trip.day_trip) summarize
GROUP BY summarize.month_trip, summarize.year_trip;

-- To visualize the new table:

SELECT * FROM working_table1;

/***********************************
2 - Members vs Non-Members: nsurprisingly, the number of trips varies greatly throughout the year. How about membership status? 
Should we expect members and non-members to behave differently? To start investigating that, calculate:
***********************************/

-- 2.1 The total number of trips in the year 2017 broken down by membership status (member/non-member).

-- For year 2017
SELECT count(start_date) as trips_2017, is_member
FROM trips 
WHERE YEAR(start_date) = 2017
GROUP BY is_member;

-- For year 2016
SELECT count(start_date) as trips_2017, is_member
FROM trips 
WHERE YEAR(start_date) = 2016
GROUP BY is_member;

-- 2.2 The percentage of total trips by members for the year 2017 broken down by month.

-- Next query visualize a table with 2017 months / trips per month / is_member: is counting all the trips, 
-- But I need to separate member and non member.

SELECT trips_2017.months_2017, 
	   trips_2017.total_trips,
       trips_2017.total_member
FROM   (SELECT Month(start_date)        AS months_2017,
               Count(Month(start_date)) AS total_trips,
               count(is_member)         AS total_member
        FROM   trips
        WHERE  YEAR(start_date) = 2017
        GROUP  BY months_2017) AS trips_2017;
 
 -- The intention of this query is separate member and non member trips.
SELECT months_2017, sum(ismember), sum(nonmember) 
FROM (
SELECT Month(start_date) AS months_2017,
	   if (is_member = 1, 1 ,0) as ismember,
	   if (is_member = 0, 1 ,0) as nonmember
        FROM   trips
        WHERE  YEAR(start_date) = 2017
        ) as summarize 
GROUP BY months_2017;

 -- Now I need to see the same data but in percentage terms:
 
SELECT months_2017,
	   trips_members,
       (trips_members * 100/(trips_members + trips_nonmembers)) as perc_trips_members, 
       trips_nonmembers,
       (trips_nonmembers * 100/(trips_members + trips_nonmembers)) as perc_trips_nonmembers  
FROM (
	SELECT months_2017, 
		sum(ismember) as trips_members, sum(nonmember) as trips_nonmembers 
	FROM (
		SELECT Month(start_date) as months_2017,
		if (is_member = 1, 1 ,0) as ismember,
	    if (is_member = 0, 1 ,0) as nonmember
        FROM   trips
        WHERE  YEAR(start_date) = 2017
        ) as summarize 
	GROUP BY months_2017) summarize2
GROUP BY  months_2017;

/***********************************
3 - Peak Season/Promotions: Use the above queries to answer the questions below.
***********************************/

/**
3.1 At which time(s) of the year is the demand for Bixi bikes at its peak? 
-- Jun, Jul, Aug, Sept, summer is the season when people use most the service.

3.2 If you were to offer non-members a special promotion in an attempt to convert them to members, 
when would you do it? Describe the promotion and explain the motivation and your reasoning behind it.

I would offer the promotion finishing march, based on the bike season is about to open and 
people are going to have 8 month ahead to enjoy the service. */

/**

/***********************************
 Question 4 - JOIN vs Subquery: It is clear now that time of year and membership status are intertwined and influence greatly 
how people use Bixi bikes. Next, let's investigate how people use individual stations, and explore station popularity.
***********************************/

-- 4.1 What are the names of the 5 most popular starting stations? Determine the answer without using a subquery.

SELECT start_station_code, count(start_station_code) as station_trips 
FROM trips
GROUP BY start_station_code
ORDER BY station_trips DESC
LIMIT 5;  -- 1.776 sec query ejecution time   

-- 4.2 Solve the same question as Q4.1, but now use a subquery.

SELECT start_station_code, station_trips
FROM (
	SELECT start_station_code, count(start_station_code) as station_trips 
	FROM trips
	GROUP BY start_station_code) AS subquery  
ORDER BY station_trips DESC
LIMIT 5;     -- 1.812 sec query ejecution duration

/* 4.3 Is there a difference in query run time between 4.1 and 4.2? Why or why not? 

Answer: In this case there is not a significantly difference. 
However, the subquery took more time processing.
I would say the time that the subquery adds to the final time is explained by the
time that the computer needs to verify the first query was completed before starting the next one.
Also I think if the query has a subquery the computer is going to need more time because 
it has to get a new group of information each time it wants to made a calculation, 
It means that the query is only one, the computer only has to get the data one time and make the operation, 
but if it has to iniciate a new query consecutivetly it is going to need to get the information again.
*/

/***********************************
5 - Mackay/de Maisonneuve: break up the hours of the day:
***********************************/

-- 5.1 How is the number of starts and ends distributed for the station Mackay / de Maisonneuve throughout the day?

-- First, I need the code of the station to analize
SELECT * 
FROM stations 
WHERE name = 'Mackay / de Maisonneuve'; -- (6100) It is the most popoular station.

-- Now I want to know the number of starts and ends in this specific station

SELECT start_station_code,  -- number of trips that started in 6100 station
	   count(*) as total_trips
FROM trips
WHERE start_station_code = '6100'; 

SELECT end_station_code,    -- number of trips that ended in 6100 station
       count(*)  as total_trips
FROM trips
WHERE end_station_code = '6100';

-- this query clasify each trip that START in 6100 station
SELECT start_station_code,  
	   CASE
       WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "morning"
       WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "afternoon"
       WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "evening"
       ELSE "night"
	   END AS "time_of_day"
FROM trips
WHERE start_station_code = '6100'; 

-- this query clasify each trip that ENDs in 6100 station
SELECT end_station_code,  
	   CASE
       WHEN HOUR(end_date) BETWEEN 7 AND 11 THEN "morning"
       WHEN HOUR(end_date) BETWEEN 12 AND 16 THEN "afternoon"
       WHEN HOUR(end_date) BETWEEN 17 AND 21 THEN "evening"
       ELSE "night"
	   END AS "time_of_day"
FROM trips
WHERE end_station_code = '6100'; 

-- Finally, those queries give me the numbers by time of the day to see the 
-- distribution of start and ended trips in the 6100 station,
-- I made a query to see the ditribution of start_trips and one more to see the end_trips

SELECT DISTINCT time_of_day, count(time_of_day)as total_trips
FROM (
	SELECT end_station_code,  
	   CASE
       WHEN HOUR(end_date) BETWEEN 7 AND 11 THEN "morning"
       WHEN HOUR(end_date) BETWEEN 12 AND 16 THEN "afternoon"
       WHEN HOUR(end_date) BETWEEN 17 AND 21 THEN "evening"
       ELSE "night"
	   END AS "time_of_day"
	   FROM trips
	   WHERE end_station_code = '6100') clasifier
GROUP BY time_of_day;

SELECT DISTINCT time_of_day, count(time_of_day) as total_trips
FROM ( SELECT start_station_code,  
	   CASE
       WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "morning"
       WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "afternoon"
       WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "evening"
       ELSE "night"
	   END AS "time_of_day"
	   FROM trips
       WHERE start_station_code = '6100') clasifier
GROUP BY time_of_day;
 
 
/* 5.2 Explain and interpret your results from above. 

This station is strategically located either in downtown Montreal or in a popular tourist destination. 
As a result, it caters to a diverse population, including local residents such as students, workers, and individuals residing in the area. 
This explains the high number of trips throughout the day, starting early in the morning. 
In the morning, many residents need to commute to work, while others arrive to work in the vicinity, contributing to the station's activity.

Furthermore, the station also serves as a hub for tourists who visit the area, particularly during the daytime, 
around noon and in the afternoon. This location may offer attractions, points of interest, or establishments that draw visitors and customers. 
Hence, the station remains busy even during nighttime, as it continues to accommodate both the local population and the influx of tourists.

/***********************************
 Question 6 - Round-Trips: List all stations for which at least 10% of trips are round trips. 
Round trips are those that start and end in the same station. 
This time we will only consider stations with at least 500 starting trips. 
(Include answers for all steps outlined)
***********************************/

-- First, write a query that counts the number of starting trips per station.

SELECT start_station_code as station, 
	   count(start_date) as total_start_trips_station
FROM trips
GROUP BY start_station_code
LIMIT 10;

-- Second, write a query that counts, for each station, the number of round trips.

SELECT start_station_code,
       end_station_code,
       Count(start_date) AS total_start_trips_station
FROM   trips
WHERE  start_station_code = end_station_code
GROUP  BY start_station_code,
          end_station_code
LIMIT  10; 

-- Combine the above queries and calculate the fraction of round trips to the total number of starting trips for each station.

SELECT trips.start_station_code,
       Count(*)                               AS total_round_trips,
       num_of_star_trips,
       ( Count(*) / num_of_star_trips ) * 100 AS perc_round_over_totalstart
FROM   trips,
       (SELECT start_station_code,
               Count(start_date) AS num_of_star_trips
        FROM   trips
        GROUP  BY start_station_code) pre_select
WHERE  trips.start_station_code = trips.end_station_code
       AND trips.start_station_code = pre_select.start_station_code
GROUP  BY start_station_code,
          end_station_code; 

-- Filter down to stations with at least 500 trips originating from them and having at least 10% of their trips as round trips.

SELECT trips.start_station_code,
       Count(*)                               AS total_round_trips,
       num_of_star_trips,
       ( Count(*) / num_of_star_trips ) * 100 AS perc_round_over_totalstart
FROM   trips,
       (SELECT start_station_code,
               Count(start_date) AS num_of_star_trips
        FROM   trips
        GROUP  BY start_station_code
        HAVING num_of_star_trips >= 500) pre_select
WHERE  trips.start_station_code = trips.end_station_code
       AND trips.start_station_code = pre_select.start_station_code
GROUP  BY start_station_code,
          end_station_code; 

-- At least 10% of round trips

SELECT trips.start_station_code,
       Count(*)                               AS total_round_trips,
       num_of_star_trips,
       ( Count(*) / num_of_star_trips ) * 100 AS perc_round_over_totalstart
FROM   trips,
       (SELECT start_station_code,
               Count(start_date) AS num_of_star_trips
        FROM   trips
        GROUP  BY start_station_code
        HAVING num_of_star_trips >= 500) pre_select
WHERE  trips.start_station_code = trips.end_station_code
       AND trips.start_station_code = pre_select.start_station_code
GROUP  BY start_station_code,
          end_station_code
HAVING perc_round_over_totalstart >= 10
ORDER  BY perc_round_over_totalstart DESC; 

/* Where would you expect to find stations with a high fraction of round trips? 

-- Bixi stations located in areas with circuits that start and end in the same place, 
for example, Bixi stations in parks, subway stations, in areas with few aditional stations in the peripheria.


END.
*/
