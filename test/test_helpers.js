const http = require('http');

function getRawTargets(port = 9334) {
    return new Promise((resolve, reject) => {
        const req = http.get(`http://127.0.0.1:${port}/json/list`, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                try {
                    resolve(JSON.parse(data));
                } catch (e) {
                    reject(e);
                }
            });
        });
        req.on('error', reject);
        req.setTimeout(3000, () => {
            req.destroy(new Error('Timeout connecting to CDP'));
        });
    });
}

function printResult(testName, success, error) {
    if (success) {
        console.log(`✅ ${testName} passed`);
    } else {
        console.error(`❌ ${testName} failed:`, error || '');
    }
}

module.exports = {
    getRawTargets,
    printResult
};
