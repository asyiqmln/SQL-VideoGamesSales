##Which titles sold the most worldwide?
CREATE VIEW total_sales_lists AS (
	SELECT title,
    round(sum(total_sales),2) as total_sales,
    round(sum(na_sales),2) as na_sales,
    round(sum(jp_sales),2) as jp_sales,
    round(sum(pal_sales),2) as pal_sales,
    round(sum(other_sales),2) as other_sales
    FROM `vgchartz-2024`
    GROUP BY title ORDER BY total_sales desc
);
SELECT title, max(total_sales) FROM total_sales_lists;

##Which year had the highest sales? Has the industry grown over time?
SELECT YEAR(release_date) AS years, round(sum(total_sales),2) AS total_sales FROM `vgchartz-2024`
GROUP BY release_date ORDER BY total_sales desc;

##Do any consoles seem to specialize in a particular genre?
WITH specialized_console AS (
	SELECT console, genre, count(*) AS genre_count, ROW_NUMBER() OVER (PARTITION BY console ORDER BY COUNT(*) DESC) AS ranks
    FROM `vgchartz-2024`
    GROUP BY console, genre
)
SELECT console, genre FROM specialized_console
WHERE ranks = 1;

##What titles are pop in one region but flop in another?
SELECT title,
GREATEST(na_sales, jp_sales, pal_sales, other_sales) AS top_sales,
LEAST(na_sales, jp_sales, pal_sales, other_sales) AS flop_sales
FROM total_sales_lists;


WITH unpivoted AS (
	SELECT title, 'na_sales' AS region, na_sales AS sales FROM total_sales_lists
	UNION ALL
	SELECT title, 'jp_sales' AS region, jp_sales AS sales FROM total_sales_lists
	UNION ALL
	SELECT title, 'pal_sales' AS region, pal_sales AS sales FROM total_sales_lists
	UNION ALL
	SELECT title, 'other_sales' AS region, other_sales AS sales FROM total_sales_lists
),
sales_ranks AS (
	SELECT title, region, sales,
		ROW_NUMBER() OVER (PARTITION BY title ORDER BY sales DESC) as rank_desc,
		ROW_NUMBER() OVER (PARTITION BY title ORDER BY sales ASC) as rank_asc
    FROM unpivoted
)
SELECT
title,
MAX(CASE WHEN rank_desc = 1 THEN region END) AS top_region, 
MAX(sales) as top_sales,
MAX(CASE WHEN rank_asc = 1 THEN region END) AS flop_region,
MIN(sales) AS flop_sales
FROM sales_ranks
GROUP BY title
