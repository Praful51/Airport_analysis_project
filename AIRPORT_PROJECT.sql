create database airport;
use airport;

select * from airport;

-- 1. Analyze total passenger traffic per route.
 

select ORIGIN_CITY_NAME,DEST_CITY_NAME,sum(PASSENGERS) as total_passengers
from airport
group by ORIGIN_CITY_NAME,DEST_CITY_NAME
order by total_passengers desc limit 10;

-- 2. Determine average passengers per flight for various routes and airports

#FOR ROUTES
select ORIGIN_CITY_NAME,DEST_CITY_NAME,avg(PASSENGERS)as avg_passengers
from airport
group by ORIGIN_CITY_NAME,DEST_CITY_NAME
order by avg_passengers desc;

#FOR AIRPORTS

WITH OUTGOING_PASSENGERS AS(
select ORIGIN_AIRPORT_ID,AVG(PASSENGERS) AS AVG_PASSENGERS
FROM  AIRPORT
GROUP BY ORIGIN_AIRPORT_ID
ORDER BY AVG_PASSENGERS DESC),

INCOMING_PASSENGERS AS(
SELECT DEST_AIRPORT_ID,AVG(PASSENGERS) AS AVG_PASSENGERS
FROM  AIRPORT
GROUP BY DEST_AIRPORT_ID
ORDER BY AVG_PASSENGERS DESC),

ALL_AIRPORTS AS(
SELECT DISTINCT ORIGIN_AIRPORT_ID AS AIRPORT_ID FROM AIRPORT
UNION
SELECT DISTINCT DEST_AIRPORT_ID AS AIRPORT_ID
FROM AIRPORT)

SELECT AA.AIRPORT_ID,OP.AVG_PASSENGERS+IP.AVG_PASSENGERS AS TOTAL_PASSENGERS_TRAVELLING
FROM ALL_AIRPORTS AA
LEFT JOIN OUTGOING_PASSENGERS OP ON AA.AIRPORT_ID=OP.ORIGIN_AIRPORT_ID
LEFT JOIN INCOMING_PASSENGERS IP ON AA.AIRPORT_ID=IP.DEST_AIRPORT_ID
ORDER BY TOTAL_PASSENGERS_TRAVELLING DESC;

-- 3. Assess flight frequency and identify high-traffic corridors.

select ORIGIN_AIRPORT_ID,DEST_AIRPORT_ID,ORIGIN,DEST,count(AIRLINE_ID)as total_flights,SUM(PASSENGERS) as Total_Passengers
from airport
group by  ORIGIN_AIRPORT_ID,DEST_AIRPORT_ID,ORIGIN,DEST
order by total_flights desc;


-- 4. Compare passenger numbers across origin cities to identify top-performing airports.

select ORIGIN_AIRPORT_ID,ORIGIN_CITY_NAME,COUNT(*)AS TOTAL_FLIGHTS,SUM(PASSENGERS) AS TOTAL_PASSENGERS
from airport
group by origin_airport_id,origin_city_name
order by total_passengers desc,total_flights desc limit 10;

    
-- 5. Identify popular destination airports based on inbound passenger counts.
select DEST_AIRPORT_ID,DEST_CITY_NAME,sum(PASSENGERS)as Inbound_Passengers
from airport
group by DEST_AIRPORT_ID,DEST_CITY_NAME
order by Inbound_Passengers desc limit 10;


-- 6. Ranking Routes with high passenger traffic

with high_traffic_route as(
select concat(ORIGIN_CITY_NAME,'-',DEST_CITY_NAME)As route,sum(PASSENGERS) as total_passengers
from airport
group by route)
select route,total_passengers,
dense_rank()over (order by total_passengers desc) rnk
from high_traffic_route;

-- 7. Routes which have low passenger volume but still operated frequently, underutilized routes

select concat(ORIGIN_CITY_NAME,'-',DEST_CITY_NAME) AS route,count(*) as total_flights,sum(passengers) as total_passengers
from airport
group by route
order by total_passengers asc,total_flights desc;

