// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	let dbConfig = require('../config/database.json').mssql;

	let db = require('../config/dbSecretShopper.js');

	let {
		Editor,
		Field,
		Validate,
		Format,
		Options
	} = require("datatables.net-editor-server");

	//====================================================================================
	https.all( '/api/mysteryShopping/questionCategories', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		let editor = new Editor( db, 'questionCategories' );

		editor.fields(

			new Field( "name" )
				.validator( Validate.notEmpty() ),

			new Field( "seq" )
				.validator( Validate.notEmpty() )

		);

		await editor.process( req.body );
		res.json( editor.data() );

	});
	//====================================================================================


	//====================================================================================
	https.all('/api/mysteryShopping/questions', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		const editor = new Editor(db, 'distinctQuestions');

		editor.fields(
			new Field('distinctQuestions.questionCategoryID', 'categoryID')
			// Show blank in the UI when DB is NULL
			.getFormatter((val) => (val == null ? '' : val))
			// Persist NULL when user picks “None”
			.setFormatter((val) => (val === '' || val == null || val === 'null' ? null : val))
			// Supply options via a function (so Editor can await it)
			.options(async () => {
				const rows = await db('questionCategories')
					.select({ value: 'id', label: 'name' })
					.orderBy('name');
				// Put “None” at the top; UI uses empty string, DB stores NULL via setFormatter
				return [{ label: '— None —', value: '' }, ...rows];
			}),

			new Field('questionCategories.name', 'categoryName'),

			new Field('distinctQuestions.id', 'questionID')
				.validator(Validate.notEmpty()),

			new Field('distinctQuestions.rawText', 'question')
				.validator(Validate.notEmpty())

		);

		editor.leftJoin(
			'questionCategories',
			'questionCategories.id',
			'=',
			'distinctQuestions.questionCategoryID'
		);

		await editor.process(req.body);
		res.json(editor.data());

	});
	//====================================================================================


	//====================================================================================
	https.get('/api/mysteryShopping/mostMissedQuestion', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if (!req.query.statusList) return res.status(400).send('Parameter missing');

			// Get active bank names for the provided statuses
			const bankNames = await getAllBankNamesByStatus(req.query.statusList);
			if (!Array.isArray(bankNames) || bankNames.length === 0) {
			return res.status(404).json({ error: 'No active banks for given statuses' });
			}

			// Optional date window (defaults: last 12 months)
			const startDate = req.query.startDate ? new Date(req.query.startDate)
			: new Date(new Date().setFullYear(new Date().getFullYear() - 1 ));
			const endDate   = req.query.endDate ? new Date(req.query.endDate) : new Date();

			const pool = await sql.connect(dbConfig);

			const SQL = `
				-- Turn the JSON array into rows
				WITH BankNames AS (
					SELECT LTRIM(RTRIM([value])) AS BankName
					FROM OPENJSON(@bankListJson)
				),
				-- Escape SQL LIKE wildcards present in bank names
				Escaped AS (
					SELECT REPLACE(REPLACE(REPLACE(BankName, '[', '[[]'), '%', '[%]'), '_', '[_]') AS BankName
					FROM BankNames
				)
				SELECT TOP 1
					dq.rawText AS questionText,
					qc.name    AS categoryName,
					COUNT(*)   AS missedCount
				FROM secretShopper.dbo.locations          AS l
				JOIN secretShopper.dbo.shops              AS s  ON s.locationID = l.locationID
				JOIN secretShopper.dbo.questions          AS q  ON q.shopID     = s.shopID
				JOIN secretShopper.dbo.distinctQuestions  AS dq ON TRIM(dq.rawText) = TRIM(q.question)
				JOIN secretShopper.dbo.questionCategories AS qc ON qc.id        = dq.questionCategoryID
				WHERE s.dateShopped BETWEEN @startDate AND @endDate
				AND s.Score NOT IN ('N/A', '100.00%')
				AND q.score NOT IN ('N/A')
				AND q.answer NOT IN ('No')
				-- only include locations whose l.name CONTAINS any active bank name
				AND EXISTS (
					SELECT 1
					FROM Escaped b
					WHERE l.name LIKE '%' + b.BankName + '%'
				)
				GROUP BY dq.rawText, qc.name
				ORDER BY COUNT(*) DESC, dq.rawText ASC; -- deterministic tiebreak
			`;

			const { recordset } = await pool.request()
			.input('bankListJson', sql.NVarChar(sql.MAX), JSON.stringify(bankNames))
			.input('startDate',    sql.DateTime, startDate)
			.input('endDate',      sql.DateTime, endDate)
			.query(SQL);

			res.json(recordset ?? []);
			// or if you only want the string: res.json(recordset[0]?.questionText ?? null);

		} catch (err) {

			logger.log({
			level: 'error',
			label: 'GET:api/mysteryShopping/mostMissedQuestion',
			message: err,
			user: req.session.userID
			});
			res.sendStatus(500);

		}

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/uncategorizedQuestions', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		const SQL =	`
			select count(*) as uncategorizedQuestions
			from secretShopper.dbo.distinctQuestions
			where questionCategoryID is null;
		`;

		sql.connect(dbConfig).then( pool => {

			return pool.request().query( SQL );

		}).then( result => {

			res.json( result.recordset );

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/uncategorizedQuestions', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		});

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/mostMissedQuestionByCustomer', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' );

		const branchPredicate 	= buildBranchPredicate( req.query.branch );
		const locationPredicate = buildLocationPredicate( req.query.locationID );

		// const bankNames = await getBankNames( req.query.customerID )

		const SQL =	`
			select top 1
				dq.rawText as questionText,
				qc.name as categoryName,
				count(*) as missedCount
			from secretShopper.dbo.locations l
			join secretShopper.dbo.shops s on (s.locationID = l.locationID)
			join secretShopper.dbo.questions q on (q.shopID = s.shopID)
			join secretShopper.dbo.distinctQuestions dq on ( trim(dq.rawTextHash) = trim(q.questionHash) )
			join secretShopper.dbo.questionCategories qc on (qc.id = dq.questionCategoryID)
			where dateShopped between @startDate and @endDate
			and l.cnote_customerID = @customerID
			and s.Score not in ( 'N/A', '100.00%' )
			and q.score not in ( 'N/A' )
			and q.answer not in ( 'No' )
			${branchPredicate}
			${locationPredicate}
			group by dq.rawText, qc.name
			order by 2 desc;
		`;

		// console.log({
		// 	customerID: req.query.customerID,
		// 	startDate: req.query.startDate,
		// 	endDate: req.query.endDate,
		// 	branchPredicate: branchPredicate,
		// 	locationPredicate: locationPredicate
		// })


		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'startDate', sql.Date, dayjs( req.query.startDate ).startOf('day').toDate() )
				.input( 'endDate', sql.Date, dayjs( req.query.endDate ).startOf('day').toDate() )
				.query( SQL );

		}).then( result => {

			res.json( result.recordset );

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/mostMissedQuestionByCustomer', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		});

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/mostMissedQuestionCategoryByCustomer', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' );

		const branchPredicate 	= buildBranchPredicate( req.query.branch );
		const locationPredicate = buildLocationPredicate( req.query.locationID );


		// const bankNames = await getBankNames( req.query.customerID )
		// console.log( {bankNames})

		const SQL =	`
			select top 1
				qc.name,
				count(*)
			from secretShopper.dbo.locations l
			join secretShopper.dbo.shops s on (s.locationID = l.locationID)
			join secretShopper.dbo.questions q on (q.shopID = s.shopID)
			join secretShopper.dbo.distinctQuestions dq on ( trim(dq.rawText) = trim(q.question) )
			join secretShopper.dbo.questionCategories qc on (qc.id = dq.questionCategoryID)
			where dateShopped between @startDate and @endDate
			and l.cnote_customerID = @customerID
			and s.Score not in ( 'N/A', '100.00%' )
			and q.score not in ( 'N/A' )
			and q.answer not in ( 'No' )
			${branchPredicate}
			${locationPredicate}
			group by qc.name
			order by 2 desc;
		`;

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'startDate', sql.Date, dayjs( req.query.startDate ).startOf('day').toDate() )
				.input( 'endDate', sql.Date, dayjs( req.query.endDate ).startOf('day').toDate() )
				.query( SQL );

		}).then( result => {

			res.json( result.recordset );

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/mostMissedQuestionCategoryByCustomer', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		});

	});
	//====================================================================================


	//====================================================================================
	https.get('/api/mysteryShopping/mostMissedQuestionCategory', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if (!req.query.statusList) return res.status(400).send('Parameter missing');

			// You already have this util — returns an array of bank names
			const bankNames = await getAllBankNamesByStatus(req.query.statusList);

			if (!Array.isArray(bankNames) || bankNames.length === 0) {
				return res.status(404).json({ error: 'No active banks found for given statuses' });
			}

			// optional: allow caller to override window; otherwise use last 12 months
			const startDate = req.query.startDate ? new Date(req.query.startDate) : new Date(new Date().setFullYear(new Date().getFullYear() - 1 ));
			const endDate   = req.query.endDate   ? new Date(req.query.endDate)   : new Date();

			const pool = await sql.connect(process.env.SQL_CONNECTION_STRING);

			const SQL = `
				-- Turn the JSON array into rows
				WITH BankNames AS (
					SELECT LTRIM(RTRIM([value])) AS BankName
					FROM OPENJSON(@bankListJson)
				),
				-- Escape SQL LIKE wildcards found in real bank names
				Escaped AS (
					SELECT
					-- escape %, _, [
					REPLACE(REPLACE(REPLACE(BankName, '[', '[[]'), '%', '[%]'), '_', '[_]') AS BankName
					FROM BankNames
				)
				SELECT TOP 1
					qc.name   AS categoryName,
					COUNT(*)  AS missedCount
				FROM secretShopper.dbo.locations          AS l
				JOIN secretShopper.dbo.shops              AS s  ON s.locationID = l.locationID
				JOIN secretShopper.dbo.questions          AS q  ON q.shopID     = s.shopID
				JOIN secretShopper.dbo.distinctQuestions  AS dq ON TRIM(dq.rawText) = TRIM(q.question)
				JOIN secretShopper.dbo.questionCategories AS qc ON qc.id        = dq.questionCategoryID
				WHERE s.dateShopped BETWEEN @startDate AND @endDate
				AND s.Score NOT IN ('N/A', '100.00%')
				AND q.score NOT IN ('N/A')
				AND q.answer NOT IN ('No')
				-- only include locations whose l.name CONTAINS any bank name
				AND EXISTS (
					SELECT 1
					FROM Escaped b
					WHERE l.name LIKE '%' + b.BankName + '%'
				)
				GROUP BY qc.name
				ORDER BY COUNT(*) DESC;
			`;

			const { recordset } = await pool.request()
				.input('bankListJson', sql.NVarChar(sql.MAX), JSON.stringify(bankNames))
				.input('startDate',    sql.DateTime, startDate)
				.input('endDate',      sql.DateTime, endDate)
				.query(SQL);

			res.json(recordset ?? []);

		} catch (err) {
			console.error(err);
			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/mostMissedQuestionCategory', message: err, user: req.session.userID });
			res.sendStatus(500);
		}

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/msBanksWithoutCustomers', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		const SQL =	`
			select distinct
				trim( bankName ) as bankName,
				format( max( s.dateShopped ), 'yyyy-MM-dd' ) as lastDateShopped
			from secretShopper.dbo.locations l
			left join secretShopper.dbo.shops s on ( s.locationID = l.locationID )
			where trim(l.bankName) not in (
				select trim( value ) as xref
				from customer c
				cross apply STRING_SPLIT( secretShopperLocationName, ',' )
			)
			group by trim( bankName )
			order by 1;
		`;


		sql.connect(dbConfig).then( pool => {

			return pool.request().query( SQL );

		}).then( result => {

			res.json( result.recordset );

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/msBanksWithoutCustomers', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		});

	})
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/minMaxShopDatesForCustomer', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );

		// let bankNames = await getBankNames( req.query.customerID );

		const SQL =	`
			select
				format( min( dateShopped ), 'MM/dd/yyyy' ) as minDate,
				format( max( dateShopped ), 'MM/dd/yyyy' ) as maxDate
			from secretShopper.dbo.locations l
			join secretShopper.dbo.shops s on ( s.locationID = l.locationID )
			where l.cnote_customerID = @cnote_customerID;
		`;

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'cnote_customerID', req.query.customerID )
				.query( SQL );

		}).then( result => {

			res.json( result.recordset[0] );

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/minMaxShopDatesForCustomer', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		});

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/distinctBranches', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' )

		// let bankNames = await getBankNames( req.query.customerID )

		// 2025-12-23 -- implemented using "cnote_city" as a proxy for "branch" because the data
		//               from secretshopper.com is messy and unreliable
		//

		const SQL =	`
			select distinct trim( l.cnote_city ) as branchName
			from secretShopper.dbo.locations l
			where l.cnote_customerID = @customerID
			order by l.cnote_city
		`;

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', req.query.customerID )
				.query( SQL );

		}).then( result => {

			res.json( result.recordset )

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/distinctBranches', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/averageGrade', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' );

		const branchPredicate = buildBranchPredicate( req.query.branch );
		// const bankNames = await getBankNames( req.query.customerID );

		const SQL =	`
			select
				avg( cast(replace( score, '%', '' ) as NUMERIC(5,2))/100 ) as averageScore
			from secretShopper.dbo.locations l
			join secretShopper.dbo.shops s on ( s.locationID = l.locationID )
			where l.cnote_customerID = @cnote_customerID
			and dateShopped between @startDate and @endDate
			${branchPredicate}
			and ( s.score <> 'N/A' );
		`;


		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'cnote_customerID',  sql.BigInt, req.query.customerID )
				.input( 'startDate', sql.Date, dayjs( req.query.startDate ).startOf('day').toDate() )
				.input( 'endDate', sql.Date, dayjs( req.query.endDate ).startOf('day').toDate() )
				.query( SQL );

		}).then( result => {

		const score = result.recordset[0].averageScore;

		const grade =
			score >= 0.90 ? 'A' :
			score >= 0.80 ? 'B' :
			score >= 0.70 ? 'C' :
			'D';

		res.json({ score, grade });

	}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/averageGrade', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		})

	})
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/totalNaShops', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );
			if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' );
			if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' );

			const branchPredicate = buildBranchPredicate( req.query.branch );
			// const bankNames = await getBankNames( req.query.customerID )

			const dataconn	= await sql.connect( dbConfig )

			const SQL =	`
				select
					SUM( CASE WHEN ( score = 'N/A' OR CAST ( replace( score, '%', '' ) AS NUMERIC ( 5, 2 ) ) < 100.00 ) THEN 1 ELSE 0 END ) AS totalNaShops,
					count(*) as totalShops
				from secretShopper.dbo.locations l
				left join secretShopper.dbo.shops s on ( s.locationID = l.locationID and dateShopped between @startDate and @endDate )
				where l.cnote_customerID = @customerID
				${branchPredicate};
			`;

			let results = await dataconn.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'startDate', sql.Date, dayjs( req.query.startDate ).startOf('day').toDate() )
				.input( 'endDate', sql.Date, dayjs( req.query.endDate ).startOf('day').toDate() )
				.query( SQL );

			res.json({
				naShops: results.recordset[0].totalNaShops,
				totalShops: results.recordset[0].totalShops
			});

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/totalNaShops', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		}

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/branchesShopped', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );
			if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' );
			if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' );

			const branchPredicate = buildBranchPredicate( req.query.branch );
			// const bankNames = await getBankNames( req.query.customerID );

			const dataconn	= await sql.connect( dbConfig );

			// get the total number of branches for the bank
			// NOTE: count(distinct grouperDistrict) wont work because sometimes grouperDistrict is null
			const sql_A = `
				select distinct l.cnote_city
				from secretShopper.dbo.locations l
				where l.cnote_customerID = @customerID
				${branchPredicate}
			`;

			const results_A = await dataconn.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( sql_A );

			// get total number of branches shopped
			const sql_B = `
				select distinct l.cnote_city
				from secretShopper.dbo.locations l
				join secretShopper.dbo.shops s on (s.locationID = l.locationID)
				where l.cnote_customerID = @customerID
				and dateShopped between @startDate and @endDate
				${branchPredicate}
			`;

			let results_B = await dataconn.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'startDate', sql.Date, dayjs( req.query.startDate ).startOf('day').toDate() )
				.input( 'endDate', sql.Date, dayjs( req.query.endDate ).startOf('day').toDate() )
				.query( sql_B );

			res.json({
				shopped: results_B.rowsAffected,
				total: results_A.rowsAffected
			});

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/branchesShopped', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		}

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/supervisorsShopped', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );
			if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' );
			if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' );

			const branchPredicate = buildBranchPredicate( req.query.branch );
			// const bankNames = await getBankNames( req.query.customerID );

			const dataconn	= await sql.connect( dbConfig );

			// get the total number of branches for the bank
			// NOTE: count(distinct grouperDistrict) wont work because sometimes grouperDistrict is null
			const sql_A = `
				select distinct grouperArea
				from secretShopper.dbo.locations l
				where l.cnote_customerID = @customerID
				${branchPredicate};
			`;

			const results_A = await dataconn.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( sql_A );

			// get total number of branches shopped
			const sql_B = `
				select distinct grouperArea
				from secretShopper.dbo.locations l
				join secretShopper.dbo.shops s on (s.locationID = l.locationID)
				where l.cnote_customerID = @customerID
				and dateShopped between @startDate and @endDate
				${branchPredicate};
			`;

			const results_B = await dataconn.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'startDate', sql.Date, dayjs( req.query.startDate ).startOf('day').toDate() )
				.input( 'endDate', sql.Date, dayjs( req.query.endDate ).startOf('day').toDate() )
				.query( sql_B );

			res.json({
				shopped: results_B.rowsAffected,
				total: results_A.rowsAffected
			});

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/supervisorsShopped', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		}

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/bankersShopped', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );
			if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' );
			if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' );

			const branchPredicate = buildBranchPredicate( req.query.branch );
			// const bankNames = await getBankNames( req.query.customerID )

			const dataconn	= await sql.connect( dbConfig )

			// get the total number of bankers.dbo..
			const sql_A = `
				select count( distinct l.locationID ) as total
				from secretShopper.dbo.locations l
				where l.cnote_customerID = @customerID
				${branchPredicate}
			`;

			const results_A = await dataconn.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( sql_A );

			// get total number of branches shopped
			const sql_B = `
				select count( distinct s.locationID ) as shopped
				from secretShopper.dbo.locations l
				join secretShopper.dbo.shops s on (s.locationID = l.locationID)
				where l.cnote_customerID = @customerID
				and dateShopped between @startDate and @endDate
				${branchPredicate};
			`;

			const results_B = await dataconn.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'startDate', sql.Date, dayjs( req.query.startDate ).startOf('day').toDate() )
				.input( 'endDate', sql.Date, dayjs( req.query.endDate ).startOf('day').toDate() )
				.query( sql_B );

			res.json({
				shopped: results_B.recordset[0].shopped,
				total: results_A.recordset[0].total
			});

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/bankersShopped', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		}

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/averageScoreByPeriod', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );
		// if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' )
		// if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' )

		const summarizeBy = req.query.summarizeBy ? req.query.summarizeBy : 'month';
		const branchPredicate = buildBranchPredicate( req.query.branch );
		let dateJoinPredicate, groupBy, formattedPeriod, dateFormat;

		switch ( summarizeBy ) {
			case 'day':

				dateFormat = 'M/D/YYYY';
				dateJoinPredicate = 'd.id = shops.id ';
				break;
			case 'week':
				dateFormat = 'M/D/YYYY';
				dateJoinPredicate = 'd.yearNo = datepart( year, shops.id ) and d.weekNo = datepart( week, shops.id ) and d.dayOfWeekNo = 1 ';
				break;
			case 'month':
				dateFormat = 'MMMM YYYY';
				dateJoinPredicate = 'd.yearNo = datepart( year, shops.id ) and d.monthNo = datepart( month, shops.id ) and d.dayOfMonth = 1 ';
				break;
			case 'quarter':
				dateFormat = 'M/D/YYYY';
				dateJoinPredicate = 'd.yearNo = datepart( year, shops.id ) and d.quarterNo = datepart( quarter, shops.id ) and d.dayOfQuarter = 1 ';
				break;
			default:
				console.error( 'Unexpected group by summarizeBy parameter' );
				logger.log({ level: 'error', label: 'GET:api/mysteryShopping/averageScoreByPeriod', message: 'Unexpected group by summarizeBy parameter' });
				throw new Error( 'Unexpected group by summarizeBy parameter' );
		}


		const locationPredicate = req.query.locationID ? `and l.locationID = ${req.query.locationID}` : '';


		// console.log({ summarizeBy, dateJoinPredicate, branchPredicate, locationPredicate })

		const cols = [
			{ id: "Date", label: "Date", type: "date" },
			{ id: "averageScore", label: "Average Score", type: "number" },
			// { role: "tooltip", type: "string", p: {html: true} },
			{ id: "naCount", label: "N/A Count", type: "number" },
			// { role: "tooltip", type: "string", 'p': {'html': true} },
		]
		var rows = []

		// let bankNames = await getBankNames( req.query.customerID )

		const SQL =	`
			select
				format( d.id, 'yyyy-MM-dd' ) as id,
				avg( shops.score ) / 100 as avgScore,
				sum( shops.passed ) as passed,
				sum( shops.didNotPass ) as didNotPass,
				sum( shops.naCount ) as naCount
			from (
				select
					d.id,
					case when ss.score <> 'N/A' then cast(replace( ss.score, '%', '' ) as NUMERIC(5,2)) else null end as score,
					case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) = 100 then 1 else null end else null end as passed,
					case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) < 100 then 1 else null end else null end as didNotPass,
					case when ss.score = 'N/A' then 1 else null end as naCount
				from dateDimension d
				left join (
					select s.dateShopped, s.score
					from secretShopper.dbo.shops s
					join secretShopper.dbo.locations l on (l.locationID = s.locationID)
					where l.cnote_customerID = @customerID
					${locationPredicate}
					${branchPredicate}
				) as ss on (ss.dateShopped = d.id)
			) as shops
			join dateDimension d on ( ${dateJoinPredicate} )
			group by d.id
			order by 1;
		`;


		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.query( SQL )

		}).then( result => {

			for ( row of result.recordset ) {

				let strYear 	= dayjs( row.id ).year();
				let strMonth 	= dayjs( row.id).month();
				let strDay		= dayjs( row.id ).date();
				let strDate		= `Date( ${strYear}, ${strMonth} , ${strDay} )`;
				let formattedPeriod = dayjs( row.id ).format( dateFormat );

				let score		= row.avgScore * 100 ? row.avgScore * 100 : null;
				let naCount 	= row.naCount ? row.naCount : null;

				let passed		= row.passed ? row.passed : '';
				let didNotPass	= row.didNotPass ? row.didNotPass : '';

				let formattedScore = row.avgScore ? parseFloat(score).toFixed(1)+'%' : null;

				let tooltip = `
					<table>
						<tr>
							<th>Period</th><td>' + formattedPeriod +'</td>
							<th>Avg Score</th><td>' + formattedScore  + '</td>
							<th>Passed</th><td>' + row.passed + '</td>
							<th>Not Passed</th>' + row.didNotPass + '</td>
							<th>N/A</th><td>' + naCount + '</td>
						</tr>
					</table>
				`;

				rows.push(
					{c: [
						{ v: strDate, f: formattedPeriod },
						{ v: score, f: formattedScore },
						// { v: tooltip },
						{ v: naCount },
						// { v: tooltip },
					]}
				);

			}

			res.json({ cols: cols, rows: rows });

		}).catch( err => {

			console.error( err );
			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/averageScoreByPeriod', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		});

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/byBranch', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' )
		if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' )
		if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' )
		if ( !req.query.format ) return res.status( 400 ).send( 'Parameter missing' )

		const branchPredicate = await buildBranchPredicate( req.query.branch )
		const bankNames = await getBankNames( req.query.customerID )

		let SQL	=	`select `
					+		`trim( grouperDistrict ) as branch, `
					+		`sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) = 100 then 1 else 0 end else 0 end ) as Ace, `
					+		`sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 90 and 99 then 1 else 0 end else 0 end ) as [A], `
					+		`sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 80 and 89 then 1 else 0 end else 0 end ) as [B], `
					+		`sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 70 and 79 then 1 else 0 end else 0 end ) as [C], `
					+		`sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) < 70 then 1 else 0 end else 0 end ) as [D], `
					+		`sum( case when score = 'N/A' then 1 else 0 end ) as NA, `
					+		`format( avg( case when score <> 'N/A' then cast(replace( score, '%', '' ) as NUMERIC(5,2)) end ) / 100, 'P1' ) as averageScore `
					+	`from secretShopper.dbo.locations l `
					+	`left join secretShopper.dbo.shops s on ( s.locationID = l.locationID and dateShopped between @startDate and @endDate ) `
					+	`where l.bankName in ( select trim( value ) from STRING_SPLIT( @bankNames, ',' ) ) `
					+	`${branchPredicate} `
					+	`group by grouperDistrict `
					+	`order by `
					+		`avg( case when score <> 'N/A' then cast(replace( score, '%', '' ) as NUMERIC(5,2)) end ) desc, `
					+		`grouperDistrict `

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'bankNames', bankNames )
				.input( 'startDate', sql.Date, dayjs( req.query.startDate ).startOf('day').toDate() )
				.input( 'endDate', sql.Date, dayjs( req.query.endDate ).startOf('day').toDate() )
				.query( SQL )

		}).then( result => {

			if ( req.query.format === 'chart' ) {

				const cols = [
					{id: "Branch", label: "Branch", type: "string"},
					{id: "N/A", label: "N/A", type: "number"},
					{id: "D", label: "D", type: "number"},
					{id: "C", label: "C", type: "number"},
					{id: "B", label: "B", type: "number"},
					{id: "A", label: "A", type: "number"},
					{id: "100", label: "100", type: "number"},
				]
				var rows = []

				for ( row of result.recordset ) {

					let branchFormatted = "Branch: " + row.branch

					rows.push(
						{c: [
							{ v: row.branch, f: branchFormatted },
							{ v: row.NA },
							{ v: row.D },
							{ v: row.C },
							{ v: row.B },
							{ v: row.A },
							{ v: row.Ace },
						]}
					)

				}

				res.json({ cols: cols, rows: rows })

			} else {

				res.json( result.recordset )

			}

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/byBranch', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/unsuccessfulShopsByBranch', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.format ) return res.status( 400 ).send( 'Parameter missing' );

		const branchPredicate = await buildBranchPredicate( req.query.branch );
		// const bankNames = await getBankNames( req.query.customerID )

		const SQL =	`
			select
				trim( cnote_city ) as branch,
				sum( case when score <> 'N/A'  then 1 else 0 end ) as Unsuccessful,
				sum( case when score = 'N/A' then 1 else 0 end ) as NA,
				count(*)
			from secretShopper.dbo.locations l
			left join secretShopper.dbo.shops s on ( s.locationID = l.locationID and dateShopped between @startDate and @endDate )
			where ( score = 'N/A' or cast(replace( score, '%', '' ) as NUMERIC(5,2)) < 100.00 )
			and l.cnote_customerID = @customerID
			${branchPredicate}
			group by cnote_city
			order by 4 desc;
		`;

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'startDate', sql.Date, dayjs( req.query.startDate ).startOf('day').toDate() )
				.input( 'endDate', sql.Date, dayjs( req.query.endDate ).startOf('day').toDate() )
				.query( SQL );

		}).then( result => {

			if ( req.query.format === 'chart' ) {

				const cols = [
					{ id: "Branch", label: "Branch", type: "string" },
					{ id: "Unsuccessful", label: "Unsuccessful - Not 100% (Excludes NA)", type: "number" },
					{ role: "tooltip", type: "string", p: {html: true} },
					{ id: "N/A", label: "N/A", type: "number" },
					{ role: "tooltip", type: "string", p: {html: true} },
				]
				var rows = []

				for ( row of result.recordset ) {

					let branchFormatted = "Branch: " + row.branch;
					let tooltip1 	= 	`
						<table>
							<tr><td><b>Branch: ${row.branch}</b></td></tr>
							<tr><td><b>Unsuccessful: ${row.Unsuccessful}</b></td></tr>
							<tr><td>Unsuccessful = Not 100% and not N/A</td></tr>
						</table>
					`;

					const tooltip2 = `
						<table>
							<tr><td><b>Branch: ${row.branch}</b></td></tr>
							<tr><td><b>N/A: ${row.NA}</b></td></tr>
							<tr><td>Unsuccessful = Not 100% and not N/A</td></tr>
						</table>
					`;

					rows.push(
						{c: [
							{ v: row.branch, f: branchFormatted },
							{ v: row.Unsuccessful },
							{ v: tooltip1 },
							{ v: row.NA },
							{ v: tooltip2 }
						]}
					);

				}

				res.json({ cols: cols, rows: rows });

			} else {

				res.json( result.recordset );

			}

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/unsuccessfulShopsByBranch', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		});

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/unsuccessfulShopsBySupervisor', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.format ) return res.status( 400 ).send( 'Parameter missing' );

		const branchPredicate = await buildBranchPredicate( req.query.branch );
		// const bankNames = await getBankNames( req.query.customerID )

		const SQL =	`
			select
				trim( grouperArea ) as supervisor,
				sum( case when score <> 'N/A'  then 1 else 0 end ) as Unsuccessful,
				sum( case when score = 'N/A' then 1 else 0 end ) as NA,
				count(*)
			from secretShopper.dbo.locations l
			left join secretShopper.dbo.shops s on ( s.locationID = l.locationID and dateShopped between @startDate and @endDate )
			where ( score = 'N/A' or cast(replace( score, '%', '' ) as NUMERIC(5,2)) < 100.00 )
			and l.cnote_customerID = @customerID
			${branchPredicate}
			group by grouperArea
			order by 4 desc;
		`;

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'startDate', sql.Date, dayjs( req.query.startDate ).startOf('day').toDate() )
				.input( 'endDate', sql.Date, dayjs( req.query.endDate ).startOf('day').toDate() )
				.query( SQL );

		}).then( result => {

			if ( req.query.format === 'chart' ) {

				const cols = [
					{ id: "Supervisor", label: "Supervisor", type: "string" },
					{ id: "Unsuccessful", label: "Unsuccessful - Not 100% (Excludes NA)", type: "number" },
					{ role: "tooltip", type: "string", p: {html: true} },
					{ id: "N/A", label: "N/A", type: "number" },
					{ role: "tooltip", type: "string", p: {html: true} },
				]
				var rows = []

				for ( row of result.recordset ) {

					let supervisor = row.supervisor == null ? 'None' : row.supervisor;

					let tooltip1 	= 	`
						<table>
							<tr><td><b>Supervisor: ${supervisor}</b></td></tr>
							<tr><td><b>Unsuccessful: ${row.Unsuccessful}</b></td></tr>
							<tr><td>Unsuccessful = Not 100% and not N/A</td></tr>
						</table>
					`;

					let tooltip2 	= 	`
						<table>
							<tr><td><b>Supervisor: ${supervisor}</b></td></tr>
							<tr><td><b>N/A: ${row.NA}</b></td></tr>
							<tr><td>N/A = Bank Not Available after 3 attempts/td></tr>
						</table>
					`;


					rows.push(
						{c: [
							{ v: supervisor },
							{ v: row.Unsuccessful },
							{ v: tooltip1 },
							{ v: row.NA },
							{ v: tooltip2 }
						]}
					);

				}

				res.json({ cols: cols, rows: rows });

			} else {

				res.json( result.recordset );

			}

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/unsuccessfulShopsBySupervisor', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		});

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/bySupervisor', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.format ) return res.status( 400 ).send( 'Parameter missing' );

		const branchPredicate = await buildBranchPredicate( req.query.branch );
		// const bankNames = await getBankNames( req.query.customerID )

			const SQL =	`
				select
					trim( grouperDistrict ) as branch,
					trim( grouperArea ) as supervisor,
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) = 100 then 1 else 0 end else 0 end ) as Ace,
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 90 and 99 then 1 else 0 end else 0 end ) as [A],
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 80 and 89 then 1 else 0 end else 0 end ) as [B],
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 70 and 79 then 1 else 0 end else 0 end ) as [C],
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) < 70 then 1 else 0 end else 0 end ) as [D],
					sum( case when score = 'N/A' then 1 else 0 end ) as NA,
					format( avg( case when score <> 'N/A' then cast(replace( score, '%', '' ) as NUMERIC(5,2)) end ) / 100, 'P1' ) as averageScore
				from secretShopper.dbo.locations l
				join secretShopper.dbo.shops s on ( s.locationID = l.locationID )
				where l.customerID = @customerID
				and dateShopped between @startDate and @endDate
				${branchPredicate}
				group by grouperDistrict, grouperArea
				order by
					avg( case when score <> 'N/A' then cast(replace( score, '%', '' ) as NUMERIC(5,2)) end ) desc,
					grouperDistrict,
					grouperArea;
			`;


		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'startDate', sql.Date, dayjs( req.query.startDate ).startOf('day').toDate() )
				.input( 'endDate', sql.Date, dayjs( req.query.endDate ).startOf('day').toDate() )
				.query( SQL );

		}).then( result => {

			if ( req.query.format === 'chart' ) {

				const cols = [
					{id: "Supervisor", label: "Supervisor", type: "string"},
					{id: "N/A", label: "N/A", type: "number"},
					{id: "D", label: "D", type: "number"},
					{id: "C", label: "C", type: "number"},
					{id: "B", label: "B", type: "number"},
					{id: "A", label: "A", type: "number"},
					{id: "100", label: "100", type: "number"},
				]
				var rows = []

				for ( row of result.recordset ) {

					let scoreFormatted = parseFloat(row.averageScore).toFixed(1)+'%';

					let supervisor = `${row.branch}/${row.supervisor}`;
					let supervisorFormatted = `Supervisor: ${row.branch} / ${row.supervisor}`;

					rows.push(
						{c: [
							{ v: supervisor, f: supervisorFormatted },
							{ v: row.NA },
							{ v: row.D },
							{ v: row.C },
							{ v: row.B },
							{ v: row.A },
							{ v: row.Ace },
						]}
					);

				}

				res.json({ cols: cols, rows: rows });

			} else {

				res.json( result.recordset );

			}

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/bySupervisor', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		});

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/gradePie', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' );

		const branchPredicate = await buildBranchPredicate( req.query.branch );
		// const bankNames = await getBankNames( req.query.customerID )

		const cols = [
			{id: "grade", label: "Grade", type: "string"},
			{id: "count", label: "Count", type: "number"}
		]
		var rows = []

		const SQL =	`
			select
				sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) = 100 then 1 else 0 end else 0 end ) as Ace,
				sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 90 and 99 then 1 else 0 end else 0 end ) as [A],
				sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 80 and 89 then 1 else 0 end else 0 end ) as [B],
				sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 70 and 79 then 1 else 0 end else 0 end ) as [C],
				sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) < 70 then 1 else 0 end else 0 end ) as [D],
				sum( case when score = 'N/A' then 1 else 0 end ) as NA
			from secretShopper.dbo.locations l
			join secretShopper.dbo.shops s on ( s.locationID = l.locationID )
			where l.cnote_customerID = @customerID
			and s.dateShopped between @startDate and @endDate
			${branchPredicate};
		`;

		sql.connect( dbConfig ).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'startDate', sql.Date, dayjs( req.query.startDate ).startOf('day').toDate() )
				.input( 'endDate', sql.Date, dayjs( req.query.endDate ).startOf('day').toDate() )
				.query( SQL );

		}).then( result => {

			rows.push({ c: [
				{ v: '100', f: '100' },
				{ v: result.recordset[0].Ace }
			]});

			rows.push({ c: [
				{ v: 'A', },
				{ v: result.recordset[0].A }
			]});

			rows.push({ c: [
				{ v: 'B', },
				{ v: result.recordset[0].B }
			]});

			rows.push({ c: [
				{ v: 'C' },
				{ v: result.recordset[0].C }
			]});

			rows.push({ c: [
				{ v: 'D' },
				{ v: result.recordset[0].D }
			]});

			rows.push({ c: [
				{ v: 'N/A' },
				{ v: result.recordset[0].NA }
			]});


			res.json({ cols: cols, rows: rows });

		}).catch( err => {

			console.error( err );
			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/gradePie', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		});

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/shopsByLocation/:locationID', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.params.locationID ) return res.status( 400 ).send( 'Parameter missing' )

			const SQL =	`
				select
					s.shopID,
					format( s.dateShopped, 'yyyy-MM-dd' ) as dateShopped,
					s.score,
					trim( s.scorePoints ) as scorePoints,
					f.name as formName
				from secretShopper.dbo.shops s
				join secretShopper.dbo.forms f on (f.formUniqueID = s.formUniqueID)
				where s.locationID = @locationID
				order by dateShopped desc;
			`;

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'locationID', sql.VarChar, req.params.locationID )
				.query( SQL );

		}).then( results => {

			res.json( results.recordset );

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/shops/:locationID', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		});

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/locationsByCustomer', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );

		// let bankNames = await getBankNames( req.query.customerID )

			const SQL =	`
				select
					l.locationID,
					l.bankerName,
					l.bankerTitle,
					trim( l.address ) as address,
					trim( l.city ) as city,
					stateAbbreviation,
					trim( l.zipCode ) as zipCode,
					trim( l.phoneNumber ) as phoneNumber,
					trim( l.grouperDistrict ) as branch,
					trim( l.grouperArea ) as supervisor,
					s.timesShopped,
					s.lastDateShopped
				from secretShopper.dbo.locations l
				left join (
					select
						locationID,
						count(*) as timesShopped,
						format( max(dateShopped), 'yyyy-MM-dd' ) as lastDateShopped
					from secretShopper.dbo.shops
					group by locationID
				) s on s.locationID = l.locationID
				where l.cnote_customerID = @customerID
				order by s.lastDateShopped desc
			`;


		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'cnote_customerID', sql.VarChar, req.query.customerID )
				.query( SQL )

		}).then( results => {

			res.json( results.recordset );

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/locations/:locationID', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		});

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/locations/:locationID', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.params.locationID ) return res.status( 400 ).send( 'Parameter missing' );

		const SQL =	`
			select *
			from secretShopper.dbo.locations l
			where l.locationID = @locationID
		`;

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'locationID', sql.VarChar, req.params.locationID )
				.query( SQL );

		}).then( results => {

			res.json( results.recordset[0] );

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/locations/:locationID', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		});

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/shops/:shopID', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.params.shopID ) return res.status( 400 ).send( 'Parameter missing' )

		const SQL =	`
			select *
			from secretShopper.dbo.shops s
			where s.shopID = @shopID;
		`;

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'shopID', sql.VarChar, req.params.shopID )
				.query( SQL );

		}).then( results => {

			res.json( results.recordset[0] );

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/shops/:shopID', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		});

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/naBySupervisor', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' );
		if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' );

		const cols = [
			{id: "Supervisor", label: "Supervisor", type: "string"},
			{id: "Count", label: "Count", type: "number"}
		]
		var rows = []

		// let bankNames = await getBankNames( req.query.customerID )

		const SQL =	`
			select
				trim( grouperArea ) as supervisor,
				count(*) as count
			from secretShopper.dbo.locations l
			join secretShopper.dbo.shops s on ( s.locationID = l.locationID )
			where l.cnote_customerID = @customerID
			and dateShopped between @startDate and @endDate
			and ( s.score = 'N/A' )
			group by trim( grouperArea )
			order by 2 desc;
		`;

		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'startDate', sql.Date, dayjs( req.query.startDate ).startOf('day').toDate() )
				.input( 'endDate', sql.Date, dayjs( req.query.endDate ).startOf('day').toDate() )
				.query( SQL );

		}).then( result => {

			for ( row of result.recordset ) {

				let supervisor = row.supervisor ? row.supervisor : 'Unknown';
				count	= row.count;

				rows.push(
					{c: [
						{ v: supervisor },
						{ v: count }
					]}
				);

			}

			res.json({ cols: cols, rows: rows });

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/naBySupervisor', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		});

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/naByBanker', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' )
		if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' )
		if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' )

		const cols = [
			{id: "Banker", label: "Banker", type: "string"},
			{id: "Count", label: "Count", type: "number"}
		]
		var rows = []

		let bankNames = await getBankNames( req.query.customerID )

		sql.connect(dbConfig).then( pool => {

			let SQL	=	"select "
						+		"bankerName, "
						+		"count(*) as count "
						+	"from secretShopper.dbo.locations l "
						+	"join secretShopper.dbo.shops s on ( s.locationID = l.locationID ) "
						+	"where l.bankName in ( select trim( value ) from STRING_SPLIT( @bankNames, ',' ) ) "
						+	"and dateShopped between @startDate and @endDate "
						+	"and ( s.score = 'N/A' ) "
						+	"group by "
						+		"bankerName "
						+	"order by 2 desc "

			return pool.request()
				.input( 'bankNames', bankNames )
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

		}).then( result => {

			for ( row of result.recordset ) {

				let bankerName = row.bankerName ? row.bankerName : 'Unknown'
				count	= row.count

				rows.push(
					{c: [
						{ v: bankerName },
						{ v: count }
					]}
				)

			}

			res.json({ cols: cols, rows: rows })

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/naBySupervisor', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/naByBranch', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' )
		if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' )
		if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' )

		const cols = [
			{id: "Banker", label: "Banker", type: "string"},
			{id: "Count", label: "Count", type: "number"}
		]
		var rows = []

		let bankNames = await getBankNames( req.query.customerID )

		sql.connect(dbConfig).then( pool => {

			let SQL	=	"select "
						+		"trim( grouperDistrict ) as branch, "
						+		"count(*) as count "
						+	"from secretShopper.dbo.locations l "
						+	"join secretShopper.dbo.shops s on ( s.locationID = l.locationID ) "
						+	"where l.bankName in ( select trim( value ) from STRING_SPLIT( @bankNames, ',' ) ) "
						+	"and dateShopped between @startDate and @endDate "
						+	"and ( s.score = 'N/A' ) "
						+	"group by "
						+		"trim( grouperDistrict ) "
						+	"order by 2 desc "

			return pool.request()
				.input( 'bankNames', bankNames )
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

		}).then( result => {

			for ( row of result.recordset ) {

				let branch = row.branch ? row.branch : 'Unknown'
				count	= row.count

				rows.push(
					{c: [
						{ v: branch },
						{ v: count }
					]}
				)

			}

			res.json({ cols: cols, rows: rows })

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/naBySupervisor', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/totalShops', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' )
		if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' )
		if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' )

		let bankNames = await getBankNames( req.query.customerID )

		sql.connect(dbConfig).then( pool => {

			let SQL	=	"select "
						+		"count( distinct s.shopID ) as shopsCount "
						+	"from secretShopper.dbo.locations l "
						+	"join secretShopper.dbo.shops s on ( s.locationID = l.locationID ) "
						+	"where l.bankName in ( select trim( value ) from STRING_SPLIT( @bankNames, ',' ) ) "
						+	"and dateShopped between @startDate and @endDate "

			return pool.request()
				.input( 'bankNames', bankNames )
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

		}).then( result => {

			res.json( result.recordset[0] )

		}).catch( err => {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/totalShops', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/branches', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );
			if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' );
			if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' );

			// let bankNames = await getBankNames( req.query.customerID )

			const dataconn	= await sql.connect( dbConfig );

			// get the total number of branches for the bank
			// NOTE: count(distinct grouperDistrict) wont work because sometimes grouperDistrict is null
			const SQL = `
				select
					trim( l.cnote_city ) as branch,
					count( l.locationID ) as totalBankers,
					count( l.grouperArea ) as totalSupervisors,
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) = 100 then 1 else 0 end else 0 end ) as Ace,
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 90 and 99 then 1 else 0 end else 0 end ) as [A],
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 80 and 89 then 1 else 0 end else 0 end ) as [B],
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 70 and 79 then 1 else 0 end else 0 end ) as [C],
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) < 70 then 1 else 0 end else 0 end ) as [D],
					sum( case when score = 'N/A' then 1 else 0 end ) as NA,
					count(distinct s.shopID) as totalShops,
					format( avg( case when score = 'N/A' then null else cast(replace( score, '%', '' ) as NUMERIC(5,2))/100 end ), 'P1' ) as averageScore,
					DATEDIFF(day, max(dateShopped), getdate() ) as daysSinceLastShop
				from secretShopper.dbo.locations l
				left join secretShopper.dbo.shops s on (s.locationID = l.locationID and s.dateShopped between @startDate and @endDate )
				where l.cnote_customerID = @customerID
				group by l.cnote_city
				order by l.cnote_city;
			`;

			let results = await dataconn.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL );

			res.json( results.recordset );

		} catch( err ) {

			console.error( err );
			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/branches', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		}

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/supervisors', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );
			if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' );
			if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' );

			// let bankNames = await getBankNames( req.query.customerID )

			let branchPredicate = supervisorPredicate = ''
			if ( req.query.branch ) {
				if ( req.query.branch === 'null' ) {
					branchPredicate = `and l.grouperDistrict is null`;
				} else {
					branchPredicate = `and l.grouperDistrict = '${req.query.branch}'`;
				}
			} else {
				branchPredicate = '';
			}


			const dataconn	= await sql.connect( dbConfig );

			// get the total number of branches for the bank
			// NOTE: count(distinct grouperDistrict) wont work because sometimes grouperDistrict is null
			const SQL = `
				select
					trim( l.cnote_city ) as branch,
					trim( l.grouperArea ) as supervisor,
					count( l.grouperDistrict ) as totalBranches,
					count( l.locationID) as totalBankers,
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) = 100 then 1 else 0 end else 0 end ) as Ace,
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 90 and 99 then 1 else 0 end else 0 end ) as [A],
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 80 and 89 then 1 else 0 end else 0 end ) as [B],
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 70 and 79 then 1 else 0 end else 0 end ) as [C],
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) < 70 then 1 else 0 end else 0 end ) as [D],
					sum( case when score = 'N/A' then 1 else 0 end ) as NA,
					count(distinct s.shopID) as totalShops,
					format( avg( case when score = 'N/A' then null else cast(replace( score, '%', '' ) as NUMERIC(5,2))/100 end ), 'P1' ) as averageScore,
					DATEDIFF(day, max(dateShopped), getdate() ) as daysSinceLastShop
				from secretShopper.dbo.locations l
				left join secretShopper.dbo.shops s on (s.locationID = l.locationID and s.dateShopped between @startDate and @endDate )
				where l.cnote_customerID = @customerID
				${ branchPredicate }
				group by l.cnote_city, l.grouperArea
				order by l.cnote_city, l.grouperArea;
			`;

			let results = await dataconn.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL );

			res.json( results.recordset );

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/supervisors', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		}

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/bankers', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );
			if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' );
			if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' );

			// let bankNames = await getBankNames( req.query.customerID )

			let branchPredicate = supervisorPredicate = '';
			if ( req.query.branch ) {
				if ( req.query.branch === 'null' ) {
					branchPredicate = `and l.grouperDistrict is null`;
				} else {
					branchPredicate = `and l.grouperDistrict = '${req.query.branch}'`;
				}
			} else {
				branchPredicate = '';
			}

			if ( req.query.supervisor ) {
				if ( req.query.supervisor === 'null' ) {
					supervisorPredicate = `and l.grouperArea is null`;
				} else {
					supervisorPredicate = `and l.grouperArea = '${req.query.supervisor}'`;
				}
			} else {
				supervisorPredicate = '';
			}

			switch ( req.query.grade ) {
				case '100':
					gradePredicate = `and ( score <> 'N/A' and cast(replace( score, '%', '' ) as NUMERIC(5,2)) >= 100.0 )`;
					break
				case 'A':
					gradePredicate = `and ( score <> 'N/A' and cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 90.0 and 99.9`;
					break
				case 'B':
					gradePredicate = `and ( score <> 'N/A' and cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 80.0 and 89.9`;
					break
				case 'C':
					gradePredicate = `and ( score <> 'N/A' and cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 70.0 and 79.9`;
					break
				case 'D':
					gradePredicate = `and ( score <> 'N/A' and cast(replace( score, '%', '' ) as NUMERIC(5,2)) < 70.0`;
					break
				case 'N/A':
					gradePredicate = `and score = 'N/A'`;
					break
				default:
					gradePredicate = '';
			}

			const dataconn	= await sql.connect( dbConfig );

			// get the total number of branches for the bank
			// NOTE: count(distinct grouperDistrict) wont work because sometimes grouperDistrict is null
			const SQL = `
				select
					l.locationID,
					l.cnote_bankerName as bankerName,
					l.cnote_bankerTitle as bankerTitle,
					l.phoneNumber,
					trim( max(l.cnote_city) ) as branch,
					trim( max(l.grouperArea) ) as supervisor,
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) = 100 then 1 else 0 end else 0 end ) as Ace,
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 90 and 99 then 1 else 0 end else 0 end ) as [A],
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 80 and 89 then 1 else 0 end else 0 end ) as [B],
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) between 70 and 79 then 1 else 0 end else 0 end ) as [C],
					sum( case when score <> 'N/A' then case when cast(replace( score, '%', '' ) as NUMERIC(5,2)) < 70 then 1 else 0 end else 0 end ) as [D],
					sum( case when score = 'N/A' then 1 else 0 end ) as NA,
					format( avg( case when score = 'N/A' then null else cast(replace( score, '%', '' ) as NUMERIC(5,2))/100 end ), 'P1' ) as averageScore,
					count(distinct s.shopID) as totalShops,
					DATEDIFF(day, max(dateShopped), getdate() ) as daysSinceLastShop
				from secretShopper.dbo.locations l
				join secretShopper.dbo.shops s on (s.locationID = l.locationID and s.dateShopped between @startDate and @endDate )
				where l.cnote_customerID = @customerID
				${ branchPredicate }
				${ supervisorPredicate }
				${ gradePredicate }
				group by l.locationID, l.cnote_bankerName, l.cnote_bankerTitle, l.phoneNumber
				order by l.cnote_bankerName;
			`;

			// console.log({ startDate: req.query.startDate, endDate: req.query.endDate })
			// console.log({ branchPredicate })
			// console.log({ supervisorPredicate })
			// console.log({ gradePredicate })
			// console.log( SQL )


			let results = await dataconn.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL );

			res.json( results.recordset );

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/bankers', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		}

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/shops', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' );
			if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' );
			if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' );

			// let bankNames = await getBankNames( req.query.customerID )

			const dataconn	= await sql.connect( dbConfig );

			const SQL =	`
				select
					s.shopID,
					l.locationID,
					l.cnote_bankerName as bankerName,
					trim( l.cnote_bankerTitle) as bankerTitle,
					trim( l.grouperArea) as supervisor,
					trim( l.cnote_city ) as branch,
					format( s.dateShopped, 'yyyy-MM-dd' ) as dateShopped,
					trim( s.score ) as score,
					trim( s.scorePoints ) as scorePoints
				from secretShopper.dbo.locations l
				join secretShopper.dbo.shops s on (s.locationID = l.locationID and s.dateShopped between @startDate and @endDate )
				where l.cnote_customerID = @customerID
				order by l.cnote_bankerName;
			`;


			let results = await dataconn.request()
				.input( 'customerID', sql.BigInt, req.query.customerID )
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL );

			res.json( results.recordset );

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/bankers', message: err, user: req.session.userID });
			res.sendStatus( 500 );

		}

	});
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/bankersWithOnlyNaShops', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' )
			if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' )
			if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' )

			const branchPredicate = buildBranchPredicate( req.query.branch )
			const bankNames = await getBankNames( req.query.customerID )

			const dataconn	= await sql.connect( dbConfig )

			let SQL 	= 	`select l.bankName, l.bankerName, count(*) `
						+	`from secretShopper.dbo.locations l `
						+	`join secretShopper.dbo.shops s on (s.locationID = l.locationID) `
						+	`where l.bankName in ( select trim( value ) from STRING_SPLIT( @bankNames, ',' ) ) `
						+	`where exists ( `
						+		`select * `
						+		`from secretShopper.dbo.shops s `
						+		`where s.locationID = l.locationID `
						+		`and dateShopped between @startDate and @endDate `
						+		`and s.score = 'N/A' `
						+	`) `
						+	`and not exists ( `
						+		`select * `
						+		`from secretShopper.dbo.shops s `
						+		`where s.locationID = l.locationID `
						+		`and dateShopped between @startDate and @endDate `
						+		`and (s.score <> 'N/A' or s.score is null) `
						+	`) `
						+	`group by l.bankName, l.bankerName `
						+	`order by 3 desc `


			let results = await dataconn.request()
				.input( 'bankNames', bankNames )
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

			res.json({
				naShops: results.recordset[0].totalNaShops,
				totalShops: results.recordset[0].totalShops
			})

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/totalNaShops', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		}

	})
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/riskByShops', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' )
			if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' )
			if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' )

			let bankNames = await getBankNames( req.query.customerID )

			const dataconn	= await sql.connect( dbConfig )

			const cols = [
				{id: "risk", label: "Risk", type: "string"},
				{id: "count", label: "Count", type: "number"}
			]
			var rows = []

			let SQL 	=	`select risk, count(*) as riskCount from ( `
						+		`select `
						+			`l.locationID, `
						+			`s.score, `
						+			`case when trim( s.score ) = 'N/A' then `
						+				`'3-High' `
						+			`else `
						+				`case when cast( trim( replace( s.score, '%', '' ) ) as decimal( 5,2 ) ) >= 90 then `
						+					`'1-Low' `
						+				`else `
						+					`case when cast( trim( replace( s.score, '%', '' ) ) as decimal( 5,2 ) ) >=80 and cast( trim( replace( s.score, '%', '' ) ) as decimal( 5,2 ) ) < 90 then `
						+						`'2-Medium' `
						+					`else `
						+						`'3-High' `
						+					`end `
						+				`end `
						+			`end as 'Risk' `
						+		`from secretShopper.dbo.shops s `
						+		`join secretShopper.dbo.locations l on (l.locationID = s.locationID) `
						+		`where l.bankName in ( select trim( value ) from STRING_SPLIT( @bankNames, ',' ) ) `
						+		`and s.dateShopped between @startDate and @endDate `
						+		`and s.score <> 'N/A' `
						+	`) as x `
						+	`group by risk `
						+	`order by 1 desc `


			let results = await dataconn.request()
				.input( 'bankNames', bankNames )
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

			debugger
			for ( row of results.recordset ) {

				rows.push({ c: [
					{ v: row.risk },
					{ v: row.riskCount }
				]})

			}

			res.json({ cols: cols, rows: rows })

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/bankers', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		}

	})
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/scoreByHierarchy', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' )
			if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' )
			if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' )

			let bankNames = await getBankNames( req.query.customerID )

			const dataconn	= await sql.connect( dbConfig )

			const cols = [
				{id: "id", label: "ID", type: "string"},
				{id: "parent", label: "Parent", type: "string"},
				{id: "score", label: "Score", type: "number"}
			]
			var rows = []

			let SQL 	=	`select distinct `
						+		`case when bankName is null then 'Undefined' else trim( bankName ) end as id, `
						+		`null as parent, `
						+		`0 as score `
						+	`from secretShopper.dbo.locations l `
						+	`join secretShopper.dbo.shops s on (s.locationID = l.locationID) `
						+	`where l.bankName in ( select trim( value ) from STRING_SPLIT( @bankNames, ',' ) ) `
						+	`and s.dateShopped between @startDate and @endDate `
						+	`and s.score <> 'N/A' `
						+	`UNION ALL `
						+	`select distinct `
						+		`case when grouperDistrict is null then 'Undefined' else trim( grouperDistrict ) end as id, `
						+		`case when bankName is null then 'Undefined' else trim( bankName ) end as parent, `
						+		`null as score `
						+	`from secretShopper.dbo.locations l `
						+	`join secretShopper.dbo.shops s on (s.locationID = l.locationID) `
						+	`where l.bankName in ( select trim( value ) from STRING_SPLIT( @bankNames, ',' ) ) `
						+	`and s.dateShopped between @startDate and @endDate `
						+	`and s.score <> 'N/A' `
						+	`UNION ALL `
						+	`select `
						+		`trim( bankerName ) as id, `
						+		`case when grouperArea is null then 'Undefined' else grouperArea end as parent, `
						+		`case when trim( s.score ) = 'N/A' then `
						+			`0.00 `
						+		`else `
						+			`cast( trim( replace( trim( s.score ), '%', '' ) ) as decimal(5,2) ) `
						+		`end as score `
						+	`from secretShopper.dbo.locations l `
						+	`join secretShopper.dbo.shops s on (s.locationID = l.locationID) `
						+	`where l.bankName in ( select trim( value ) from STRING_SPLIT( @bankNames, ',' ) ) `
						+	`and s.dateShopped between @startDate and @endDate `
						+	`and s.score <> 'N/A' `


			let results = await dataconn.request()
				.input( 'bankNames', bankNames )
				.input( 'startDate', sql.Date, req.query.startDate )
				.input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

			debugger
			for ( row of results.recordset ) {

				rows.push({ c: [
					{ v: row.id },
					{ v: row.parent },
					{ v: row.score },
				]})

			}

			res.json({ cols: cols, rows: rows })

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/bankers', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		}

	})
	//====================================================================================


	//====================================================================================
	https.get( '/api/mysteryShopping/riskByMonth', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' )
		if ( !req.query.startDate ) return res.status( 400 ).send( 'Parameter missing' )
		if ( !req.query.endDate ) return res.status( 400 ).send( 'Parameter missing' )

		const summarizeBy = req.query.summarizeBy ? req.query.summarizeBy : 'month'
		const branchPredicate = buildBranchPredicate( req.query.branch )
		let groupBy, formattedPeriod, dateFormat

		let locationPredicate = req.query.locationID ? `and l.locationID = ${req.query.locationID}` : ''


		// console.log({ summarizeBy, dateJoinPredicate, branchPredicate, locationPredicate })

		const cols = [
			{ id: "Date", label: "Date", type: "date" },
			{ id: "lowRisk", label: "Low Risk", type: "number" },
			{ id: "mediumRisk", label: "Medium Risk", type: "number" },
			{ id: "highRisk", label: "High Risk", type: "number" },
		]
		var rows = []

		let bankNames = await getBankNames( req.query.customerID )

		let SQL	=	`select period, [High], [Medium], [Low] `
					+	`from ( `
					+		`select `
					+			`datefromparts( d.yearNo, d.monthNo, 1) as period, `
					+			`case when cast( trim( replace( s.score, '%', '' ) ) as decimal( 5,2 ) ) >= 90 then `
					+				`'Low' `
					+			`else `
					+				`case when cast( trim( replace( s.score, '%', '' ) ) as decimal( 5,2 ) ) >=80 then `
					+					`'Medium' `
					+				`else `
					+					`'High' `
					+				`end `
					+			`end as risk `
					+		`from dateDimension d `
					+		`join secretShopper.dbo.shops s on (s.dateShopped = d.id) `
					+		`join secretShopper.dbo.locations l on (l.locationID = s.locationID) `
					+		`where l.bankName in ( select trim( value ) from STRING_SPLIT( 'BANK OF GUAM', ',' ) ) `
					+		`and s.score <> 'N/A' `
					+	`) as x `
					+	`PIVOT ( `
					+		`count(risk) `
					+		`for risk in ( [High], [Medium] , [Low] ) `
					+	`) as y `


		sql.connect(dbConfig).then( pool => {

			return pool.request()
				.input( 'bankNames', bankNames )
				// .input( 'startDate', sql.Date, dayjs( req.query.startDate ).format( 'M/D/YYYY' ) )
				// .input( 'endDate', sql.Date, req.query.endDate )
				.query( SQL )

		}).then( result => {

			for ( row of result.recordset ) {

				let strYear 	= dayjs( row.period ).year()
				let strMonth 	= dayjs( row.period).month()
				let strDay		= dayjs( row.period ).date()
				let strDate		= `Date( ${strYear}, ${strMonth} , ${strDay} )`
				let formattedPeriod = dayjs( row.id ).format( dateFormat )

				rows.push(
					{c: [
						{ v: strDate, f: formattedPeriod },
						{ v: row.High  },
						{ v: row.Medium },
						{ v: row.Low },
					]}
				)

			}

			res.json({ cols: cols, rows: rows })

		}).catch( err => {

			console.error( err )
			logger.log({ level: 'error', label: 'GET:api/mysteryShopping/averageScoreByPeriod', message: err, user: req.session.userID })
			res.sendStatus( 500 )

		})

	})
	//====================================================================================


	//====================================================================================
	https.get('/api/mysteryShopping/locations', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			const dataconn	= await sql.connect( dbConfig )

			const SQL = `
				SELECT
					id,
					LTRIM( RTRIM( name ) ) as name,
					cnote_bankName,
					cnote_bankerTitle,
					cnote_bankerName,
					LTRIM( RTRIM( cnote_city ) ) as cnote_city,
					cnote_customerID
				FROM secretShopper.dbo.locations
				WHERE cnote_active = 1
				ORDER BY name;
			`;

			const results = await dataconn.request().query( SQL );

			return res.json( results.recordset );

		} catch( err ) {
			logger.log({ level: 'error', label: 'api/mysteryShopping/locations', message: err, user: req.session.userID })
			return res.status( 500 ).send( 'Unexpected error' )
		}


	})
	//====================================================================================


	//====================================================================================
	https.put( '/api/mysteryShopping/locations', utilities.jwtVerify, async ( req, res ) => {
	//====================================================================================

		try {

			if ( req.body.locationID === undefined || req.body.locationID === null ) {
				return res.status( 400 ).send( 'locationID parameter missing' );
			}

			// IMPORTANT: allow clearing mapping (customerID can be '' or null)
			// If you never want to allow clearing, keep your old check.
			if ( req.body.cnote_customerID === undefined ) {
				return res.status( 400 ).send( 'customerID parameter missing' );
			}

			const locationID = Number( req.body.locationID );
			const customerID = ( req.body.cnote_customerID === '' || req.body.cnote_customerID === null )
				? null
				:Number( req.body.cnote_customerID );

			const applyToAllForBank = req.body.applyToAllForBank === true;
			const bankName = ( req.body.cnote_bankName ?? '' ).trim();

			if ( applyToAllForBank && !bankName ) {
				return res.status( 400 ).send( 'cnote_bankName parameter missing (required when applyToAllForBank is true)' );
			}

			const dataconn = await sql.connect( dbConfig );

			let SQL = '';
			const request = dataconn.request()
				.input( 'customerID', sql.BigInt, customerID )
				.input( 'userID', sql.BigInt, req.session.userID );

			if ( applyToAllForBank ) {

				SQL = `
					UPDATE secretShopper.dbo.locations SET
						cnote_customerID = @customerID,
						cnote_updatedDateTime = CURRENT_TIMESTAMP,
						cnote_updatedBy = @userID
					WHERE cnote_bankName = @bankName;
				`;

				request.input( 'bankName', sql.NVarChar( 255 ), bankName );

			} else {

				SQL = `
					UPDATE secretShopper.dbo.locations SET
						cnote_customerID = @customerID,
						cnote_updatedDateTime = CURRENT_TIMESTAMP,
						cnote_updatedBy = @userID
					WHERE id = @locationID;
				`;

				request.input( 'locationID', sql.BigInt, locationID );

			}

			const results = await request.query( SQL );

			if ( results.rowsAffected[ 0 ] === 0 ) {
				return res.status( 404 ).send( 'No record updated — check locationID/bankName' );
			}

			return res.json({
				success: true,
				updatedCount: results.rowsAffected[ 0 ],
				applyToAllForBank: applyToAllForBank,
				bankName: applyToAllForBank ? bankName : null,
			});

		} catch ( err ) {

			logger.log({ level: 'error', label: 'PUT:api/mysteryShopping/locations', message: err, user: req.session.userID });
			return res.status( 500 ).send( 'Unexpected error' );

		}

	});
	//====================================================================================


	//====================================================================================
	async function getAllBankNamesByStatus( statusList ) {
	//====================================================================================

		try {

			const dataconn	= await sql.connect( dbConfig )

			let SQL 	= 	`select `
						+		`secretShopperLocationName `
						+	`from customer `
						+	`where customerStatusID in ( select value from STRING_SPLIT( @statusList, ',' ) ) `

			let results = await dataconn.request()
				.input( 'statusList', statusList )
				.query( SQL )

			let bankNamesArray = []

			for ( bankNames of results.recordset ) {
				if ( bankNames.secretShopperLocationName ) {
					let sublist = bankNames.secretShopperLocationName.split( ',' )
					for ( item of sublist ) {
						if( item ) bankNamesArray.push( item.trim() )
					}
				}
			}
			// console.log( `bankNamesArray.lengh: ${bankNamesArray.length}` )

			return bankNamesArray

		} catch( err ) {

			logger.error({ level: 'error', label: 'mysteryShopping/getAllBankNamesByStatus', message: err })
			console.error( err )
			throw new Error( err )

		}

	}
	//====================================================================================


	//====================================================================================
	async function getBankNames( customerID ) {
	//====================================================================================

		try {

			const dataconn	= await sql.connect( dbConfig )

			let SQL = await `select secretShopperLocationName from customer where id = ${customerID} `
			let results = await dataconn.request().query( SQL )

			return results.recordset[0].secretShopperLocationName

		} catch( err ) {

			logger.error({ level: 'error', label: 'mysteryShopping/getBankNames', message: err })
			console.error( err )
			throw new Error( err )

		}

	}
	//====================================================================================


	//====================================================================================
	function buildBranchPredicate( branch ) {
	//====================================================================================

		let predicate = ''

		if ( branch ) {

			if ( branch === 'all' ) {

				predicate = ``

			} else {

				if ( branch === 'null' ) {
					predicate = `and l.cnote_city is null`
				} else {
					predicate = `and trim( l.cnote_city ) = '${branch}'`
				}

			}

		} else {

			predicate = ``

		}

		return predicate

	}
	//====================================================================================


	//====================================================================================
	function buildLocationPredicate( locationID ) {
	//====================================================================================

		let predicate

		if ( locationID ) {
			predicate = `and l.locationID = ${locationID}`
		} else {
			predicate = ``
		}

		return predicate

	}
	//====================================================================================




}
