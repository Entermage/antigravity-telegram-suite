const BaseDriver = require('./base_driver');
const { getLocatorsScript } = require('../locators');

class StandaloneDriver extends BaseDriver {
    constructor() {
        super('agent', 'antigravity', 9333);
    }

    getLocatorsScript() {
        return getLocatorsScript('agent');
    }

    getActiveThreadInfoScript() {
        return `(() => {
            let name = document.title || null;
            let nameSource = document.title ? 'document-title' : 'none';
            let threadIdVal = null;
            
            try {
                const url = window.location.href;
                const urlMatch = url.match(/\\/c\\/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/i);
                if (urlMatch) threadIdVal = urlMatch[1];
            } catch (e) {}

            let workspace = null;
            if (threadIdVal) {
                const activeLink = document.querySelector('a[href*="' + threadIdVal + '"]');
                if (activeLink) {
                    const header = document.querySelector('button[class*="headerbtn"]');
                    if (header) {
                        let container = header;
                        while (container && container !== document.body) {
                            if (container.children.length > 5) break;
                            container = container.parentElement;
                        }
                        if (container) {
                            let currWs = null;
                            for (const child of Array.from(container.children)) {
                                const h = child.querySelector('button[class*="headerbtn"]');
                                if (h) currWs = h.textContent.trim().replace(/\\s+\\d+$/, '');
                                if (child.contains(activeLink) && currWs) {
                                    workspace = currWs;
                                    break;
                                }
                            }
                        }
                    }
                }
            }

            // Fallback for older standalone versions
            if (!workspace) {
                const panel = document.querySelector(".antigravity-agent-side-panel");
                const wsEl2 = panel ? panel.querySelector("div.text-lg.font-medium") : null;
                if (wsEl2) workspace = wsEl2.textContent.trim();
            }

            return { name, workspace, threadId: threadIdVal, nameSource };
        })()`;
    }

    getSwitchThreadScript(threadNameStr, targetWsNameStr) {
        return `(async () => {
            const targetThread = ${threadNameStr};
            const targetWs = ${targetWsNameStr};
            const normalize = s => (s || '').toLowerCase().replace(/[^a-z0-9]/g, '');

            if (normalize(document.title) === normalize(targetThread)) {
                return 'already-active';
            }

            // Expand all 'See all' buttons if present in sidebar
            const seeAllBtns = Array.from(document.querySelectorAll('button')).filter(b => /see\\s+all/i.test(b.textContent.trim()));
            for (const b of seeAllBtns) {
                try { b.click(); } catch(e) {}
            }

            // Find matching conversation link
            const allLinks = Array.from(document.querySelectorAll('a[href*="/c/"]'));
            let targetLink = allLinks.find(a => {
                const aria = a.getAttribute('aria-label') || '';
                const text = a.textContent.trim();
                return normalize(aria) === normalize(targetThread) || normalize(text) === normalize(targetThread);
            });

            // If not found, try fuzzy match
            if (!targetLink && targetThread.length > 5) {
                const targetNorm = normalize(targetThread);
                targetLink = allLinks.find(a => {
                    const aria = normalize(a.getAttribute('aria-label') || '');
                    const text = normalize(a.textContent.trim());
                    return (aria && (aria.includes(targetNorm) || targetNorm.includes(aria))) ||
                           (text && (text.includes(targetNorm) || targetNorm.includes(text)));
                });
            }

            if (!targetLink) {
                // Fallback for legacy workspace cards
                const cards = Array.from(document.querySelectorAll('[data-project-card="true"], [data-workspace-card="true"]'));
                for (const card of cards) {
                    const threadRows = Array.from(card.querySelectorAll('a, [role="button"]'));
                    for (const row of threadRows) {
                        const title = row.getAttribute('aria-label') || row.textContent.trim();
                        if (normalize(title) === normalize(targetThread)) {
                            targetLink = row;
                            break;
                        }
                    }
                    if (targetLink) break;
                }
            }

            if (!targetLink) return 'not-found';

            // Click target link with full pointer & mouse events
            targetLink.focus();
            const rect = targetLink.getBoundingClientRect();
            const clientX = rect.left + rect.width / 2;
            const clientY = rect.top + rect.height / 2;

            try {
                targetLink.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, cancelable: true, clientX, clientY, pointerId: 1, pointerType: 'mouse' }));
                targetLink.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, cancelable: true, clientX, clientY }));
                targetLink.dispatchEvent(new PointerEvent('pointerup', { bubbles: true, cancelable: true, clientX, clientY, pointerId: 1, pointerType: 'mouse' }));
                targetLink.dispatchEvent(new MouseEvent('mouseup', { bubbles: true, cancelable: true, clientX, clientY }));
                targetLink.click();
            } catch (e) {
                targetLink.click();
            }

            await new Promise(r => setTimeout(r, 500));
            return 'clicked';
        })()`;
    }

