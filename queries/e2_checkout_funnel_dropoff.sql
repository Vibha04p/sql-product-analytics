-- Q2 — Checkout Funnel Drop-off by Entry Channel

-- Business Question:
-- Where is checkout leaking, and is the leak the same across paid social vs organic search?

-- What this tells us:
-- Looking at drop-off percentages instead of raw numbers makes it much easier to compare channels of different sizes. While the number of sessions varies across channels, the percentages clearly show where users are abandoning the checkout journey.
--
-- Across all channels, the biggest drop-off happens between the payment and purchase steps, indicating that many users reach the payment stage but do not complete their purchase. Paid channels consistently have a higher drop-off at this stage than organic channels, suggesting that users acquired through paid campaigns may be facing more friction before completing

-- PM Action:
-- Prioritise an investigation into the payment-to-purchase step, as it is the largest point of abandonment across all channels. Review payment success rates, payment gateway errors, transaction failures, and session recordings to identify where users are dropping off. As a secondary investigation, analyse the address step to determine whether form complexity, validation errors, or UX friction are causing users to abandon checkout, particularly for paid traffic.
-- Schedule a session-recording and heatmap analysis for the payment-to-purchase step in the next sprint to identify where users abandon checkout. Compare behaviour across paid and organic channels to determine whether the issue is channel-specific or affects all users.

WITH session_step_reached AS (
  SELECT
    s.session_id
    , sc.channel
    , MAX(CASE
      WHEN se.event_type = 'purchase'        THEN 5
      WHEN se.event_type = 'add_payment'     THEN 4
      WHEN se.event_type = 'select_shipping' THEN 3
      WHEN se.event_type = 'add_address'     THEN 2
      WHEN se.event_type = 'begin_checkout'  THEN 1
      ELSE 0
    END) AS max_step
  FROM ecom.sessions s
  JOIN ecom.session_channels sc USING (session_id)
  JOIN ecom.session_events se USING (session_id)
  GROUP BY 1, 2
)
, channel_step_count as (
SELECT
  channel
  ,COUNT(*) FILTER (WHERE max_step >= 1) AS begin_checkout
  ,COUNT(*) FILTER (WHERE max_step >= 2) AS address
  ,COUNT(*) FILTER (WHERE max_step >= 3) AS shipping
  ,COUNT(*) FILTER (WHERE max_step >= 4) AS payment
  ,COUNT(*) FILTER (WHERE max_step >= 5) AS purchased
FROM session_step_reached
WHERE max_step >= 1
GROUP BY 1
ORDER BY begin_checkout DESC)

select
channel
,begin_checkout
, address
, shipping
, payment
, purchased
,(begin_checkout-address)*1.0 /begin_checkout *100 as drop_address_pct
,(address-shipping)*1.0 /address *100 as drop_shipping_pct
,(shipping-payment)*1.0 /shipping *100 as drop_payment_pct
,(payment-purchased)*1.0 /payment *100 as drop_final_pct
from channel_step_count;
