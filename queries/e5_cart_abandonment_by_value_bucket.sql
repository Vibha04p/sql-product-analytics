-- E5 — Cart Abandonment by Cart Value Bucket

-- Business Question:
-- How does cart abandonment vary across different cart value buckets, and where is the highest potential revenue (GMV) being lost due to abandoned carts?

-- What this tells us:
-- Lower-value carts experienced the highest abandonment rates, with 53% of carts below ₹500 and 46% of carts between ₹500–₹1,999 being abandoned. However, the largest financial impact came from higher-value carts. The ₹5,000–₹14,999 bucket had the highest GMV left on the table (approximately ₹9.85M) despite a relatively low abandonment rate of 22%. The ₹15,000+ bucket had the lowest abandonment rate (8.3%), but each abandoned cart represented a significant revenue loss, resulting in over ₹6M in lost GMV.

-- PM Action:
-- Prioritise reducing abandonment in the ₹5,000–₹14,999 bucket, as even small improvements can recover substantial revenue. Investigate the reasons behind the high abandonment rates in lower-value carts, such as checkout friction, shipping costs, or pricing concerns. Consider targeted recovery campaigns, payment assistance, or personalised reminders for customers abandoning high-value carts.

-- Sanity Check:
-- Verified that every row in the analysis represents a unique session with at least one add_to_cart event.
-- Confirmed that purchased_sessions + abandoned_sessions = atc_sessions for every cart value bucket.
-- Calculated cart value as the sum of (quantity × unit_price) across all add_to_cart events within a session.
-- Counted only sessions with non-cancelled orders as purchased and treated sessions without a completed order as abandoned.
-- Verified that abandonment rates fall between 0 and 1 and that GMV left on the table includes only abandoned sessions.

with session_cart as (
select
se.session_id
, SUM( se.quantity * se.unit_price) as cart_value
,MAX( CASE WHEN lower (o.status) != 'cancelled' THEN 1
    ELSE 0
    END) AS purchased_flag
from ecom.session_events se
left join ecom.orders o
on se.session_id = o.session_id
where se.event_type = 'add_to_cart'
group by se.session_id)

, buckets as (
select
session_id
, cart_value
, purchased_flag
,CASE
    WHEN cart_value < 500 THEN '<500'
    WHEN cart_value BETWEEN 500 AND 1999 THEN '500-1999'
    WHEN cart_value BETWEEN 2000 AND 4999 THEN '2000-4999'
    WHEN cart_value BETWEEN 5000 AND 14999 THEN '5000-14999'
    ELSE '15000+'
END AS cart_bucket
from session_cart)

--cart_bucket, , purchased_sessions, abandoned_sessions, abandonment_rate, gmv_left_on_table


select
cart_bucket
, COUNT(*) as atc_sessions
, count(purchased_flag) filter( where purchased_flag = 1) as purchased_sessions
, count(purchased_flag) filter ( where purchased_flag = 0) as abandoned_sessions
, (count(purchased_flag) filter ( where purchased_flag = 0)*1.0/ COUNT(*) ) as abandonment_rate
,SUM(cart_value) filter ( where purchased_flag = 0) as gmv_left_on_table
from buckets
group by cart_bucket;
