/*
  metricTypeID: 5 (FDIC_calc)
  metricID: 9000
  Purpose: 9000_Noncurrent Loans to Total Loans
  Params:
	 {{IDRSSD}} INT
*/

WITH rcn AS (
	SELECT
		IDRSSD,
		[Reporting Period] AS rpt_period,
		CAST(COALESCE(RCFD1403, RCON1403, 0) AS DECIMAL(38,2)) AS nonaccrual_loans,
		CAST(COALESCE(RCFD1407, RCON1407, 0) AS DECIMAL(38,2)) AS dpd90_accruing
	FROM fdic_calls.dbo.RCN
	WHERE IDRSSD = {{IDRSSD}}
),
rcci AS (
	SELECT
		IDRSSD,
		[Reporting Period] AS rpt_period,
		CAST(COALESCE(RCFD2122, RCON2122, 0) AS DECIMAL(38,2)) AS loans_net_unearned
	FROM fdic_calls.dbo.RCCI
	WHERE IDRSSD = {{IDRSSD}}
)
SELECT
	rcn.rpt_period AS [Date],
	CASE WHEN rcci.loans_net_unearned <> 0 THEN 100.0 * (rcn.nonaccrual_loans + rcn.dpd90_accruing) / rcci.loans_net_unearned ELSE NULL END AS [Value]
FROM rcn
JOIN rcci ON ( rcci.IDRSSD = rcn.IDRSSD AND rcci.rpt_period = rcn.rpt_period )
ORDER BY rcn.rpt_period;