WITH route_summary AS (
    SELECT 
        CONCAT(ORIGIN_CITY_NAME, ' - ', DEST_CITY_NAME) AS route,
        ORIGIN,
        DEST,
        COUNT(*) AS total_flights,
        SUM(PASSENGERS) AS total_passengers,
        ROUND(
            SUM(PASSENGERS) * 1.0 / COUNT(*), 
            2
        ) AS avg_passengers_per_flight
    FROM airport
    GROUP BY 
        ORIGIN_CITY_NAME, 
        DEST_CITY_NAME, 
        ORIGIN, 
        DEST
)
SELECT 
    route,
    ORIGIN AS origin_airport,
    DEST AS dest_airport,
    total_flights,
    total_passengers,
    avg_passengers_per_flight
FROM route_summary
WHERE total_flights >= 5                    
  AND total_passengers < 500                
ORDER BY total_passengers ASC, 
         total_flights DESC
LIMIT 15;


-- 8. Airlines which dominate passenger traffic, Airline market share analysis

with airline_passenger_traffic as(
select AIRLINE_ID,UNIQUE_CARRIER_NAME,sum(PASSENGERS)as total_passengers
from airport
group by AIRLINE_ID,UNIQUE_CARRIER_NAME)

select AIRLINE_ID,UNIQUE_CARRIER_NAME,total_passengers,(dense_rank() over (order by total_passengers desc )) rnk
from airline_passenger_traffic limit 5 ;

-- 9. Airports with highest passenger growth potential, Airports with high flight frequency but relatively low passengers
SELECT * FROM AIRPORT;
WITH outgoing_passengers AS (
SELECT ORIGIN_AIRPORT_ID,count(*)as flights, SUM(PASSENGERS) AS TOT_passengers
FROM airport
GROUP BY ORIGIN_AIRPORT_ID
),
incoming_passengers AS (
SELECT DEST_AIRPORT_ID,count(*)as flights, SUM(PASSENGERS) AS TOT_passengers
FROM airport
GROUP BY DEST_AIRPORT_ID
),
all_airports as(
select ORIGIN_AIRPORT_ID AS AIRPORT_ID, ORIGIN_CITY_NAME AS CITY_NAME FROM AIRPORT
UNION
SELECT DEST_AIRPORT_ID AS AIRPORT_ID, DEST_CITY_NAME AS CITY_NAME FROM AIRPORT),


passenger_traffic AS (
    SELECT 
        aa.airport_id,
        aa.city_name,

        COALESCE(op.flights,0) + COALESCE(ip.flights,0) AS total_flights,

        COALESCE(op.tot_passengers,0) + COALESCE(ip.tot_passengers,0) 
        AS total_passenger_traffic,

        ROUND(
            (COALESCE(op.tot_passengers,0) + COALESCE(ip.tot_passengers,0)) /
            NULLIF(COALESCE(op.flights,0) + COALESCE(ip.flights,0),0)
        ,2) AS passengers_per_flight
        
FROM ALL_AIRPORTS AA
LEFT JOIN OUTGOING_PASSENGERS OP ON AA.AIRPORT_ID=op.ORIGIN_AIRPORT_ID                                 #
LEFT JOIN INCOMING_PASSENGERS IP ON AA.AIRPORT_ID=IP.DEST_AIRPORT_ID)

select AIRPORT_ID,CITY_NAME,total_flights,total_passenger_traffic,passengers_per_flight
from passenger_traffic
where total_flights is not null and total_passenger_traffic is not null
order by total_flights desc,total_passenger_traffic asc;

-- 10. Airports which connect to the largest number of destinations, Network Connectivity Analysis

select origin_airport_id as airport_id,
origin_city_name as city_name,
count(distinct dest_city_name)as destination
from airport
group by airport_id,city_name
order by destination desc;

-- 11. Average passengers per flight by airline

select AIRLINE_ID,UNIQUE_CARRIER_NAME,count(*) as total_flights,avg(passengers) as avg_passengers
from airport
group by AIRLINE_ID,UNIQUE_CARRIER_NAME
order by avg_passengers desc;




