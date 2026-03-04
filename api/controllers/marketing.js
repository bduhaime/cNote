// ----------------------------------------------------------------------------------------
// Copyright 2017-2023, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get('/api/marketing/institutions', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		let maxAssets = req.query.maxAssets ? req.query.maxAssets : 250000000;
		let reportingPeriod = await getMostRecentReportingPeriod();

		let SQL 	= 	`
			select
				i.cert,
				i.Fed_RSSD,
				i.NAME,
				i.STALP,
				i.SPECGRPN,
				i.WEBADDR,
				CASE WHEN i.PARCERT <> '0' THEN i.PARCERT ELSE null END as PARCERT,
				i.OFFICES,
				case when i.MUTUAL = '1' then 'Mutual' else case when i.MUTUAL = '0' then 'Non-Mutual' else '' end end as MUTUAL,
				r1.UBPR2170,
				r1.UBPRE209,
				r1.UBPRK435,
				r1.UBPRE200,
				r1.UBPRE153,
				r1.UBPR2200,
				r1.UBPRE162,
				r1.UBPRE141,
				r2.UBPRD487,
				r2.UBPRE630,
				r3.UBPR7316,
				r3.UBPRE027,
				r3.UBPR7414,
				r3.UBPRE006,
				r3.UBPRE020,
				r3.UBPRE013,
				r3.UBPRE018,
				r3.UBPRE019,
				r3.UBPRE004,
				r4.UBPRM009,
				r4.UBPRE591,
				r4.UBPRE601,
				r4.UBPRE600,
				r5.UBPRE088,
				r5.UBPRE090,
				r6.UBPRK441,
				r6.UBPRE371,
				r6.UBPRE372,
				r6.UBPRE380,
				r7.UBPRKW06,
				r7.UBPRKW08,
				r7.UBPRE070,
				r7.UBPRE075,
				r8.UBPRE023,
				cast( k1.UBPKE209 as int ) as UBPKE209,
				cast( k2.UBPKD487 as int ) as UBPKD487,
				cast( k2.UBPKE630 as int ) as UBPKE630,
				cast( k3.UBPK7316 as int ) as UBPK7316,
				cast( k3.UBPKE027 as int ) as UBPKE027,
				cast( k3.UBPK7414 as int ) as UBPK7414,
				cast( k3.UBPKE019 as int ) as UBPKE019,
				cast( k3.UBPKE006 as int ) as UBPKE006,
				cast( k3.UBPKE020 as int ) as UBPKE020,
				cast( k3.UBPKE013 as int ) as UBPKE013,
				cast( k3.UBPKE018 as int ) as UBPKE018,
				cast( k3.UBPKE004 as int ) as UBPKE004,
				cast( k4.UBPKM009 as int ) as UBPKM009,
				cast( k4.UBPKE591 as int ) as UBPKE591,
				cast( k4.UBPKE601 as int ) as UBPKE601,
				cast( k4.UBPKE600 as int ) as UBPKE600,
				cast( k5.UBPKE088 as int ) as UBPKE088,
				cast( k5.UBPKE090 as int ) as UBPKE090,
				cast( k6.UBPKK441 as int ) as UBPKK441,
				cast( k6.UBPKE371 as int ) as UBPKE371,
				cast( k6.UBPKE372 as int ) as UBPKE372,
				cast( k6.UBPKE380 as int ) as UBPKE380,
				cast( k7.UBPKE075 as int ) as UBPKE075,
				cast( k8.UBPKE023 as int ) as UBPKE023,
				cast( a.RIAD4230 as int ) as RIAD4230,
				cs.name as customerStatusName,
				i.CITY,
				case when i.CB = '1' then 'True' else case when i.CB = '0' then 'False' else '' end end as CB,
				i.ADDRESS,
				i.ZIP,
				il.label
			from fdic..institutions i
			left join fdic_ratios..BalanceSheetDollar r1 on ( r1.[id rssd] = i.FED_RSSD and r1.[Reporting Period] = @reportingPeriod )
			left join fdic_ratios..CapitalAnalysisA r2 on ( r2.[id rssd] = i.FED_RSSD and r2.[Reporting Period] = @reportingPeriod )
			left join fdic_ratios..SummaryRatios r3 on ( r3.[id rssd] = i.FED_RSSD and r3.[Reporting Period] = @reportingPeriod )
			left join fdic_ratios..LiquidityFunding r4 on ( r4.[id rssd] = i.FED_RSSD and r4.[Reporting Period] = @reportingPeriod )
			left join fdic_ratios..NonIntIncExpYields r5 on ( r5.[id rssd] = i.FED_RSSD and r5.[Reporting Period] = @reportingPeriod )
			left join fdic_ratios..BalanceSheetPercent r6 on ( r6.[id rssd] = i.FED_RSSD and r6.[Reporting Period] = @reportingPeriod )
			left join fdic_ratios..IncomeStatementDollar r7 on ( r7.[id rssd] = i.FED_RSSD and r7.[Reporting Period] = @reportingPeriod )
			left join fdic_ratios..AllowanceLoanMixA r8 on ( r8.[id rssd] = i.FED_RSSD and r8.[Reporting Period] = @reportingPeriod )
			left join fdic_calls..ribii a on ( a.idrssd = i.FED_RSSD and a.[reporting period] = @reportingPeriod )
			left join fdic_ranks..BalanceSheetDollar k1 on ( k1.[id rssd] = i.FED_RSSD and k1.[Reporting Period] = @reportingPeriod and k1.[peer group] in ( '1','10','101','102','103','104','11','13','14','15','2','201','3','4','401','5','6','7','8','9' ) )
			left join fdic_ranks..CapitalAnalysisA k2 on ( k2.[id rssd] = i.FED_RSSD and k2.[Reporting Period] = @reportingPeriod and k2.[peer group] in ( '1','10','101','102','103','104','11','13','14','15','2','201','3','4','401','5','6','7','8','9' ) )
			left join fdic_ranks..SummaryRatios k3 on ( k3.[id rssd] = i.FED_RSSD and k3.[Reporting Period] = @reportingPeriod and k3.[peer group] in ( '1','10','101','102','103','104','11','13','14','15','2','201','3','4','401','5','6','7','8','9' ) )
			left join fdic_ranks..LiquidityFunding k4 on ( k4.[id rssd] = i.FED_RSSD and k4.[Reporting Period] = @reportingPeriod and k4.[peer group] in ( '1','10','101','102','103','104','11','13','14','15','2','201','3','4','401','5','6','7','8','9' ) )
			left join fdic_ranks..NonIntIncExpYields k5 on ( k5.[id rssd] = i.FED_RSSD and k5.[Reporting Period] = @reportingPeriod and k5.[peer group] in ( '1','10','101','102','103','104','11','13','14','15','2','201','3','4','401','5','6','7','8','9' ) )
			left join fdic_ranks..BalanceSheetPercent k6 on ( k6.[id rssd] = i.FED_RSSD and k6.[Reporting Period] = @reportingPeriod and k6.[peer group] in ( '1','10','101','102','103','104','11','13','14','15','2','201','3','4','401','5','6','7','8','9' ) )
			left join fdic_ranks..IncomeStatementDollar k7 on ( k7.[id rssd] = i.FED_RSSD and k7.[Reporting Period] = @reportingPeriod and k7.[peer group] in ( '1','10','101','102','103','104','11','13','14','15','2','201','3','4','401','5','6','7','8','9' ) )
			left join fdic_ranks..AllowanceLoanMixA k8 on ( k8.[id rssd] = i.FED_RSSD and k8.[Reporting Period] = @reportingPeriod and k8.[peer group] in ( '1','10','101','102','103','104','11','13','14','15','2','201','3','4','401','5','6','7','8','9' ) )
			left join customer c on ( c.cert = i.cert and ( c.deleted = 0 or c.deleted is null ) )
			left join customerStatus cs on (cs.id = c.customerStatusID and ( cs.deleted = 0 or cs.deleted is null) )
			left join fdic..institutionLabels il on ( il.cert = i.cert )
			where i.ACTIVE = '1'
			and i.asset < @maxAssets
			and i.name not like '%wells fargo%'
			order by i.asset desc
		`

			// console.log( SQL )

		sql.connect( dbConfig ).then( pool => {

			return pool.request()
				.input( 'maxAssets', sql.Money, maxAssets )
				.input( 'reportingPeriod', reportingPeriod )
				.query( SQL )

		}).then( result => {

			// console.log( 'marketing dataset resolved and resturning rows:', result.rowsAffected )
			res.json({
				params: {
					maxAssets: maxAssets,
					reportingPeriod: dayjs( reportingPeriod ).format( 'YYYY-MM-DD' ),
				},
				data: result.recordset
			})

		}).catch( err => {

			logger.log({ level: 'error', label: 'marketing/institutions', message: err, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/marketing/institutions/map', utilities.jwtVerify, async (req, res) => {
	//====================================================================================
// 		console.log( 'mapit!' )

		if ( !req.query.certList ) return res.status( 400 ).send( 'certList parameter missing' )
		const certList = req.query.certList
		// const certList = '57957,24735,59017,6672,588,34221,32992,17534,6560,57803,57890,16571,913,12368'	// for debugging only

		let SQL 	= 	`select `
					+		`g.latitude, `
					+		`g.longitude, `
					+		`i.NAME `
					+	`from fdic..institutions i `
					+	`join fdic..institutionGeocodes g on ( g.cert = i.cert ) `
					+	`where i.CERT in ( select value from STRING_SPLIT( @certList, ',' ) ) `

			// console.log( SQL )

		sql.connect( dbConfig ).then( pool => {

			return pool.request()
				.input( 'certList', certList )
				.query( SQL )

		}).then( result => {

			let dataset = []
			dataset.push( [ 'Lat', 'Long', 'Name' ] )
			for ( row of result.recordset ) {
				dataset.push( [ row.latitude, row.longitude, row.NAME ] )
			}
			res.json( dataset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'marketing/institutions', message: err, user: req.session.username })
			return res.status( 500 ).send( 'Unexpected database error' )

		})

	})
	//====================================================================================


	//====================================================================================
	https.post('/api/marketing/labels', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		logger.log({ level: 'debug', label: 'POST:marketing/labels', message: 'start of POST:marketing/labels', user: req.session.userID })

		if ( !req.body.cert ) return res.status( 400 ).send( 'cert parameter missing' )

		let SQL	= 	`merge fdic..institutionLabels target `
					+	`using ( select * from fdic..institutions where cert = @cert ) source  `
					+	`on ( target.cert = source.cert ) `
					+	`when matched then `
					+		`update set `
					+			`target.[label] = @label `
					+	`when not matched then `
					+		`insert ( cert, [label] ) `
					+		`values ( @cert, @label ) `
					+	`; `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'cert', sql.BigInt, req.body.cert )
				.input( 'label', sql.VarChar( sql.Max ), req.body.label )
				.query( SQL )

		}).then( result => {

			res.sendStatus( 200 )
			// return res.status( 200 ).send( 'Call lead updated' )

		}).catch( err => {

			debugger
			logger.log({ level: 'error', label: 'POST:marketing/labels', message: err, user: req.session.userID })
			console.error( err )
			return res.status( 500 ).send( 'Unexpected database error' )

		})


	})
	//====================================================================================


	//====================================================================================
	https.post('/api/marketing/labels/replace', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		logger.log({ level: 'debug', label: 'POST:marketing/labels/replace', message: 'start of POST:marketing/labels/replace', user: req.session.userID })

		if ( !req.body.certs ) return res.status( 400 ).send( 'certs parameter array missing' )
		if ( !req.body.label ) return res.status( 400 ).send( 'label parameter missing' )

		let SQL	= 	`merge fdic..institutionLabels target `
					+	`using ( `
					+		`select  `
					+			`i.cert, `
					+			`il.label `
					+		`from fdic..institutions i `
					+		`left join fdic..institutionLabels il on ( il.cert = i.cert ) `
					+		`where i.cert in ( select value from STRING_SPLIT( @certlist, ',' ) ) `
					+	`) source  `
					+	`on ( target.cert = source.cert ) `
					+	`when matched then `
					+		`update set `
					+			`target.[label] = @label `
					+	`when not matched then `
					+		`insert ( cert, [label] ) `
					+		`values ( source.cert, @label ) `
					+	`; `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'certlist', req.body.certs )
				.input( 'label', sql.VarChar( sql.Max ), req.body.label )
				.query( SQL )

		}).then( result => {

			res.sendStatus( 200 )

		}).catch( err => {

			debugger
			logger.log({ level: 'error', label: 'POST:marketing/labels/replace', message: err, user: req.session.userID })
			console.error( err )
			return res.status( 500 ).send( 'Unexpected database error' )

		})


	})
	//====================================================================================


	//====================================================================================
	https.post('/api/marketing/labels/append', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		logger.log({ level: 'debug', label: 'POST:marketing/labels/append', message: 'start of POST:marketing/labels/append', user: req.session.userID })

		if ( !req.body.certs ) return res.status( 400 ).send( 'certs parameter array missing' )
		if ( !req.body.label ) return res.status( 400 ).send( 'label parameter missing' )

		let SQL	= 	`merge fdic..institutionLabels target `
					+	`using ( `
					+		`select  `
					+			`i.cert, `
					+			`il.label `
					+		`from fdic..institutions i `
					+		`left join fdic..institutionLabels il on ( il.cert = i.cert ) `
					+		`where i.cert in ( select value from STRING_SPLIT( @certlist, ',' ) ) `
					+	`) source  `
					+	`on ( target.cert = source.cert ) `
					+	`when matched then `
					+		`update set `
					+			`target.[label] = target.[label] + ' ' + @label `
					+	`when not matched then `
					+		`insert ( cert, [label] ) `
					+		`values ( source.cert, @label ) `
					+	`; `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'certlist', String(req.body.certs) )
				.input( 'label', sql.VarChar( sql.Max ), req.body.label )
				.query( SQL )

		}).then( result => {

			res.sendStatus( 200 )
			// return res.status( 200 ).send( 'Call lead updated' )

		}).catch( err => {

			debugger
			logger.log({ level: 'error', label: 'POST:marketing/labels/append', message: err, user: req.session.userID })
			console.error( err )
			return res.status( 500 ).send( 'Unexpected database error' )

		})


	})
	//====================================================================================


	//====================================================================================
	https.delete('/api/marketing/labels', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		logger.log({ level: 'debug', label: 'DELETE:marketing/labels', message: 'start of DELETE:marketing/labels', user: req.session.userID })

		if ( !req.body.certs ) return res.status( 400 ).send( 'certs parameter string missing' )

		let SQL	= 	`delete from fdic..institutionlabels `
					+	`where cert in ( select value from STRING_SPLIT( @certlist, ',' ) ) `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'certlist', req.body.certs )
				.query( SQL )

		}).then( result => {

			res.sendStatus( 200 )
			// return res.status( 200 ).send( 'Call lead updated' )

		}).catch( err => {

			debugger
			logger.log({ level: 'error', label: 'DELETE:marketing/labels', message: err, user: req.session.userID })
			console.error( err )
			return res.status( 500 ).send( 'Unexpected database error' )

		})


	})
	//====================================================================================


	//====================================================================================\
	function getMostRecentReportingPeriod() {
	//====================================================================================

		return new Promise( (resolve, reject) => {

			let SQL 	= 	`
				select max(reportingPeriod) as reportingPeriod
				from (
					select cast(max([reporting period]) as datetime) as reportingPeriod
					from fdic_ranks.dbo.SummaryRatios
					where source = 'bulk'
					union
					select cast(max([reporting period]) as datetime) as reportingPeriod
					from fdic_ratios.dbo.SummaryRatios
					where source = 'bulk'
					union
					select cast(max([reporting period]) as datetime) as reportingPeriod
					from fdic_stats.dbo.SummaryRatios
					where source = 'bulk'
				) as x;
			`;

			sql.connect(dbConfig).then( pool => {

				return pool.request().query( SQL )

			}).then( results => {

				return resolve( results.recordset[0].reportingPeriod )

			}).catch( err => {

				console.error( 'Error in getMostRecentReportingPeriod()' )
				reject( err )

			})

		})

	}
	//====================================================================================



}
