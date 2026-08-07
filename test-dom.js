const fs = require('fs');
const readline = require('readline');
const logsDir = '/home/emreturkmen/.gemini/antigravity-ide/brain/ae775a86-3b4d-4a7a-bc13-0600718346d1/.system_generated/logs';
if (fs.existsSync(logsDir + '/transcript.jsonl')) {
    const fileStream = fs.createReadStream(logsDir + '/transcript.jsonl');
    const rl = readline.createInterface({ input: fileStream });
    let lastUser = '';
    let lastModel = '';
    rl.on('line', (line) => {
        try {
            const entry = JSON.parse(line);
            if (entry.source === 'USER_EXPLICIT') lastUser = entry.content;
            if (entry.source === 'MODEL' && entry.type === 'PLANNER_RESPONSE') lastModel = entry.content;
        } catch(e){}
    });
    rl.on('close', () => {
        console.log("USER:", lastUser.substring(0, 200));
        console.log("MODEL:", lastModel.substring(0, 200));
    });
}
