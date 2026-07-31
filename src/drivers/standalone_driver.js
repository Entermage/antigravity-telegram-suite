const BaseDriver = require('./base_driver');
const { getLocatorsScript } = require('../locators');

class StandaloneDriver extends BaseDriver {
    constructor() {
        super('agent', 'antigravity', 9333);
    }

    getLocatorsScript() {
        return getLocatorsScript('agent');
    }
}

module.exports = StandaloneDriver;
