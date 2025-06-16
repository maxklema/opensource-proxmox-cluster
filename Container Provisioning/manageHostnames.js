// ~/shell/manageHostnames.js on proxmox host
// Module file containing a function to check if a hostname exists in the hostnames.json file and another file to add new hostnames
// Ensures that two duplicate containers (appnames/hostnames) cannot co-exist 
// Updated: June 16, 2025 Maxwell Klema

const fs = require('fs');
const path = require('path');

const JsonFile = path.join(__dirname, 'hostnames.json');
const data = fs.readFileSync(JsonFile, 'utf8');
const hostnames = JSON.parse(data);

// Function to check if a hostname exists in the JSON file
function checkHostnameExists(hostname){;
    if (hostnames[0].hasOwnProperty(hostname)) {
        console.log('true');
	return true;
    } else {
	console.log('false');
        return false;
    }
}

// Function to add a new hostname to the JSON file
function addHostname(hostname, ipAddress, type) {
    if (checkHostnameExists(hostname)) {
        return;
    }
    
    new_entry = {
        "ip": ipAddress,
        "type": type,
        "date_added": new Date().toISOString()
    }

    hostnames[0][hostname] = new_entry;

    fs.writeFileSync(JsonFile, JSON.stringify(hostnames, null, 2));
}
module.exports = { addHostname, checkHostnameExists };
