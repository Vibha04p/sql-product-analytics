--Query S2 — Trial-to-Paid Conversion by Cohort
--Business Question: Measure weekly trial-to-paid conversion by cohort and determine what percentage of trial accounts converted within 14, 30, and 60 days, along with the median time to conversion.

--What this tells us?:Weekly trial-to-paid conversion rates varied significantly across cohorts, ranging from 0% to 100%.
--The median conversion time remained consistent at 9–14 days (overall average: 11.27 days).
--Validation confirmed that all 113 converted accounts converted between Day 9 and Day 14.
--Since no conversions occurred after Day 14, the cumulative 14-day, 30-day, and 60-day conversion rates are identical across all cohorts.

--PM Action: Focus onboarding, product education, and sales engagement within the first 14 days of the trial, as this is the critical conversion window. Investigate high-performing cohorts to replicate successful acquisition and onboarding strategies, and analyze low-performing cohorts to identify opportunities for improving trial conversion.

--Validation:
--First trial per account considered.
--Conversion defined as trial_converted or subscription_started.
--Only conversions occurring after the trial start date included.
--Non-converted trial accounts retained using a LEFT JOIN.
--Validation confirmed 113/113 converted accounts completed conversion within 14 days, explaining why the 14-, 30-, and 60-day conversion metrics are identical.

with account_trials as (
SELECT
    account_id,
    MIN(started_at) AS first_trial_date,
    DATE_TRUNC('week', MIN(started_at)) AS trial_week
FROM saas.trials
GROUP BY account_id)

, trial_conversions as(
select 
at.account_id
, at.first_trial_date
, at.trial_week
, MIN(se. event_time) as first_conversion_date
from account_trials at
left join saas.subscription_events se
on at.account_id = se.account_id
AND se.event_type IN ('trial_converted', 'subscription_started')
AND se.event_time >= first_trial_date
group by 1,2,3)

, conversion_metrics as (
select
account_id
,first_trial_date
,trial_week
,first_conversion_date
,(first_conversion_date::date - first_trial_date::date) AS days_to_conversion
, CASE
    WHEN (first_conversion_date::date - first_trial_date::date ) <= 14 THEN 1
    ELSE 0
END AS converted_14d
, CASE
    WHEN (first_conversion_date::date - first_trial_date::date ) <= 30 THEN 1
    ELSE 0
END AS converted_30d
, CASE
    WHEN (first_conversion_date::date - first_trial_date::date ) <= 60 THEN 1
    ELSE 0
END AS converted_60d
from trial_conversions)

select
trial_week
,COUNT(*) AS trials_started
,SUM(converted_14d) as converted_14d
,SUM(converted_30d) as converted_30d
,SUM(converted_60d) as converted_60d
,SUM(converted_14d) *1.0/count(*) as conv_rate_14d
,SUM(converted_30d)*1.0/count(*) as conv_rate_30d
,SUM(converted_60d)*1.0/count(*) as conv_rate_60d
,PERCENTILE_CONT(0.5)
WITHIN GROUP (ORDER BY days_to_conversion)
AS median_days_trial_to_paid
from conversion_metrics
group by 1;


