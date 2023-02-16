
-- Inside Airbnb provides data on Airbnb listings in many large cities and significant locations around the world. They also do some analysis of this data on their 
-- own to provide users with an idea of how Airbnb and its hosts operate. So, users like us can take that data and expand on the analysis if desired. Here, I chose to
-- look at the listings in Washington D.C. as it is a popular tourist destination with much to see in a relatively small area. So, choosing an ideally located Airbnb
-- could make a trip there all the more enjoyable.

SELECT *
FROM [Airbnb Database]..listings

-- Let's get the number of listings per neighborhood to start, to see which are the most popular, as well as the average price per neighborhood.

SELECT neighbourhood, COUNT(neighbourhood) AS Listings
FROM [Airbnb Database]..listings
GROUP BY neighbourhood
ORDER BY Listings DESC

SELECT neighbourhood, AVG(price) AS AvgPrice
FROM [Airbnb Database]..listings
GROUP BY neighbourhood
ORDER BY AvgPrice DESC

-- Unsurprisingly, landmark neighborhoods like Capitol Hill and Union Station have the most listings (which is probably visible from the map they provide, but just to 
-- be sure)! But perhaps surprisingly, these neighborhoods are not necessarily the most expensive. To double check, I'm going to put this in a subquery and sum the 
-- listings to see if it matches our total rows.

SELECT SUM(Listings) AS TotalListings
FROM (SELECT neighbourhood, COUNT(neighbourhood) AS Listings
	FROM [Airbnb Database]..listings
	GROUP BY neighbourhood) s1

-- Let's also get a breakdown of the room types. A percentage will be more helpful for understanding here.

SELECT room_type, COUNT(room_type) AS Listings, COUNT(*)*100.0/SUM(COUNT(*)) OVER() AS Percentage
FROM [Airbnb Database]..listings
GROUP BY room_type

-- Not all databases support OVER() clauses though, so here it is in a subquery.

SELECT room_type, 
	COUNT(room_type) AS Listings, 
	COUNT(room_type)*100.0/(SELECT COUNT(room_type) FROM [Airbnb Database]..listings) AS Percentage
FROM [Airbnb Database]..listings
GROUP BY room_type

-- Almost 75% of the listings are entire homes/apartments!


-- Inside Airbnb provides considerable analysis on their own, but does not show exactly how, so we'll try to recreate some of it here. For instance, exact booking 
-- details such as number of nights and amounts paid are not available and can only be estimated. First, we can use number of reviews and reviews per month to 
-- estimate how long many of these Airbnb's have been operating.

SELECT *, MonthsActive/12 AS YearsActive
FROM (SELECT name, number_of_reviews, reviews_per_month, number_of_reviews/reviews_per_month AS MonthsActive
	FROM [Airbnb Database]..listings) s2

-- Using price and minimum stay, we can calculate the minimum amount made off each stay, as well as average income per stay. The longer stays (the ones requiring at 
-- least one month) skew the data, so we'll try to keep it to vacation stays (2 weeks or less). This is part of the issue when analyzing Airbnb data: a majority of
-- people use them as vacation stays, but there are still quite a few locations that people live in for extended periods, so it is more helpful to distinguish.

SELECT name, price, minimum_nights, price*minimum_nights AS RevPerMinStay
FROM [Airbnb Database]..listings
WHERE minimum_nights <= 14

SELECT AVG(RevPerMinStay) AS AvgRevPerMinStay
FROM (SELECT name, price, minimum_nights, price*minimum_nights AS RevPerMinStay
	FROM [Airbnb Database]..listings
	WHERE minimum_nights <= 14) s3

-- Let's break this down further to get what the average income per minimum stay is in each neighborhood to see which areas are the most lucrative.

SELECT neighbourhood, AvgPrice*AvgMinNights AS AvgRevPerMinStay
FROM (
SELECT neighbourhood, AVG(price) AS AvgPrice, AVG(minimum_nights) AS AvgMinNights
FROM [Airbnb Database]..listings
WHERE minimum_nights <= 14
GROUP BY neighbourhood
) s4

-- We can use the time active we found earlier to get an idea of how much total income has been made off of each listing over the years.

SELECT *, MonthsActive/12 AS YearsActive, RevPerMinStay*number_of_reviews AS TotalMinIncome
FROM (
SELECT name, price, minimum_nights, number_of_reviews, reviews_per_month, price*minimum_nights AS RevPerMinStay, number_of_reviews/reviews_per_month AS MonthsActive
FROM [Airbnb Database]..listings
) s5

-- Some of the numbers look abnormally large (in the millions), but given the number of reviews and minimum stays, one would have to conclude that that amount of
-- money has been made over time. For instance, the location 'DC, Near Metro' appears to have made $17 million over the past 12 years. But with a price of $500 per
-- night, a minimum stay of 3 years and 31 reviews, this would be the conclusion. But this also does not add up because a minimum stay of that length would preclude
-- that many poeple from ever being there. So it is likely that hosts' conditions (such as price and minimum stay) change over time.


-- Let's find the the hosts with the most locations. We'll also count the number of times each name appears to get how many hosts go by the same name.

SELECT host_name, COUNT(host_id) AS Listings, COUNT(DISTINCT host_id)
FROM [Airbnb Database]..listings
GROUP BY host_name
ORDER BY Listings DESC

-- We see that a host by the name of Blueground has over 200 listings, which lines up with the info provided by Inside Airbnb. We can use the following query to get
-- a breakdown on where some of these hosts have their listings. The host 'Team' has an astonishing 70 listings in the single neighborhood of Dupont Circle!

SELECT host_name, neighbourhood, COUNT(host_id) AS Listings
FROM [Airbnb Database]..listings
WHERE host_name = 'Team'
GROUP BY host_name, neighbourhood
ORDER BY Listings DESC