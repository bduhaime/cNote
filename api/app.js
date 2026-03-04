// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

global.cnote = require('dotenv').config({ path: './config/cnote.env'})
if (cnote.error) {
  throw cnote.error
}

const bodyParser		= require( 'body-parser' )
const cookieParser 	= require( 'cookie-parser')
const cors 				= require( 'cors' )
const express 			= require( 'express' )
// const session 			= require( 'express-session' )
const fs					= require( 'fs' )
const http				= require( 'http' )
const https				= require( 'https' )
// const passport			= require( 'passport' )



const app = express()
app.use( cors() ) 												// this enables CORS on *all* routes!
app.use( express.json({ limit: '50mb' }) )				// enables use of JSON
app.use( bodyParser.urlencoded({ limit: '50mb', extended: true, parameterLimit: 50000 }) )
app.use( cookieParser() )										// enables cookie parsing

// app.use( session( { secret: 'keyboard cat', resave: true, saveUninitialized: true } ) )
// app.use( passport.initialize() )
// app.use( passport.session() )

// app.post('/login',
//   passport.authenticate('local', { failureRedirect: '/login' }),
//   function( req, res ) {
//     res.redirect('/');
//   });


// Show error information
process.on( 'unhandledRejection', ( reason, p ) => {
	console.error( 'Unhandled promise error:  ' + p + reason )
	console.error( 'stack: ' + reason.stack )
})


const { createLogger, format, transports } = require( 'winston' );
require( 'winston-daily-rotate-file' );

const { combine, timestamp, label, printf } = format;
const cnoteFormat = printf(({ level, message, label, timestamp, user }) => {
	return `${timestamp} [${user}] [${label}] ${level}: ${message}`;
});

global.logger = createLogger({

	transports: [
		new transports.Console({
			level: 'info',
			format: combine(
				format.timestamp({ format: 'MM/DD/YYYY HH:mm:ss' }),
				cnoteFormat
			)
		}),
		new transports.DailyRotateFile({
			level: 'debug',
			format: combine(
				format.timestamp({ format: 'MM/DD/YYYY HH:mm:ss.SSS' }),
				cnoteFormat
			),
			dirname: 'logs',
			filename: 'cNote-%DATE%.log',
			datePattern: 'YYYYMMDD',
			zippedArchive: true,
			// maxSize: '20m',
			maxFiles: '10d'
		})
	]
})
logger.log({ level: 'debug', label: 'app.js', message: '='.repeat(80), user: 'system' })
logger.log({ level: 'debug', label: 'app.js', message: 'Logger instantiated', user: 'system' })
logger.log({ level: 'debug', label: 'app.js', message: '='.repeat(80), user: 'system' })

const controllers = require('./controllers')

controllers.set( app )

logger.log({ level: 'debug', label: 'app.js', message: 'Routes instantiated...', user: 'system' })




//====================================================================================
// app.listen(3000, (req, res) => {
// 	logger.log({ level: 'info', label: 'app.js', message: 'cNote API Service listening on port 3000', user: 'system' })
// })
app.listen(3000, () => {
  logger.log({
    level: 'info',
    label: 'app.js',
    message: 'cNote API Service listening on port 3000 (internal HTTP)',
    user: 'system'
  });
});

const httpsOptions = {
	pfx: fs.readFileSync( process.env.CERT_LOCATION ),
	passphrase: process.env.CERT_PASSPHRASE
}

https.createServer( httpsOptions, app ).listen( 3443, () => {
	logger.log({ level: 'info', label: 'app.js', message: 'cNote API Service listening securely on port 3443', user: 'system' })
})
