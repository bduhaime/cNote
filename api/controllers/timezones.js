// ----------------------------------------------------------------------------------------
// Copyright 2017-2022, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../config/database.json').mssql;

	//====================================================================================
	https.get('/api/timezones/', utilities.jwtVerify, async (req, res) => {
	//====================================================================================

		try {

			// if ( !req.query.customerID ) return res.status( 400 ).send( 'Parameter missing' )

			let SQL
			let customerDefault = null
			let output = []
			let defaultTZ = null
			let defaultTimezone = 3

			if ( !!req.query.scheduledTimeZoneInd ) {
				defaultTZ = await getScheduledTimeZone( req.query.scheduledTimeZoneInd )
			} else {
				if ( !!req.query.customerID ) {
					defaultTZ = await getCustomerDefaultTimezone( req.query.customerID )
				} else {
					defaultTZ = defaultTimezone
				}
			}

			let timeZones = await getTimeZones()

			for ( tz of timeZones ) {

				output.push({
					id: tz.id,
					name: tz.name,
					displayName: tz.displayName,
					ianaName: tz.fullName,
					default: ( tz.id === defaultTZ ) ? true : false
				})

			}

			return res.json( output )

		} catch( err ) {

			logger.log({ level: 'error', label: 'GET:timezones/', message: err, user: req.session.userID });
			return res.status( 500 ).json({ ok: false, message: 'Unexpected database error' });

		}


	})
	//====================================================================================


	//====================================================================================
	async function getScheduledTimeZone( scheduledTimeZoneInd ) {
	//====================================================================================

		try {

			const SQL =	`select id from timezones where fullName = @scheduledTimeZoneInd`;

			const results = await poopool.request()
				.input( 'scheduledTimeZoneInd', sql.VarChar( 30 ), scheduledTimeZoneInd )
				.query( SQL);

			return result.recordset[0].id ? result.recordset[0].id : null;

		} catch( err ) {

			logger.log({ level: 'error', label: 'timezones/getCustomerDefaultTimezone()', message: err });
			throw new Error( err );

		}

	}
	//====================================================================================


	//====================================================================================
	async function getCustomerDefaultTimezone( customerID ) {
	//====================================================================================

		try {

			const SQL = `
				select
					case when c.defaultTimezone is not null then
						case when c.defaultTimezone = 0 then tz.id else c.defaultTimezone end
					else
						tz.id
					end as defaultTimezone
				from customer c
				join timezones tz on ( [default] = 1 )
				where c.id = @customerID ;
			`;

			const results = await pool.request()
				.input( 'customerID', sql.BigInt, customerID )
				.query( SQL);

			const customerDefault = ( !!results.recordset[0].defaultTimezone ) ? results.recordset[0].defaultTimezone : null;
			return customerDefault;

		} catch( err ) {

			logger.log({ level: 'error', label: 'timezones/getCustomerDefaultTimezone()', message: err });
			throw new Error( err );

		}

	}
	//====================================================================================


	//====================================================================================
	async function getTimeZones() {
	//====================================================================================

		try {

			const SQL = `
				select
					id,
					name,
					fullName,
					[default],
					displayName
				from timezones
				order by utcOffset, displayName
			`;

			results = await pool.request().query( SQL );

			return results.recordset;

		} catch( err ) {

			logger.log({ level: 'error', label: 'timezones/getTimeZones()', message: err });
			throw new Error( err );

		}

	}
	//====================================================================================

}
