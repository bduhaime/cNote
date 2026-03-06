// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

let knex = require('knex');

module.exports = knex({
    client: 'mssql', // pg, mssql, etc

    connection: {
        database: 'lightspeed',
        host: 'bill.local',
        password: '__REPLACE_ME__',
        user: '__REPLACE_ME__',
        dateStrings: true,
        debug: true,
        options: {
            enableArithAbort: false
        }
    }

});
