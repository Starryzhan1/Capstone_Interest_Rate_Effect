
-- fact_macro_quarter view--
create view fact_macro_month as
with months as (
    select date_trunc('month', min("Date"))::date as start_month,
           date_trunc('month', max("Date"))::date as end_month
    from unemployment_inflation ui
),
calendar as (
    select gs::date as month_start,
           (gs + interval '1 month - 1 day')::date as month_end,
           to_char(gs,'YYYYMM')::int as month_key
    from months m, generate_series(m.start_month, m.end_month, interval '1 month') gs
),
macro as (
    select to_char(date_trunc('month', "Date"),'YYYYMM')::int as month_key,
           avg("inflation_rate_YoY")   as inflation_rate_yoy,
           avg(unemployment_rate)      as unemployment_rate
    from unemployment_inflation ui
    group by 1
),
ecb_month_end as (
    select
        c.month_key,
        (select e.deposit_rate
           from ecb_interest_rate e
          where e.effective_date <= c.month_end
          order by e.effective_date desc
          limit 1) as ecb_deposit_rate,
        (select e.refinancing_rate
           from ecb_interest_rate e
          where e.effective_date <= c.month_end
          order by e.effective_date desc
          limit 1) as ecb_refi_rate,
        (select e.marginal_lending_rate
           from ecb_interest_rate e
          where e.effective_date <= c.month_end
          order by e.effective_date desc
          limit 1) as ecb_marginal_rate
    from calendar c
)
select
    c.month_key,
    c.month_start,
    m.inflation_rate_yoy,
    m.unemployment_rate,
    e.ecb_deposit_rate,
    e.ecb_refi_rate,
    e.ecb_marginal_rate
from calendar c
left join macro m using (month_key)
left join ecb_month_end e using (month_key);


CREATE VIEW fact_macro_quarter AS
WITH q_avg AS (
    SELECT
        date_trunc('quarter', month_start)::date AS quarter_start,
        ROUND(AVG(inflation_rate_yoy)::numeric, 2) AS inflation_rate_yoy,
        ROUND(AVG(unemployment_rate)::numeric, 2)  AS unemployment_rate
    FROM fact_macro_month
    GROUP BY 1
),
q_eoq AS (
    SELECT DISTINCT ON (date_trunc('quarter', month_start))
        date_trunc('quarter', month_start)::date AS quarter_start,
        ROUND(ecb_deposit_rate::numeric, 2)  AS ecb_deposit_rate,
        ROUND(ecb_refi_rate::numeric, 2)     AS ecb_refi_rate,
        ROUND(ecb_marginal_rate::numeric, 2) AS ecb_marginal_rate
    FROM fact_macro_month
    ORDER BY date_trunc('quarter', month_start), month_start DESC
)
SELECT
    TO_CHAR(a.quarter_start, 'YYYY') || '_Q' || EXTRACT(quarter FROM a.quarter_start)::int AS quarter_key,
    a.quarter_start,
    a.inflation_rate_yoy,
    a.unemployment_rate,
    e.ecb_deposit_rate,
    e.ecb_refi_rate,
    e.ecb_marginal_rate
FROM q_avg a
JOIN q_eoq e ON a.quarter_start = e.quarter_start
ORDER BY a.quarter_start;

--fact_bundesbank_quarter view--
CREATE VIEW fact_bundesbank_quarter AS
WITH
deposit_q AS (
  SELECT
    to_char(date_trunc('quarter', time), 'YYYY_"Q"Q') AS quarter_key,
    date_trunc('quarter', time)::date                 AS quarter_start,
    unit,
    unit_multiplier,
    ROUND(SUM(overnight_deposit_value)::numeric, 2)            AS overnight_deposit_value,
    ROUND(SUM(fixed_term_deposit_value)::numeric, 2)           AS fixed_term_deposit_value,
    ROUND(AVG(overnight_ptp_change_percentage)::numeric, 2)    AS overnight_ptp_change_percentage,
    ROUND(AVG(overnight_yoy_change_percentage)::numeric, 2)    AS overnight_yoy_change_percentage,
    ROUND(AVG(fixed_term_ptp_change_percentage)::numeric, 2)   AS fixed_term_ptp_change_percentage,
    ROUND(AVG(fixed_term_yoy_change_percentage)::numeric, 2)   AS fixed_term_yoy_change_percentage
  FROM deposit
  GROUP BY 1,2,3,4
),
investment_q AS (
  SELECT
    to_char(date_trunc('quarter', time), 'YYYY_"Q"Q') AS quarter_key,
    date_trunc('quarter', time)::date                 AS quarter_start,
    ROUND(SUM(investment_value)::numeric, 2)                      AS investment_value,
    ROUND(AVG(investment_ptp_change_percentage)::numeric, 2)      AS investment_ptp_change_percentage,
    ROUND(AVG(investment_yoy_change_percentage)::numeric, 2)      AS investment_yoy_change_percentage
  FROM "Investment"
  GROUP BY 1,2
),
loans_q AS (
  SELECT * FROM "Loan"
)
SELECT
  COALESCE(d.quarter_key, i.quarter_key, l.quarter_key)         AS quarter_key,
  COALESCE(d.quarter_start, i.quarter_start, l.quarter_start)   AS quarter_start,
  d.unit,
  d.unit_multiplier,
  d.overnight_deposit_value,
  d.fixed_term_deposit_value,
  d.overnight_ptp_change_percentage,
  d.overnight_yoy_change_percentage,
  d.fixed_term_ptp_change_percentage,
  d.fixed_term_yoy_change_percentage,
  l.total_loan_value,
  l.instalment_credit_value,
  l.housing_loan_value,
  l.total_loan_ptp_change_percentage,
  l.total_loan_yoy_change_percentage,
  l.instalment_credit_ptp_change_percentage,
  l.instalment_credit_yoy_change_percentage,
  l.housing_loan_ptp_change_percentage,
  l.housing_loan_yoy_change_percentage,
  i.investment_value,
  i.investment_ptp_change_percentage,
  i.investment_yoy_change_percentage