    getListAgentThreadsScript() {
        return `(() => {
            const header = document.querySelector('button[class*="headerbtn"]');
            if (header) {
                // Standalone 2.0 Sidebar Hierarchy
                let container = header;
                while (container && container !== document.body) {
                    if (container.children.length > 5) break;
                    container = container.parentElement;
                }

                const workspaces = [];
                let currentWs = null;

                if (container) {
                    for (const child of Array.from(container.children)) {
                        const headerBtn = child.querySelector('button[class*="headerbtn"]');
                        if (headerBtn) {
                            const wsName = headerBtn.textContent.trim().replace(/\\s+\\d+$/, '');
                            currentWs = { workspace: wsName, threads: [] };
                            workspaces.push(currentWs);
                            continue;
                        }

                        const link = child.querySelector('a[href*="/c/"]');
                        if (link) {
                            const title = link.getAttribute('aria-label') || link.textContent.trim();
                            let time = '';
                            const timeSpan = Array.from(child.querySelectorAll('span, p, div')).find(s => 
                                s.textContent.trim() !== title && 
                                /^[0-9]+[smhd]|^[0-9]+:[0-9]+|^[0-9]+\\s*(min|hour|day|sec|mo|wk|yr)/i.test(s.textContent.trim())
                            );
                            if (timeSpan) time = timeSpan.textContent.trim();

                            if (title && !/^(Projects|Conversations|Settings|New Conversation|See all)/i.test(title)) {
                                if (!currentWs) {
                                    currentWs = { workspace: 'Default', threads: [] };
                                    workspaces.push(currentWs);
                                }
                                if (!currentWs.threads.some(t => t.name === title)) {
                                    currentWs.threads.push({ name: title, time, href: link.getAttribute('href') });
                                }
                            }
                        }
                    }
                }

                if (workspaces.length > 0 && workspaces.some(w => w.threads.length > 0)) {
                    return JSON.stringify(workspaces);
                }
            }

            // Fallback for older standalone versions
            const panel = document.querySelector(".antigravity-agent-side-panel");
            if (panel) {
                const wsEl = panel.querySelector("div.text-lg.font-medium");
                const currentWsName = wsEl ? wsEl.textContent.trim() : "Default";
                
                const workspacesMap = {};
                const btns = Array.from(panel.querySelectorAll("button.group.cursor-pointer, a.group, a[href*='/c/']"));
                
                for (const item of btns) {
                    const nameEl = item.querySelector("div.truncate, span.truncate") || item;
                    const timeEl = item.querySelector("p.text-muted-foreground, span.text-xs");
                    const name = item.getAttribute('aria-label') || (nameEl ? nameEl.textContent.trim() : "");
                    const time = timeEl ? timeEl.textContent.trim() : "";
                    if (name && !/^(Projects|Conversations|Settings|New Conversation|See all)/i.test(name)) {
                        if (!workspacesMap[currentWsName]) workspacesMap[currentWsName] = { workspace: currentWsName, threads: [] };
                        if (!workspacesMap[currentWsName].threads.find(t => t.name === name)) {
                            workspacesMap[currentWsName].threads.push({ name, time });
                        }
                    }
                }
                return JSON.stringify(Object.values(workspacesMap));
            }

            // General fallback: collect all a[href*="/c/"] links
            const allLinks = Array.from(document.querySelectorAll('a[href*="/c/"]'));
            if (allLinks.length > 0) {
                const threads = allLinks.map(a => ({
                    name: a.getAttribute('aria-label') || a.textContent.trim(),
                    time: '',
                    href: a.getAttribute('href')
                })).filter(t => t.name && !/^(Projects|Conversations|Settings|New Conversation|See all)/i.test(t.name));

                return JSON.stringify([{ workspace: 'Default', threads }]);
            }

            return JSON.stringify([]);
        })()`;
    }
}

module.exports = StandaloneDriver;
