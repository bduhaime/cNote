/*
  metricTypeID: 4 (TGIM-U)
  metricID: 995
  Purpose: Training Attempt Utilization
  Params:
	 {{customerID}} INT
*/

select
	attemptMonth AS [Date],
	[pass],
	[fail],
	[viewed]
from (
	select
		a.chapterAttemptStatus,
		format( a.chapterAttemptDate, 'yyyy-MM-01' ) AS attemptMonth
	from lightspeed..userChapterAttempts a
	where a.locationID in (
		select locationID
		from lightspeed..locations
		where name like (
			select lsvtCustomerName + '%'
			from customer
			where id = {{customerID}}
		)
	)
) p
PIVOT (
	count(chapterAttemptStatus)
	for chapterAttemptStatus in ([pass],[fail],[viewed])
) as pvt
order by 1;
