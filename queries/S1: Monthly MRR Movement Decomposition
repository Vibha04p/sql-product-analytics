--S1: Monthly MRR Movement Decomposition

--Business Question:
--How has Monthly Recurring Revenue (MRR) changed over the past 12 months, and what portion of those changes comes from new customers, expansions, contractions, churn, and reactivations?

--What this tells us:
--The business maintained positive Net New MRR throughout the analysis period, primarily driven by new customer acquisition.
--Expansion MRR consistently contributed additional growth, while contraction MRR remained relatively small.
--Churn was the largest negative factor, particularly in January and March, where it significantly reduced overall growth.
--Reactivations provided a steady but smaller contribution to revenue recovery.
--June's figures are lower because the analysis only includes data up to June 15, making it a partial month.

--PM Action:
--Investigate the causes of high churn in January and March and implement targeted retention strategies.
--Continue investing in acquisition channels that consistently drive strong New MRR.
--Promote successful upsell opportunities to increase Expansion MRR.
--Run win-back campaigns to improve Reactivation MRR.
--Monitor Net New MRR monthly to ensure revenue growth remains healthy and sustainable.

--Sanity Check:
--Confirm trial_started events are excluded since they do not contribute to MRR.
--Ensure every event is assigned to exactly one movement bucket (New, Expansion, Contraction, Churn, or Reactivation).
--Verify Expansion and Contraction are classified correctly based on the sign of mrr_delta.
--Validate Reactivation logic (using EXISTS or the chosen business rule) correctly identifies returning customers.
--Confirm monthly aggregation is performed using DATE_TRUNC('month', event_time).
--Verify the analysis window includes only the last 12 months and excludes events after 2026-06-15.
--Validate Net New MRR = New + Expansion + Reactivation − Contraction − Churn.
--Recognize that June is a partial month and should not be directly compared with full months.

WITH event_history AS (
SELECT
account_id
, DATE_TRUNC('month', event_time) AS month
, event_time
, event_type
, mrr_delta
, LAG(event_type) OVER (
PARTITION BY account_id
ORDER BY event_time
) AS previous_event
FROM saas.subscription_events
WHERE event_type <> 'trial_started'
AND event_time >= CURRENT_DATE - INTERVAL '12 months'
AND event_time <= DATE '2026-06-15'
)

, classified_events AS (
SELECT
month
, account_id
, event_time
, event_type
, mrr_delta
, CASE
WHEN event_type = 'subscription_started'
AND previous_event = 'cancelled'
THEN 'reactivation'

WHEN event_type IN ('subscription_started', 'trial_converted')
AND mrr_delta > 0
THEN 'new'

WHEN event_type = 'plan_changed'
AND mrr_delta > 0
THEN 'expansion'

WHEN event_type IN ('seat_add', 'addon_attach')
THEN 'expansion'

WHEN event_type = 'plan_changed'
AND mrr_delta < 0
THEN 'contraction'

WHEN event_type = 'cancelled'
THEN 'churn'
END AS bucket
FROM event_history
)

SELECT
  month
  , SUM(mrr_delta) FILTER (WHERE bucket = 'new') AS new_mrr
  , SUM(mrr_delta) FILTER (WHERE bucket = 'expansion') AS expansion_mrr
  , SUM(mrr_delta) FILTER (WHERE bucket = 'contraction') AS contraction_mrr
  , SUM(mrr_delta) FILTER (WHERE bucket = 'churn') AS churn_mrr
  , SUM(mrr_delta) FILTER (WHERE bucket = 'reactivation') AS reactivation_mrr
  , SUM(mrr_delta)  AS net_new_mrr
FROM classified_events
GROUP BY 1
ORDER BY 1;
