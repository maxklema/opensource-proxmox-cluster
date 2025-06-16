// ~/shell/hostnameRunner.js on proxmox host
// Runner file to call JS functions in the create_container script using node runtime
// Updated: June 16, 2025 Maxwell Klema

manageHostnames = require('./manageHostnames.js');

const [,, func, ...args] = process.argv;
if (func == "checkHostnameExists"){
    manageHostnames.checkHostnameExists(...args)
} else if (func == "addHostname") {
    manageHostnames.addHostname(...args);
} else {
    console.error("Invalid function name. Use 'checkHostnameExists' or 'addHostname'.");
    process.exit(1);
}
