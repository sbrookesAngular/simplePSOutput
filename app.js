//https://adamtheautomator.com/html-report/

import { createRequire } from 'module';
const require = createRequire(import.meta.url);

let http = require('http');
let fs = require('fs');
let port = 9997;

/* -- POWERSHELL RELATED START -- */
//script that opens and executes the powershell script
//populates data into  dataX.json
var spawn = require("child_process").spawn, child;
// child = spawn("powershell.exe",["./zaw.ps1"]);
child = spawn("powershell.exe",["./Get-IntelEthernet.ps1"]);
child.stdout.on("data", function(data){
    console.log("Powershell Data: " + data);
});
// child.stderr.on("data",function(data){
//     console.log("Powershell Errors: " + data);
// });
// child.on("exit",function(){
//     console.log("Powershell Script finished");
// });
// child.stdin.end(); //end input
/* -- POWERSHELL RELATED END -- */


//serving and rendering
const server = http.createServer((request, response) => {

    /*
    the issue is trying to bring in the data from dataX.json
    to be used int the HTML. Node does not make it clear how to do this
    I've tried many ways and many scopes in this file to no avail
    and you cannot pull it from the script found index.html
    like you normally can with vanilla JS!!!! utterly frustrating!!!!!
    */

    response.writeHead(200, {
        // 'Content-Type': 'text/html'
        'Content-Type': 'application/json'
    });


    //reads and outputs files
    // fs.readFile('./ethernetInfo.html', null, function (error, data) {
    
    // fs.readFile('./index.html', null, function (error, data) {
    fs.readFile('./dataX.json', null, function (error, data) {
        if (error) {

            response.writeHead(404);
            respone.write('Whoops! File not found!');

        } else {

            response.write(data);
            console.log(`Server is listening on port number: ${port}`);

        }
        response.end();

    });

});

server.listen(port, () => {

    console.log(`Server is listening on port number: ${port}`);

});


/* -- PAGE RENDERING START -- */

//trying a simpler approach
// const server = http.createServer((req, res) => {

//     //use this with HTML
//     // res.writeHead(200, { 'content-type': 'text/html' })
//     // fs.createReadStream('index.html').pipe(res);
//     // fs.createReadStream('ethernetInfo.html').pipe(res);

//     res.writeHead(200, { 'content-type': 'application/json' })
//     fs.createReadStream('dataX.json').pipe(res);
//     fs.readFile('./index.html', null);

// });
  
// server.listen(process.env.PORT || 3000);
// /* -- PAGE RENDERING END -- */