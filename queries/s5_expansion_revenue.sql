--Query S5 — Expansion Revenue: Who's Upgrading and Why
--Business question: "Of accounts that expanded MRR in the last 6 months, what's the dominant expansion vector — seats added, plan upgrade, or add-on attach?"
--What this tells us
--Plan upgrades are the dominant expansion driver, generating 96 expansion events across 87 accounts and contributing $10,341.45 in expansion MRR. Seat additions are fewer but have the highest expansion MRR per account ($198.76), indicating larger expansions when they occur. Add-ons have minimal adoption and contribute very little incremental revenue.
--PM Action
--Since plan upgrades are the dominant expansion vector, the company should invest in clearer pricing tier differentiation and in-app upgrade prompts. Making upgrade benefits more visible and reducing friction in the upgrade flow can increase expansion revenue from existing customers.
--Sanity Check
--The expansion_mrr_total across all expansion types is $15,549.09, which reconciles with the expansion_mrr for the same six-month window in Query S1. Since both totals match, the event classification is consistent across the two queries, indicating that expansion events have been categorized correctly.

with expansion_events  as( 
select
account_id
, event_time
,mrr_delta
, CASE WHEN event_type ='seat_add' then 'seats_added'
when  event_type ='addon_attach' then 'addon' 
when event_type= 'plan_changed' then 'plan_upgrade'
END as expansion_type
from saas.subscription_events
WHERE (event_type IN ('seat_add', 'addon_attach') OR (event_type = 'plan_changed' AND mrr_delta > 0))
AND event_time >= CURRENT_DATE - INTERVAL '6 months')


, days_expansion as (
select
ee.account_id
,ee.event_time
,ee.mrr_delta
,ee.expansion_type
,a.signup_date
, (ee.event_time::date - a.signup_date::date) as days_from_signup_to_expansion
from expansion_events ee
JOIN saas.accounts a
on ee.account_id = a.account_id)

select 
expansion_type
,count(*) as expansion_events
,count(DISTINCT account_id) as accounts_expanded
,SUM(mrr_delta) as expansion_mrr_total
,SUM(mrr_delta)*1.0/count(DISTINCT account_id) as expansion_mrr_per_account
,percentile_cont(0.5) WITHIN GROUP(Order by days_from_signup_to_expansion) as median_days_from_signup_to_expansion
from days_expansion
group by expansion_type;


