

-- E3 —Cohort Retention Curve (Weekly, Behavioral)
-- Business question: How well do weekly signup cohorts retain users over the first four weeks after signup?
--
-- What this tells us:
-- Cohort sizes increased after the first week and remained relatively stable between 700 and 800 users for most cohorts. The first completed cohort had the lowest Week 1 retention (25%), while subsequent completed cohorts showed retention of approximately 30–36%. Week 2 and Week 3 retention fluctuate across cohorts without a consistent trend. The later cohorts should be interpreted with caution because they have not yet completed the full four-week observation window, resulting in artificially low or zero retention values.
--
-- PM Action:
-- Investigate why the first cohort experienced significantly lower Week 1 retention than later cohorts to determine whether onboarding or product changes improved activation. Analyse user behaviour between Weeks 2 and 3 to understand why retention fluctuates across cohorts and identify where users disengage. Exclude incomplete cohorts from business reporting until the full four-week retention window has elapsed.
--
-- Sanity check: Verified that w0_active = cohort_size for every cohort.
-- Excluded customers who signed up before 2026-04-19 because session_events were not instrumented before this date.
-- Counted only meaningful actions (product_view, add_to_cart, purchase) occurring on or after the customer's signup date.
-- Calculated retention using relative week_index instead of calendar weeks.



with signups as (
select
customer_id
, created_at
, date_trunc('week',created_at) as cohort_week
from ecom.customers
where created_at >= DATE '2026-04-19')

,customer_week_activity as(
select DISTINCT
s.customer_id
,s.cohort_week
,FLOOR(EXTRACT(EPOCH from (se.occurred_at - s.created_at))/(86400 * 7)) as week_index
from signups s
inner join ecom.session_events se
on s.customer_id = se.customer_id
WHERE se.event_type IN (
'product_view', 'add_to_cart', 'purchase') AND se.occurred_at >= s.created_at
)



select 
count(DISTINCT s.customer_id) as cohort_size
, s.cohort_week
,Count(DISTINCT s.customer_id) as w0_active
,COUNT(DISTINCT s.customer_id)
FILTER (WHERE cw.week_index = 1) as w1_retained
,COUNT(DISTINCT s.customer_id)
FILTER (WHERE cw.week_index = 2) as w2_retained
,COUNT(DISTINCT s.customer_id)
FILTER (WHERE cw.week_index = 3) as w3_retained
,COUNT(DISTINCT s.customer_id)
FILTER (WHERE cw.week_index = 4) as w4_retained
,ROUND(
COUNT(DISTINCT s.customer_id)
FILTER (WHERE cw.week_index = 1)::numeric
/
COUNT(DISTINCT s.customer_id),
2
) AS w1_retention_rate
,ROUND(
COUNT(DISTINCT s.customer_id)
FILTER (WHERE cw.week_index = 2)::numeric
/
COUNT(DISTINCT s.customer_id),
2
) AS w2_retention_rate
,ROUND(
COUNT(DISTINCT s.customer_id)
FILTER (WHERE cw.week_index = 3)::numeric
/
COUNT(DISTINCT s.customer_id),
2
) AS w3_retention_rate
,ROUND(
COUNT(DISTINCT s.customer_id)
FILTER (WHERE cw.week_index = 4)::numeric
/
COUNT(DISTINCT s.customer_id),
2
) AS w4_retention_rate
from signups s
left join customer_week_activity cw
on s.customer_id = cw.customer_id
group by s.cohort_week;

