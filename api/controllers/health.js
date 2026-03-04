// ----------------------------------------------------------------------------------------
// Health endpoint (no auth)
// ----------------------------------------------------------------------------------------

const os = require( 'os' );

module.exports.set = function( app ) {

	//====================================================================================
	app.get( '/api/health', async ( req, res ) => {
	//====================================================================================

		const started = Date.now();

		const payload = {
			ok: true,
			service: 'cnote-api',
			status: 'up',
			time: new Date().toISOString(),
			hostname: os.hostname(),
			uptimeSeconds: Math.floor( process.uptime() ),
			checks: {
				api: { ok: true, ms: 0 },
				db: { ok: false, ms: null }
			}
		};

		try {

			// Your pool is effectively global in this codebase (created in controllers/index.js)
			// We’ll safely look for it either way.
			const poolRef = ( global.pool ?? pool );

			if ( poolRef ) {

				const dbStarted = Date.now();
				await poolRef.request().query( 'SELECT 1 AS ok;' );
				payload.checks.db.ok = true;
				payload.checks.db.ms = Date.now() - dbStarted;

			} else {

				// API is up, but DB pool not present (or not initialized yet)
				payload.checks.db.ok = false;
				payload.checks.db.ms = 0;

			}

			payload.checks.api.ms = Date.now() - started;

			// If DB is down, return 503 so monitors can alert.
			return res.status( payload.checks.db.ok ? 200 : 503 ).json( payload );

		} catch ( err ) {

			payload.ok = false;
			payload.status = 'degraded';
			payload.checks.api.ms = Date.now() - started;
			payload.error = 'DB_CHECK_FAILED';

			return res.status( 503 ).json( payload );

		}

	});
	//====================================================================================

};
