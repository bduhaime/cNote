module.exports.set = function( https ) {

//===========================================================================================================
	https.get('/api/calendar/date-info', (req, res) => {
//===========================================================================================================

		const input = req.query.date;
		if (!input || !dayjs(input, 'YYYY-MM-DD', true).isValid()) {
			return res.status(400).json({ error: 'Invalid or missing date (expected YYYY-MM-DD)' });
		}

		const d = dayjs(input);
		const dayOfWeek = d.day(); // 0 = Sunday
		const isWeekend = dayOfWeek === 0 || dayOfWeek === 6;
		const holidayInfo = hd.isHoliday(d.toDate());
		const isHoliday = !!holidayInfo;

		// Extract holiday details (name, type, rule)
		let holidayDetails = [];
		if (holidayInfo) {
			if (Array.isArray(holidayInfo)) {
				holidayDetails = holidayInfo.map(h => ({
					name: h.name,
					type: h.type,
					rule: h.rule
				}));
			} else {
				holidayDetails = [{
					name: holidayInfo.name,
					type: holidayInfo.type,
					rule: holidayInfo.rule
				}];
			}
		}

		const isWorkday =  ( isWeekend || isHoliday ) ? false : true;

		res.json({
			date: d.format('YYYY-MM-DD'),
			year: d.year(),
			monthNumber: d.month() + 1,
			monthName: d.format('MMMM'),
			weekNumber: d.isoWeek(),
			dayOfMonth: d.date(),
			dayOfWeek: dayOfWeek,
			dayOfWeekName: d.format('dddd'),
			dayOfYear: d.dayOfYear(),
			isWeekday: !isWeekend,
			isUSHoliday: isHoliday,
			isWorkday: isWorkday,
			holidayDetails: holidayDetails,
		});

	});
//===========================================================================================================


//===========================================================================================================
	https.get('/api/calendar/holidays', (req, res) => {
//===========================================================================================================

		const input = req.query.year;
		if (!input || !dayjs(input, 'YYYY', true).isValid()) {
			return res.status(400).json({ error: 'Invalid or missing year (expected YYYY)' });
		}

		const blockedTypes = [ 'public', 'bank' ];
		const allHolidays = hd.getHolidays( input );
		const publicHolidays = allHolidays.filter( holiday => blockedTypes.includes( holiday.type ) );

		let result = [];

		for ( holiday of publicHolidays ) {
			result.push({
				date: dayjs( holiday.date ).format( 'YYYY-MM-DD' ),
				name: holiday.name
			})
		}

		res.json( result );

	});
//===========================================================================================================

//===========================================================================================================
	https.get('/api/calendar/isWorkday', (req, res) => {
//===========================================================================================================

	try {
		const input = req.query.date;
		if (!input || !dayjs(input, 'YYYY-MM-DD', true).isValid()) {
			return res.status(400).json({ error: 'Invalid or missing date (expected YYYY-MM-DD)' });
		}

		let isWorkday = utilities.isWorkday( input );

		res.json({ isWorkday });

	} catch( err ) {
		console.error( 'error in api/calendar/isWorkday', err );
	}

	});
//===========================================================================================================


//===========================================================================================================
	https.get('/api/calendar/workDaysAdd', (req, res) => {
//===========================================================================================================

	try {
		const input = req.query.date;
		if (!input || !dayjs(input, 'YYYY-MM-DD', true).isValid()) {
			return res.status(400).json({ error: 'Invalid or missing date (expected YYYY-MM-DD)' });
		}

		let days = req.query.days;
		days = parseInt(days, 10);
		if (isNaN(days)) {
			throw new Error(`Invalid days parameter: ${days}`);
		}

		let newDate = utilities.workDaysAddv2( input, days );

		res.json({ newDate });

	} catch( err ) {
		console.error( 'error in api/calendar/isWorkday', err );
	}

	});
//===========================================================================================================


//===========================================================================================================
	https.get('/api/calendar/workDaysBetweenv2', (req, res) => {
//===========================================================================================================

	try {
		const startDate = req.query.startDate;
		if (!startDate || !dayjs(startDate, 'YYYY-MM-DD', true).isValid()) {
			return res.status(400).json({ error: 'Invalid or missing startDate (expected YYYY-MM-DD)' });
		}

		const endDate = req.query.endDate;
		if (!endDate || !dayjs(endDate, 'YYYY-MM-DD', true).isValid()) {
			return res.status(400).json({ error: 'Invalid or missing endDate (expected YYYY-MM-DD)' });
		}

		let daysBetween  = utilities.workDaysBetweenv2( startDate, endDate );

		res.json({ daysBetween });

	} catch( err ) {
		console.error( 'error in api/calendar/workDaysBetweenv2', err );
	}

	});
//===========================================================================================================



}
