const fs = require('fs');
const readline = require('readline');
const logsDir = '/home/emreturkmen/.gemini/antigravity-ide/brain/03d92ff5-ece5-4658-9bae-abad014866b1/.system_generated/logs';
if (fs.existsSync(logsDir + '/transcript.jsonl')) {
    const fileStream = fs.createReadStream(logsDir + '/transcript.jsonl');
    const rl = readline.createInterface({ input: fileStream });
    let modelMsgs = [];
    rl.on('line', (line) => {
        try {
            const entry = JSON.parse(line);
            if (entry.source === 'MODEL' && entry.type === 'PLANNER_RESPONSE') {
                if (entry.content) modelMsgs.push(entry.content);
            }
        } catch(e){}
    });
    rl.on('close', () => {
        console.log("LAST 3 MODEL MESSAGES:");
        console.log(modelMsgs.slice(-3).map(m => m.substring(0, 100)).join('\n---\n'));
    });
}
