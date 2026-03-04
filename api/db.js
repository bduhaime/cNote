const sql = require('mssql');
const dbConfig = require('./config/database.json').mssql;

const poolPromise = new sql.ConnectionPool(dbConfig)
	.connect()
	.then(pool => {
		console.log('✔️ Connected to MSSQL');
		return pool;
	})
	.catch(err => {
		console.error('❌ Database Connection Failed!', err);
		throw err;
	});

module.exports = {
	sql,
	poolPromise
};
