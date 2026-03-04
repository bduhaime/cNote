/*
  metricTypeID: 4 (TGIM-U)
  metricID: 996
  Purpose: Training Attempt Utilization
  Params:
	 {{customerID}} INT
*/

select
	format(a.chapterAttemptDate, 'yyyy-MM-01') as [Date],
	count(distinct a.userID) as [Value]
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
group by format(chapterAttemptDate, 'yyyy-MM-01')
order by 1;