FROM deposit_q d
FULL OUTER JOIN investment_q i ON i.quarter_key = d.quarter_key
FULL OUTER JOIN loans_q      l ON l.quarter_key = COALESCE(d.quarter_key, i.quarter_key)
ORDER BY quarter_start;


--fact_bank_quarter View--
CREATE VIEW fact_bank_quarter AS
SELECT
    i.bank_name,
    i.quarter_key,
    i.quarter_start,
    i.bank_interest_income,
    i.bank_interest_expense,
    i.bank_net_interest_income,
    i.unit,
    i.unit_multiplier,
    r.tagesgeld_rate,
    r.festgeld_3m_rate,
    r.festgeld_6m_rate,
    r.festgeld_12m_rate
FROM bank_interest_income i
LEFT JOIN bank_rates_pivot_quarter r
  ON r.bank_name   = i.bank_name
 AND r.quarter_key = i.quarter_key;
 

--fact_bank_rate_event view--
CREATE VIEW fact_bank_rate_event AS
WITH tg AS (
  SELECT
    bank_name,
    'tagesgeld'::text AS product,
    NULL::int        AS term_months,
    time::date                           AS effective_date,
    tagesgeld_konto_percentage                     AS new_rate,
    LAG(tagesgeld_konto_percentage) OVER (
      PARTITION BY bank_name
      ORDER BY time
    )                                              AS prev_rate
  FROM bank_interest_rate
),
fg AS (
  SELECT
    bank_name,
    'festgeld'::text                               AS product,
    festgeld_fixed_term::int                       AS term_months,      
    time::date                           AS effective_date,
    festgeld_konto_percentage                      AS new_rate,          
    LAG(festgeld_konto_percentage) OVER (
      PARTITION BY bank_name, festgeld_fixed_term
      ORDER BY time
    )                                              AS prev_rate
  FROM bank_interest_rate
)
SELECT * FROM tg
WHERE new_rate IS NOT NULL AND (prev_rate IS DISTINCT FROM new_rate)
UNION ALL
SELECT * FROM fg
WHERE new_rate IS NOT NULL AND (prev_rate IS DISTINCT FROM new_rate);


--fact_ecb_bank_adjustment view--
CREATE VIEW fact_ecb_policy_event AS
SELECT
  effective_date AS ecb_date,
  deposit_rate,
  refinancing_rate,
  marginal_lending_rate
FROM ecb_interest_rate_new
ORDER BY ecb_date;

CREATE VIEW fact_ecb_bank_adjustment AS
WITH e AS (
  SELECT
    ecb_date,
    deposit_rate,
    refinancing_rate,
    marginal_lending_rate,
    LEAD(ecb_date) OVER (ORDER BY ecb_date) AS next_ecb_date
  FROM fact_ecb_policy_event
)
SELECT DISTINCT ON (b.bank_name, b.product, COALESCE(b.term_months, -1), e.ecb_date)
  b.bank_name,
  b.product,
  b.term_months,
  e.ecb_date,
  e.next_ecb_date,
  b.effective_date                      AS bank_change_date,
  (b.effective_date - e.ecb_date)       AS lag_days,        -- days to adjust
  (b.new_rate - b.prev_rate)            AS bank_delta,      -- bank's NEW rate - previous rate
  e.deposit_rate,
  e.refinancing_rate,
  e.marginal_lending_rate,
  TO_CHAR(b.effective_date, 'YYYY') || '_Q' || EXTRACT(QUARTER FROM b.effective_date) AS bank_change_quarter_key,
  TO_CHAR(e.ecb_date,       'YYYY') || '_Q' || EXTRACT(QUARTER FROM e.ecb_date)       AS ecb_quarter_key
FROM e
JOIN fact_bank_rate_event b
  ON b.effective_date > e.ecb_date
 AND (e.next_ecb_date IS NULL OR b.effective_date <= e.next_ecb_date)
ORDER BY
  b.bank_name, b.product, COALESCE(b.term_months, -1), e.ecb_date, b.effective_date;