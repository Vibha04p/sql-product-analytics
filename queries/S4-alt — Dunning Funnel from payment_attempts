--S4-alt — Dunning Funnel from payment_attempts
--Business Question
--Of failed charges last quarter, what fraction recovered on retry by failure reason, and where should we improve the dunning process?
--What this tells us
--Insufficient funds has the highest recovery rate (42%) but also the largest MRR at risk ($20,001.34), making it the biggest revenue recovery opportunity.
--Card declined and expired card show moderate recovery rates (39% and 38%), indicating retries help but don't recover most failed payments.
--Fraud blocked has the lowest recovery rate (29%), suggesting retries alone are ineffective.
--The median attempts to recovery is 2 across all failure reasons, meaning successful recoveries typically happen on the first retry.
--PM Action
--Different failure reasons require different interventions:
--Insufficient funds → Smart retry timing (e.g., retry around payday instead of the next day).
--Expired card → Pre-expiry reminders and a seamless card update flow.
--Authentication required → Improve the 3DS authentication experience.
--Fraud blocked → Review fraud rules instead of increasing retry frequency.
--Based on MRR at Risk × (1 − Recovery Rate), Insufficient funds is the highest-impact failure reason. The first improvement to ship would be smart retry scheduling.
--Sanity Check
--eventually_recovered ≤ failed_invoices for every failure reason. ✓
--Total mrr_recovered should reconcile with a separate query summing MRR for attempt_number > 1 AND status = 'succeeded'


with first_attempts as (select 
invoice_id
,account_id
,failure_reason
,amount
,attempted_at
from saas.payment_attempts
where attempt_number = 1 AND status = 'failed'
AND attempted_at >= date_trunc('quarter', CURRENT_DATE) - INTERVAL '3 months'
AND attempted_at < date_trunc('quarter', CURRENT_DATE))

, recovered_attempts as (select 
fa.invoice_id
, fa.account_id
, fa.failure_reason
, fa.amount
,MIN(pa.attempt_number) as recovery_attempt
,CASE WHEN MIN(pa.attempt_number) IS NOT NULL THEN 1 ELSE 0
END AS eventually_recovered
from first_attempts fa
LEFT JOIN saas.payment_attempts pa
ON fa.invoice_id = pa.invoice_id
AND pa.attempt_number > 1
AND pa.status = 'succeeded'
group by fa.invoice_id ,fa.account_id ,fa.failure_reason ,fa.amount)

select 
failure_reason
,count(*) as failed_invoices
,count(recovery_attempt) as recovered_invoices
,SUM(eventually_recovered)*100 / count(*) as recovery_rate
,SUM(eventually_recovered) AS eventually_recovered_invoices
,SUM(amount) AS mrr_at_risk
,SUM(CASE WHEN eventually_recovered = 1 THEN amount else 0 END) AS mrr_recovered
, PERCENTILE_CONT(0.5) WITHIN GROUP (order by recovery_attempt) as median_attempts_to_recovery
from recovered_attempts
GROUP BY failure_reason;
