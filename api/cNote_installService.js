// be sure to launch CMD as Administrator!
// then execute this from the command prompt>node cNote_installService.js


const Service = require('node-windows').Service

// Create a new service object
const svc = new Service({
  name:'cNote',
  description: 'cNote API web server.',
  script: 'e:\\www\\banks\\api\\app.js',
  nodeOptions: [
    '--harmony',
    '--max_old_space_size=4096'
  ]
  //, workingDirectory: '...'
  //, allowServiceLogon: true
});

// Listen for the "install" event, which indicates the
// process is available as a service.
svc.on('install',function(){
  svc.start();
});

svc.install();
