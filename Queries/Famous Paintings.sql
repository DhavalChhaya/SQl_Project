SELECT * FROM artist
SELECT * FROM canvas_size
SELECT * FROM museum
SELECT * FROM museum_hours
SELECT * FROM product_size
SELECT * FROM [subject]
SELECT * FROM work

-- 1) Fetch all the paintings which are not displayed on any museums?
-- ANSWER:
-- Simple one
SELECT [name]
FROM work
WHERE museum_id IS NULL

-- Another way Somtimes these concept use to solve complex problem
SELECT W.name
FROM work W
LEFT join museum M on W.museum_id = M.museum_id
WHERE M.museum_id IS NULL

-- 2) Are there museums without any paintings?
-- ANSWER: NO

SELECT M.name
FROM museum M
LEFT JOIN work W ON M.museum_id = W.museum_id
WHERE W.museum_id IS NULL

--3) How many paintings have an asking price of more than their regular price?
--ANSWER: As Per Question No One. but if We change the condition to oppsite then "102807"

-- As per Question:
SELECT work_id
FROM product_size
WHERE sale_price > regular_price

--opposite
SELECT COUNT(work_id) AS Answer
FROM product_size
WHERE sale_price < regular_price
--GROUP BY work_id

--4) Identify the paintings whose asking price is less than 50% of its regular price?
--ANSWER: 58

-- Result Table
SELECT *
FROM product_size
WHERE sale_price < ( 0.5 * regular_price)

--Count
SELECT COUNT(work_id) AS Answer
FROM product_size
WHERE sale_price < ( 0.5 * regular_price)

-- 5) Which canva size costs the most?
--ANSWER:  CS.size_id,   CS.width,   CS.height,     CS.label					A.sale_price
--           4896	        48         	96	      48" x 96"(122 cm x 244 cm)		1115

SELECT CS.size_id, CS.width, CS.height, CS.label , A.sale_price
FROM
(SELECT *, RANK() OVER (ORDER BY sale_price DESC) RNK
FROM product_size) AS  A JOIN canvas_size CS ON A.size_id = CS.size_id
WHERE RNK = 1

--6) Fetch the top 10 most famous painting subject?
--ANSWER: Portraits, Abstract/Modern Art ,Nude ,Landscape Art ,Rivers/Lakes ,
--        Flowers ,Still-Life ,Seascapes ,Marine Art/Maritime ,Horses

SELECT [subject] AS MOST_FAMOUST_PAINTINGS_SUBJECTS
FROM
(SELECT S.[subject] , COUNT(1) NO_OF_PAINTINGS , RANK() OVER (ORDER BY COUNT(1) DESC) AS RANKING
FROM [subject] S
JOIN work W ON S.work_id = W.work_id
GROUP BY S.[subject]) AS A
WHERE RANKING <= 10

-- 7) Identify the museums which are open on both Sunday and Monday. Display museum name, city.
--ANSWER: There are 28 museums that opens on both Sunday and Monday.

SELECT DISTINCT M.[name] AS Museum_Name , M.[city] , M.[state], M.[country]
FROM museum M
JOIN museum_hours MH ON M.museum_id = MH.museum_id
WHERE MH.day = 'Sunday' AND EXISTS
(SELECT *
FROM museum_hours MH2
WHERE MH2.museum_id = MH.museum_id AND MH2.day = 'Monday');

--8) Display the country and the city with most no of museums.


WITH CTE_COUNTRY AS
		(SELECT country , COUNT(1) AS CNT, 
			   RANK() OVER (ORDER BY COUNT(1) DESC) AS RNK
		FROM museum
		GROUP BY country),
CTE_CITY AS
		(SELECT city, COUNT(1) AS CNTC,
				RANK() OVER (ORDER BY COUNT(1) DESC) AS RNKC
		FROM museum
		GROUP BY city)
SELECT country , city
FROM CTE_COUNTRY COUNTRY
CROSS JOIN CTE_CITY CITY 
WHERE COUNTRY.RNK = 1
AND CITY.RNKC = 1



--9) Identify the artist and the museum where the most expensive and least expensive
--painting is placed. Display the artist name, sale_price, painting name, museum
--name, museum city and canvas label
--
ANSWER:
WITH CTE AS
(SELECT *, RANK() OVER (ORDER BY sale_price DESC) AS RNK,
		  RANK() OVER (ORDER BY sale_price) AS RNK_ASC
FROM product_size) 
SELECT A.full_name AS Artist_Name, CTE.sale_price , W.[name] AS Painting_Name, M.[name] AS Museum_Name, M.city, CZ.[label]
FROM CTE
JOIN work W ON CTE.work_id = W.work_id 
JOIN museum M ON M.museum_id = W.museum_id
JOIN artist A ON A.artist_id =W.artist_id 
JOIN canvas_size CZ ON CZ.size_id = CTE.size_id
WHERE RNK = 1 OR RNK_ASC = 1



-- 10) Which country has the 5th highest no of paintings?
--ANSWER: Spain has 196 Paintings.

WITH CTE AS 
			(SELECT country, COUNT(1) AS no_of_paintings, RANK() OVER (ORDER BY COUNT(1) DESC) RNK
			FROM museum M 
			JOIN work W ON M.museum_id = W.museum_id
			GROUP BY country)
SELECT country , no_of_paintings
FROM CTE
WHERE RNK = 5

--11) Which are the 3 most popular and 3 least popular painting styles?
--ANSWER:

WITH CTE AS	
			(SELECT style , COUNT(1) AS CNT , RANK() OVER (ORDER BY COUNT(1) DESC) RNK, COUNT(1) OVER() AS NO_OF_RECORDS
			FROM work
			WHERE style IS NOT NULL
			GROUP BY style)
SELECT style, 
		CASE WHEN RNK <= 3 THEN 'Most Popular' ELSE 'Least Popular' END AS Remarks
FROM CTE 
WHERE RNK <= 3 OR
	  RNK > NO_OF_RECORDS - 3;

--12) Which artist has the most no of Portraits paintings outside USA?. Display artist
--	  name, no of paintings and the artist nationality.
-- ANSWER: There are two artist 1.Jan Willem Pieneman Vincent Van Gogh

WITH CTE AS
			(SELECT A.full_name AS Artist_name ,  A.nationality, COUNT(1) AS no_of_paintings , RANK() OVER (ORDER BY COUNT(1) DESC) AS RNK
			FROM artist A
			JOIN work W ON A.artist_id = W.artist_id
			JOIN [subject] S ON S.work_id = W.work_id
			JOIN museum M ON M.museum_id = W.museum_id
			WHERE S.[subject] = 'Portraits' AND M.country != 'USA'
			GROUP BY A.full_name, A.nationality )
SELECT Artist_name, nationality , no_of_paintings
FROM CTE
WHERE RNK = 1
