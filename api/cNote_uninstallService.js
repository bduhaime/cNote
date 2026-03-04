// be sure to launch CMD as Administrator!
// then execute this from the command prompt>node cNote_uninstallService.js

const Service = require('node-windows').Service

// Create a new service object
const svc = new Service({
  name:'cNote',
  script: require('path').join(__dirname,'app.js')
});

// Listen for the "uninstall" event so we know when it's done.
svc.on('uninstall',function(){
  console.error('Uninstall complete.');
  console.error('The service exists: ',svc.exists);
});

// Uninstall the service.
svc.uninstall();
