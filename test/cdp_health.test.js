const assert = require('assert');
const { ensureCdpReady, isConnectionRefusedError } = require('../src/cdp_health');

async function run() {
    assert.strictEqual(isConnectionRefusedError(new Error('connect ECONNREFUSED 127.0.0.1:9333')), true);
    assert.strictEqual(isConnectionRefusedError(new Error('other failure')), false);

    const events = [];
    let reachable = false;
    await ensureCdpReady({
        port: 9333,
        app: 'agent',
        isReachable: async () => reachable,
        restartApp: async (app, port) => {
            events.push(`restart:${app}:${port}`);
            reachable = true;
        },
        waitMs: 0
    });
    assert.deepStrictEqual(events, ['restart:agent:9333']);

    events.length = 0;
    await ensureCdpReady({
        port: 9333,
        app: 'agent',
        isReachable: async () => true,
        restartApp: async () => events.push('restart'),
        waitMs: 0
    });
    assert.deepStrictEqual(events, []);

    // Test onStarting and onStarted callbacks
    events.length = 0;
    let reachState = false;
    await ensureCdpReady({
        port: 9333,
        app: 'agent',
        isReachable: async () => reachState,
        restartApp: async (app, port) => {
            events.push(`restart:${app}:${port}`);
            reachState = true;
        },
        onStarting: async (app, port) => {
            events.push(`starting:${app}:${port}`);
        },
        onStarted: async (app, port) => {
            events.push(`started:${app}:${port}`);
        },
        waitMs: 0
    });
    assert.deepStrictEqual(events, [
        'starting:agent:9333',
        'restart:agent:9333',
        'started:agent:9333'
    ]);

    console.log('✅ CDP health tests passed!');
}

run().catch(err => {
    console.error(err);
    process.exit(1);
});
