const http = require('http');
const server = http.createServer((req, res) => {
	res.statusCode = 200;
	res.setHeader('Content-Type', 'text/plain');
	res.write('[OK]\n');
	res.write('NodeJS is running\n');
	res.end();
});
server.listen(3000, '0.0.0.0');
