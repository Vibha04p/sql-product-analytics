--#### Query E4 — PDP Engagement: High-View, Low-Cart Products

--**Business question:** "Which products attract eyeballs but don't get added to cart? Those are either pricing problems, image problems, or stock problems."
--What this tells us

--These products attract a lot of customer interest, but they are not converting that interest into add-to-cart actions as well as other products in their category. This highlights products that may need further investigation.

--Sanity Check
--add_to_cart_sessions should never be greater than views.
--atc_rate should be between 0 and 1.
--The flagged products should have a lower atc_rate than the median for their category.


with product_engagement as (
SELECT
p.product_id
,count( *) filter(where s.event_type = 'product_view') as views
,count(DISTINCT s.session_id) filter(where s.event_type = 'add_to_cart') as add_to_cart_sessions
from ecom.products p
left join ecom.session_events s
on p.product_id = s.product_id
group by 1)

, product_metrics as (
select 
pe.product_id
,p.product_name
,c.category_name
, pe.views
, pe.add_to_cart_sessions
,(pe.add_to_cart_sessions*1.0/nullif(pe.views,0)) as atc_rate
from ecom.products p
left join ecom.categories c
on p.category_id = c. category_id
left join product_engagement pe
on pe.product_id = p.product_id)

, category_medians AS (
SELECT
category_name
,PERCENTILE_CONT(0.5)
WITHIN GROUP (ORDER BY atc_rate) AS category_median
FROM product_metrics
GROUP BY category_name
)

,product_benchmarks AS (
SELECT
pm.product_id
,pm.product_name
,pm.category_name
,pm.views
,pm.add_to_cart_sessions
,pm.atc_rate
,cm.category_median
,RANK() OVER (ORDER BY pm.views DESC) AS view_rank
,RANK() OVER (ORDER BY pm.atc_rate ASC) AS atc_rate_rank
FROM product_metrics pm
LEFT JOIN category_medians cm
ON pm.category_name = cm.category_name
)

SELECT
product_id
,product_name
,category_name
,views
,add_to_cart_sessions
,atc_rate
,category_median
,((atc_rate - category_median) / NULLIF(category_median, 0)) * 100
AS atc_rate_vs_category_median
,view_rank
,atc_rate_rank
FROM product_benchmarks
ORDER BY
view_rank
,atc_rate_rank
limit 10;
