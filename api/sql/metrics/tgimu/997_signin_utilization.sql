/*
  metricTypeID: 4 (TGIM-U)
  metricID: 995
  Purpose: Sign in Utilization
  Params:
	 {{customerID}} INT
*/

select
	format(a.accessDateTime, 'yyyy-MM-01') as [Date],
	count(distinct a.userID) as [Value]
from lightspeed..usersAccessInfo a
where a.locationID in (
	select locationID
	from lightspeed..locations
	where name like (
		select lsvtCustomerName + '%'
		from customer
		where id = {{customerID}}
	)
	and isActive = 1
)
group by format(a.accessDateTime, 'yyyy-MM-01')
order by 1;
