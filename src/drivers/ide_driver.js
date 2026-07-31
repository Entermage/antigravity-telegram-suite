const BaseDriver = require('./base_driver');
const { getLocatorsScript } = require('../locators');

class IDEDriver extends BaseDriver {
    constructor() {
        super('ide', 'antigravity-ide', 9222);
    }

    getLocatorsScript() {
        return getLocatorsScript('ide');
    }
}

module.exports = IDEDriver;
