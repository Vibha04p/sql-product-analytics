-- Q[N] — Activation Curve: Time-to-First-Meaningful-Action
-- Business question: How fast do new signups become real users, and how has that changed cohort-over-cohort?
-- -- What this tells us:
-- The activation rate has been improving across the signup cohorts, meaning a higher percentage of new users are completing a meaningful action within seven days of signing up. At the same time, the number of new signups has gradually declined in the most recent cohorts. While newer cohorts are activating at a higher rate, additional analysis is needed to determine whether this is due to better onboarding, changes in acquisition strategy, or other product improvements.
-- PM Action: Investigate why the number of new signups has declined in the recent cohorts. Review acquisition channel performance, marketing campaigns, and traffic sources to determine whether fewer users are entering the funnel or whether acquisition strategy has changed. If no acquisition changes are found, analyse landing page performance and website metrics to identify any potential drop-off during the signup journey. The last one or two cohorts should be interpreted with caution because the full seven-day activation window has not yet elapsed. As a result, these cohorts may not yet reflect their final activation rates.
-- Sanity check: Verified that activated_7d <= cohort_size for every cohort. ✔️
--Excluded customers who signed up before 2026-04-19 because session_events were not instrumented before this date.
--Confirmed that meaningful actions were only counted if they occurred on or after the customer's signup date, preventing negative activation times.


with signups as (
select customer_id
,created_at
, date_trunc('week', created_at) as signup_week
from ecom.customers
where created_at >= DATE '2026-04-19'
)

, first_meaningful_action as (
select se.customer_id
,MIN(se.occurred_at) as first_meaningful_action_date
from signups s 
JOIN ecom.session_events se
on se.customer_id = s.customer_id
where se.event_type in ('add_to_cart', 'begin_checkout', 'purchase') AND se.occurred_at >= s.created_at
group by se.customer_id)


, activation_metrics as(
select 
fd.customer_id
,s.signup_week
,EXTRACT (EPOCH from (fd.first_meaningful_action_date - s.created_at))/60 as minutes_to_activation
, CASE WHEN fd.first_meaningful_action_date <= s.created_at + INTERVAL '7 days' THEN 1 ELSE 0 END AS activated_7d 
from signups s left join first_meaningful_action fd
on s.customer_id = fd.customer_id)

select
signup_week
,count(customer_id) as cohort_size
,sum(activated_7d) as activated_7d
,sum(activated_7d)*1.0/count(customer_id) as activation_rate_7d
,percentile_cont(0.5) WITHIN GROUP(order by minutes_to_activation ) as median_minutes_to_activation
,percentile_cont(0.9) WITHIN GROUP(order by minutes_to_activation ) as p90_minutes_to_activation
from activation_metrics
group by signup_week;

