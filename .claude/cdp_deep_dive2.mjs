import WebSocket from 'ws';

const PAGE_ID = '290B2E4CCC5E76C33C7AF2FCA772B880';
const ws = new WebSocket(`ws://localhost:9222/devtools/page/${PAGE_ID}`);

let responses = {};
let pending = 0;

function send(id, method, params = {}) {
    pending++;
    ws.send(JSON.stringify({id, method, params}));
}

function done() {
    pending--;
    if (pending <= 0) {
        setTimeout(() => { ws.close(); process.exit(0); }, 500);
    }
}

ws.on('open', () => {
    // ====== 1. Get IndexedDB database names via CDP API ======
    send(1, 'IndexedDB.requestDatabaseNames');

    // ====== 2. List all object stores in zdb_ via JS with callback pattern ======
    send(2, 'Runtime.evaluate', {expression: `(function() {
        var result = '__PENDING__';
        try {
            var req = indexedDB.open('zdb_8791610426867118415', 74);
            req.onsuccess = function(event) {
                var db = event.target.result;
                var names = Array.from(db.objectStoreNames);
                db.close();
                result = JSON.stringify({stores: names, count: names.length});
            };
            req.onerror = function() { result = JSON.stringify({error: 'cannot open zdb_'}); };
        } catch(e) { result = JSON.stringify({error: e.message}); }
        // Polling approach - the result will be set asynchronously
        setTimeout(function() { window.__zdbResult = result; }, 1000);
        return 'waiting...';
    })()`, returnByValue: true});

    // ====== 3. Get message count and last messages from zdb_ ======
    send(3, 'Runtime.evaluate', {expression: `(function() {
        window.__msgData = { status: 'pending' };
        var req = indexedDB.open('zdb_8791610426867118415', 74);
        req.onsuccess = function(event) {
            var db = event.target.result;
            if (!db.objectStoreNames.contains('message')) {
                window.__msgData = { error: 'no message store', stores: Array.from(db.objectStoreNames) };
                db.close();
                return;
            }
            var tx = db.transaction(['message'], 'readonly');
            var store = tx.objectStore('message');
            var countReq = store.count();
            countReq.onsuccess = function() {
                window.__msgData.count = countReq.result;
                // Get last 5 messages
                var msgs = [];
                var cursorReq = store.openCursor(null, 'prev');
                cursorReq.onsuccess = function(e) {
                    var cursor = e.target.result;
                    if (cursor && msgs.length < 5) {
                        var v = cursor.value;
                        msgs.push({
                            msgId: v.msgId,
                            msgType: v.msgType,
                            status: v.status,
                            sendDttm: v.sendDttm,
                            fromUid: v.fromUid,
                            toUid: v.toUid,
                            cmd: v.cmd,
                            originMsgType: v.originMsgType,
                            src: v.src,
                            syncFromMobile: v.syncFromMobile,
                            cliMsgId: v.cliMsgId,
                            e2eeStatus: v.e2eeStatus,
                            msgLen: v.message ? v.message.length : 0,
                            msgPreview: v.message ? v.message.substring(0, 60) : null,
                            ttl: v.ttl,
                            hasMentions: v.mentions ? v.mentions.length : 0
                        });
                        cursor.continue();
                    } else {
                        window.__msgData.messages = msgs;
                        window.__msgData.status = 'done';
                        db.close();
                    }
                };
            };
        };
        req.onerror = function() { window.__msgData = { error: 'cannot open' }; };
        return 'reading...';
    })()`, returnByValue: true});

    // ====== 4. Read msginfo_ database ======
    send(4, 'Runtime.evaluate', {expression: `(function() {
        window.__msginfoData = { status: 'pending' };
        var req = indexedDB.open('msginfo_8791610426867118415', 7);
        req.onsuccess = function(event) {
            var db = event.target.result;
            var storeNames = Array.from(db.objectStoreNames);
            var result = { stores: {}, storeList: storeNames };
            var processed = 0;
            storeNames.forEach(function(name) {
                var tx = db.transaction([name], 'readonly');
                var store = tx.objectStore(name);
                var cr = store.count();
                cr.onsuccess = function() {
                    result.stores[name] = { count: cr.result };
                    if (name === 'MsgInfo' || name === 'unreadInfo') {
                        var curReq = store.openCursor(null, 'prev');
                        var items = [];
                        curReq.onsuccess = function(e) {
                            var c = e.target.result;
                            if (c && items.length < 3) {
                                items.push(c.value);
                                c.continue();
                            } else {
                                result.stores[name].samples = items;
                                processed++;
                                checkDone();
                            }
                        };
                    } else {
                        processed++;
                        checkDone();
                    }
                };
            });
            function checkDone() {
                if (processed === storeNames.length) {
                    window.__msginfoData = result;
                    window.__msginfoData.status = 'done';
                    db.close();
                }
            }
        };
        req.onerror = function() { window.__msginfoData = { error: 'cannot open' }; };
        return 'reading...';
    })()`, returnByValue: true});

    // ====== 5. Hook WebSocket to capture real messages ======
    send(5, 'Runtime.evaluate', {expression: `(function() {
        // Store original onmessage handler approach
        window.__wsHooked = false;
        window.__capturedMessages = [];

        // Try to find existing WebSocket by overriding prototype
        var OrigWS = WebSocket;
        window.__wsInstances = [];

        // Use performance API to monitor websocket
        if (window.PerformanceObserver) {
            window.__wsObserver = new PerformanceObserver(function(list) {
                var entries = list.getEntries();
                for (var i = 0; i < entries.length; i++) {
                    if (entries[i].name.indexOf('wpa.chat.zalo.me') > -1 || entries[i].name.indexOf('socket') > -1) {
                        window.__capturedMessages.push({
                            url: entries[i].name,
                            type: entries[i].entryType,
                            duration: entries[i].duration,
                            transferSize: entries[i].transferSize,
                            time: Date.now()
                        });
                    }
                }
            });
            window.__wsObserver.observe({type: 'resource', buffered: true});
            window.__wsHooked = true;
        }

        // DOM MutationObserver to watch for new message bubbles
        window.__domMutations = [];
        window.__domObserver = new MutationObserver(function(mutations) {
            mutations.forEach(function(m) {
                if (m.type === 'childList' && m.addedNodes.length > 0) {
                    for (var i = 0; i < m.addedNodes.length; i++) {
                        var node = m.addedNodes[i];
                        if (node.nodeType === 1) { // Element
                            var cls = node.className || '';
                            if (typeof cls === 'string' && (cls.includes('msg') || cls.includes('message') || cls.includes('conv'))) {
                                window.__domMutations.push({
                                    class: cls.substring(0, 200),
                                    text: (node.innerText || '').substring(0, 150),
                                    time: Date.now(),
                                    addedCount: m.addedNodes.length
                                });
                                if (window.__domMutations.length > 20) window.__domMutations.shift();
                            }
                        }
                    }
                }
            });
        });
        window.__domObserver.observe(document.body, { childList: true, subtree: true });

        return JSON.stringify({wsHooked: window.__wsHooked, domObserverActive: true, initialCaptureCount: window.__capturedMessages.length});
    })()`, returnByValue: true});

    // ====== 6. Get conv list from DOM (detailed) ======
    send(6, 'Runtime.evaluate', {expression: `(function() {
        var convs = [];
        document.querySelectorAll('.msg-item, [class*=conv-item]').forEach(function(el) {
            var text = (el.innerText || '').trim();
            if (text && text.length > 3) {
                var unreadEl = el.querySelector('[class*=unread], [class*=badge], [class*=count]');
                var timeEl = el.querySelector('[class*=time], [class*=timestamp]');
                var nameEl = el.querySelector('[class*=name], [class*=title]');
                convs.push({
                    name: nameEl ? nameEl.innerText.trim() : text.split('\\n')[0],
                    preview: text.split('\\n').slice(1).join(' | ').substring(0, 120),
                    hasUnread: !!unreadEl,
                    unreadText: unreadEl ? unreadEl.innerText.trim() : '',
                    className: el.className.substring(0, 100)
                });
            }
        });
        return JSON.stringify({conversationCount: convs.length, conversations: convs.slice(0, 20)});
    })()`, returnByValue: true});

    // ====== 7. Read sync_ database to see sync state ======
    send(7, 'Runtime.evaluate', {expression: `(function() {
        window.__syncData = { status: 'pending' };
        var req = indexedDB.open('sync_8791610426867118415', 1);
        req.onsuccess = function(event) {
            var db = event.target.result;
            var names = Array.from(db.objectStoreNames);
            if (names.length > 0) {
                var tx = db.transaction([names[0]], 'readonly');
                var store = tx.objectStore(names[0]);
                var allReq = store.getAll();
                allReq.onsuccess = function() {
                    window.__syncData = { storeName: names[0], entries: allReq.result };
                    db.close();
                };
            } else {
                window.__syncData = { storeNames: names, empty: true };
                db.close();
            }
        };
        req.onerror = function() { window.__syncData = { error: 'cannot open sync_' }; };
        return 'reading...';
    })()`, returnByValue: true});

    // ====== 8. Read sidx_ search index ======
    send(8, 'Runtime.evaluate', {expression: `(function() {
        window.__sidxData = { status: 'pending' };
        var req = indexedDB.open('sidx_8791610426867118415', 2);
        req.onsuccess = function(event) {
            var db = event.target.result;
            var names = Array.from(db.objectStoreNames);
            var result = { stores: {} };
            var done = 0;
            names.forEach(function(name) {
                var tx = db.transaction([name], 'readonly');
                var store = tx.objectStore(name);
                var cr = store.count();
                cr.onsuccess = function() {
                    result.stores[name] = { count: cr.result };
                    done++;
                    if (done === names.length) {
                        window.__sidxData = result;
                        db.close();
                    }
                };
            });
        };
        req.onerror = function() { window.__sidxData = { error: 'cannot open' }; };
        return 'reading...';
    })()`, returnByValue: true});

    setTimeout(() => { ws.close(); process.exit(0); }, 6000);
});

