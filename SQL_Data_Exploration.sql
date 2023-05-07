/*
ENGLAND Football Data Exploration 
*/

/*Get all matches and the number of corner kicks for both teams*/
SELECT home, away, home_corner, away_corner, total_corners
FROM ENGLAND_statistical 

/*Show the average number of corner kicks by home teams in the 'Premier League' tournament in 2023*/
SELECT s.home, AVG(s.home_corner) AS avg_home_corner
FROM ENGLAND_statistical s
WHERE s.tournament = 'Premier League' and YEAR(date) = 2023
GROUP BY s.home;

/*Show the number of matches with and without goals for each tournament*/
SELECT tournament, 
COUNT(*) AS matches_with_goals, 
(SELECT COUNT(*) FROM ENGLAND_result WHERE tournament = r.tournament AND (away_goal = 0 AND home_goal = 0)) as matches_without_goal
FROM ENGLAND_result r
WHERE r.away_goal > 0 OR r.home_goal > 0
GROUP BY tournament;

/*Calculate the number of matches won, drawn, and lost by each team in each tournament and sort by tournament name*/
SELECT tournament,
    SUM(CASE WHEN ht_result = 'WON' THEN 1 ELSE 0 END) AS home_wins,
    SUM(CASE WHEN ht_result = 'DRAW' THEN 1 ELSE 0 END) AS draws,
    SUM(CASE WHEN ht_result = 'LOST' THEN 1 ELSE 0 END) AS home_losses
FROM ENGLAND_result
GROUP BY tournament
ORDER BY tournament ASC

/*Show the win percentage of home teams, sorted in descending order*/
SELECT m.home, ROUND((CAST(w.total_win_matches AS float) / CAST(m.total_matches AS float))*100,2) as win_percentage
FROM (
    select home, count(*) as 'total_matches'
	from ENGLAND_result
	group by home
) m
JOIN (
    select home, count(*) as 'total_win_matches'
	from ENGLAND_result
	where home_goal > away_goal
	group by home
) w ON m.home = w.home
order by win_percentage desc

/*Calculate the total number of shots and goals for each team in the 'Premier League' tournament in March 2023*/
SELECT 
  s.home AS team,
  SUM(s.home_shots + s.away_shots) AS total_shots,
  SUM(r.home_goal + r.away_goal) AS total_goals
FROM ENGLAND_statistical s 
JOIN ENGLAND_result r ON s.tournament = r.tournament AND s.home = r.home AND s.away = r.away AND s.date = r.date
WHERE 
  s.tournament = 'Premier League' AND 
  MONTH(s.date) = 3 AND 
  YEAR(s.date) = 2023
GROUP BY s.home
ORDER BY total_goals desc

/*Use CTE to calculate the number of matches played by each team at home in the Premier League tournament in March 2023*/
WITH CTE AS (
   SELECT home, COUNT(*) AS num_matches
   FROM ENGLAND_result
   WHERE tournament = 'Premier League' AND MONTH(date) = 3 AND YEAR(date) = 2023
   GROUP BY home
)
SELECT home, num_matches
FROM CTE
ORDER BY num_matches DESC;

/*Use Temp Table to get information about the number of wins, losses, and draws of each football team in the Premier League from 2023 to now*/
-- Create a Temp Table to store the result of each match
CREATE TABLE #temp_result (
    home_team VARCHAR(255),
    away_team VARCHAR(255),
    home_goal FLOAT,
    away_goal FLOAT
)

-- Insert data from the ENGLAND_result table into the Temp Table
INSERT INTO #temp_result (home_team, away_team, home_goal, away_goal)
SELECT home, away, home_goal, away_goal
FROM ENGLAND_result

-- Calculate the number of wins, losses, and draws for each team
SELECT 
    team,
    COUNT(CASE WHEN result = 'W' THEN 1 END) AS win,
    COUNT(CASE WHEN result = 'L' THEN 1 END) AS lose,
    COUNT(CASE WHEN result = 'D' THEN 1 END) AS draw
FROM (
    SELECT 
        home_team AS team, 
        CASE WHEN home_goal > away_goal THEN 'W' WHEN home_goal < away_goal THEN 'L' ELSE 'D' END AS result 
    FROM #temp_result
    UNION ALL
    SELECT 
        away_team AS team, 
        CASE WHEN away_goal > home_goal THEN 'W' WHEN away_goal < home_goal THEN 'L' ELSE 'D' END AS result 
    FROM #temp_result
) AS t
GROUP BY team
ORDER BY win desc
-- Drop Temp Table
DROP TABLE #temp_result