// Poll for async results
let pollCount = 0;
const pollInterval = setInterval(() => {
    pollCount++;
    if (pollCount > 5) { clearInterval(pollInterval); return; }

    ws.send(JSON.stringify({id: 100 + pollCount, method: 'Runtime.evaluate', params: {expression: `JSON.stringify({
        msgData: window.__msgData || 'not set',
        msginfoData: window.__msginfoData || 'not set',
        syncData: window.__syncData || 'not set',
        sidxData: window.__sidxData || 'not set',
        zdbResult: window.__zdbResult || 'not set',
        capturedMessages: window.__capturedMessages ? window.__capturedMessages.slice(-5) : 'not set',
        domMutations: window.__domMutations ? window.__domMutations.slice(-10) : 'not set'
    })`, returnByValue: true}}));
}, 1500);

ws.on('message', (data) => {
    try {
        const msg = JSON.parse(data);
        const id = msg.id;

        if (msg.result?.result?.value && id >= 100) {
            // Poll results
            try {
                const val = JSON.parse(msg.result.result.value);
                console.log('========================================');
                console.log('POLL #' + (id - 100) + ' - Async Results:');
                if (val.msgData && val.msgData !== 'not set') {
                    console.log('--- Message Data ---');
                    console.log(JSON.stringify(val.msgData, null, 2));
                }
                if (val.msginfoData && val.msginfoData !== 'not set') {
                    console.log('--- MsgInfo Data ---');
                    console.log(JSON.stringify(val.msginfoData, null, 2).substring(0, 2000));
                }
                if (val.syncData && val.syncData !== 'not set') {
                    console.log('--- Sync Data ---');
                    console.log(JSON.stringify(val.syncData, null, 2));
                }
                if (val.sidxData && val.sidxData !== 'not set') {
                    console.log('--- Search Index Data ---');
                    console.log(JSON.stringify(val.sidxData, null, 2));
                }
                if (val.zdbResult && val.zdbResult !== 'not set') {
                    console.log('--- ZDB Stores ---');
                    console.log(JSON.stringify(val.zdbResult, null, 2));
                }
                if (val.capturedMessages && val.capturedMessages !== 'not set' && val.capturedMessages.length > 0) {
                    console.log('--- Captured WS Messages ---');
                    console.log(JSON.stringify(val.capturedMessages, null, 2));
                }
                if (val.domMutations && val.domMutations !== 'not set' && val.domMutations.length > 0) {
                    console.log('--- Recent DOM Mutations ---');
                    console.log(JSON.stringify(val.domMutations, null, 2));
                }
            } catch(e) {}
        } else if (msg.result?.result?.value && id <= 10) {
            console.log('--- Response #' + id + ' ---');
            console.log(msg.result.result.value);
        } else if (msg.result && !msg.result.result) {
            // CDP API result
            if (id === 1) {
                console.log('--- IndexedDB Databases ---');
                console.log(JSON.stringify(msg.result, null, 2));
            }
        }
        if (msg.error) {
            console.log('Error #' + id + ':', JSON.stringify(msg.error).substring(0, 300));
        }
        if (id < 100) done();
    } catch(e) {
        if (data.toString().length < 1000) console.log('Raw:', data.toString());
    }
});

ws.on('error', (err) => { console.log('WS Error:', err.message); process.exit(1); });
