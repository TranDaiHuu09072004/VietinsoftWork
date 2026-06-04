import WebSocket from 'ws';

const PAGE_ID = '290B2E4CCC5E76C33C7AF2FCA772B880';
const ws = new WebSocket(`ws://localhost:9222/devtools/page/${PAGE_ID}`);

let responses = {};
let pending = 0;
let timer = null;

function send(id, expression) {
    pending++;
    ws.send(JSON.stringify({id, method: 'Runtime.evaluate', params: {expression, returnByValue: true}}));
}

function done() {
    pending--;
    if (pending <= 0) {
        setTimeout(() => { ws.close(); process.exit(0); }, 500);
    }
}

ws.on('open', () => {
    // ====== 1. IndexedDB: list all databases ======
    send(1, `(async function() {
        try {
            const dbs = await indexedDB.databases();
            return JSON.stringify({dbs: dbs.map(d => ({name: d.name, version: d.version}))});
        } catch(e) { return JSON.stringify({error: e.message}); }
    })()`);

    // ====== 2. Read zdb_ message store: count and sample ======
    send(2, `(async function() {
        try {
            return new Promise((resolve) => {
                const req = indexedDB.open('zdb_8791610426867118415', 74);
                req.onsuccess = (event) => {
                    const db = event.target.result;
                    const tx = db.transaction(['message'], 'readonly');
                    const store = tx.objectStore('message');
                    const countReq = store.count();
                    countReq.onsuccess = () => {
                        const count = countReq.result;
                        // Get last 3 messages
                        const msgs = [];
                        const cursorReq = store.openCursor(null, 'prev');
                        let i = 0;
                        cursorReq.onsuccess = (e) => {
                            const cursor = e.target.result;
                            if (cursor && i < 3) {
                                const val = cursor.value;
                                msgs.push({
                                    msgId: val.msgId,
                                    msgType: val.msgType,
                                    status: val.status,
                                    sendDttm: val.sendDttm,
                                    fromUid: val.fromUid,
                                    toUid: val.toUid,
                                    cmd: val.cmd,
                                    originMsgType: val.originMsgType,
                                    src: val.src,
                                    syncFromMobile: val.syncFromMobile,
                                    cliMsgId: val.cliMsgId,
                                    e2eeStatus: val.e2eeStatus,
                                    messageLen: val.message ? val.message.length : 0,
                                    messagePreview: val.message ? val.message.substring(0, 80) : null,
                                    dNameLen: val.dName ? val.dName.length : 0,
                                    ttl: val.ttl,
                                    properties: val.properties ? Object.keys(val.properties) : null,
                                    mentions: val.mentions ? val.mentions.length : 0
                                });
                                i++;
                                cursor.continue();
                            } else {
                                db.close();
                                resolve(JSON.stringify({dbName: 'zdb_8791610426867118415', messageCount: count, sampleMessages: msgs}));
                            }
                        };
                    };
                };
                req.onerror = () => resolve(JSON.stringify({error: 'Cannot open zdb_8791610426867118415'}));
            });
        } catch(e) { return JSON.stringify({error: e.message}); }
    })()`);

    // ====== 3. Read msginfo_ database ======
    send(3, `(async function() {
        try {
            return new Promise((resolve) => {
                const req = indexedDB.open('msginfo_8791610426867118415', 7);
                req.onsuccess = (event) => {
                    const db = event.target.result;
                    const storeNames = Array.from(db.objectStoreNames);
                    const data = {};
                    let done = 0;
                    storeNames.forEach(name => {
                        const tx = db.transaction([name], 'readonly');
                        const store = tx.objectStore(name);
                        const cr = store.count();
                        cr.onsuccess = () => {
                            data[name] = {count: cr.result};
                            // For MsgInfo, read last 2 entries
                            if (name === 'MsgInfo' && cr.result > 0) {
                                const curReq = store.openCursor(null, 'prev');
                                const items = [];
                                let i = 0;
                                curReq.onsuccess = (e) => {
                                    const c = e.target.result;
                                    if (c && i < 2) {
                                        const v = c.value;
                                        items.push({
                                            msgId: v.msgId,
                                            seenUidsLen: v.seenUids ? v.seenUids.length : 0,
                                            deliveredUidsLen: v.deliveredUids ? v.deliveredUids.length : 0
                                        });
                                        i++;
                                        c.continue();
                                    } else {
                                        data[name].samples = items;
                                        done++;
                                        if (done === storeNames.length) { db.close(); resolve(JSON.stringify({dbName: 'msginfo_8791610426867118415', stores: data})); }
                                    }
                                };
                            } else {
                                done++;
                                if (done === storeNames.length) { db.close(); resolve(JSON.stringify({dbName: 'msginfo_8791610426867118415', stores: data})); }
                            }
                        };
                    });
                };
                req.onerror = () => resolve(JSON.stringify({error: 'Cannot open msginfo_'}));
            });
        } catch(e) { return JSON.stringify({error: e.message}); }
    })()`);

    // ====== 4. Check WebSocket connection state ======
    send(4, `(function() {
        // Intercept WebSocket
        const info = {};
        if (window.WebSocket) {
            info.WebSocketAvailable = true;
            info.readyState = 'Cannot access directly without proxy';
        }
        // Check for socket-related global variables
        const wsKeys = Object.keys(window).filter(k => k.toLowerCase().includes('socket') || k.toLowerCase().includes('ws') || k.toLowerCase().includes('sock'));
        info.socketGlobalKeys = wsKeys.slice(0, 20);

        // Try to find the WebSocket instance via prototype
        const origSend = WebSocket.prototype.send;
        info.prototypeSendExists = typeof origSend === 'function';

        // Check socket polling
        info.socketPollingExists = typeof window.socketPolling === 'function';

        return JSON.stringify(info);
    })()`);

    // ====== 5. Read conversation store from zdb_ ======
    send(5, `(async function() {
        try {
            return new Promise((resolve) => {
                const req = indexedDB.open('zdb_8791610426867118415', 74);
                req.onsuccess = (event) => {
                    const db = event.target.result;
                    const tx = db.transaction(['conversation'], 'readonly');
                    const store = tx.objectStore('conversation');
                    const countReq = store.count();
                    countReq.onsuccess = () => {
                        const count = countReq.result;
                        const convs = [];
                        const cursorReq = store.openCursor();
                        let i = 0;
                        cursorReq.onsuccess = (e) => {
                            const cursor = e.target.result;
                            if (cursor && i < 15) {
                                const val = cursor.value;
                                convs.push({
                                    userId: val.userId,
                                    isGroup: val.isGroup,
                                    numMsg: val.numMsg,
                                    respondedByMe: val.respondedByMe,
                                    pinned: val.pinned,
                                    label: val.label
                                });
                                i++;
                                cursor.continue();
                            } else {
                                db.close();
                                resolve(JSON.stringify({conversationCount: count, conversations: convs}));
                            }
                        };
                    };
                };
                req.onerror = () => resolve(JSON.stringify({error: 'Cannot open for conversations'}));
            });
        } catch(e) { return JSON.stringify({error: e.message}); }
    })()`);

    // ====== 6. DOM MutationObserver - check if there's already one active ======
    send(6, `(function() {
        // Check current DOM for chat-related structures
        const chatContainers = [];
        document.querySelectorAll('[class*=message], [class*=msg], [class*=chat-area], [class*=chat-container], [class*=conversation-view], [class*=main-chat], [class*=right-panel], [class*=detail]').forEach(el => {
            const text = el.innerText?.trim()?.substring(0, 200);
            if (text && text.length > 5) {
                chatContainers.push({class: el.className?.substring(0, 150), text: text.substring(0, 200)});
            }
        });
        return JSON.stringify({chatContainers: chatContainers.slice(0, 15), totalDivs: document.querySelectorAll('div').length});
    })()`);

    // ====== 7. Hook into WebSocket to capture next messages ======
    send(7, `(function() {
        // Monkey-patch WebSocket to log next messages received
        if (!window.__zaloWsMonitor) {
            window.__zaloWsMonitor = { messages: [], maxCapture: 10 };
            const OrigWebSocket = window.WebSocket;
            // We can't easily intercept existing connections, but we can log
            // via performance observer for websocket frames
            try {
                const observer = new PerformanceObserver((list) => {
                    for (const entry of list.getEntries()) {
                        if (entry.name.includes('socket') || entry.name.includes('wpa')) {
                            window.__zaloWsMonitor.messages.push({
                                name: entry.name,
                                duration: entry.duration,
                                transferSize: entry.transferSize,
                                time: Date.now()
                            });
                        }
                    }
                });
                observer.observe({type: 'resource', buffered: false});
                window.__zaloWsMonitor.observerActive = true;
            } catch(e) {
                window.__zaloWsMonitor.observerError = e.message;
            }
        }
        return JSON.stringify({monitorSetUp: true, existing: window.__zaloWsMonitor.messages.length});
    })()`);

    // ====== 8. Check key localStorage values for message tracking ======
    send(8, `(function() {
        const keys = ['0_sock_msg', '0_lsmsg', '0_sock_ac', '0_sock_ctrl', '0_sock_aco', '0_sock_ctrl_aco', '0_sock_ctrl_ac', '0_sock_verfy_510_1', '0_sock_verfy_511_1', 'sh_sock_cnted', '0_sufficient_msg_ts', '0_l_r_msg', '0_config_show_unread_time', '0_last_ack_evict'];
        const values = {};
        keys.forEach(k => {
            const v = localStorage.getItem(k);
            if (v) values[k] = v.length > 300 ? v.substring(0, 300) + '...(truncated)' : v;
        });
        return JSON.stringify({localStorageSocketState: values});
    })()`);

    // ====== 9. Check the e2ee database for encryption keys ======
    send(9, `(async function() {
        try {
            return new Promise((resolve) => {
                const req = indexedDB.open('e2ee_8791610426867118415', 2);
                req.onsuccess = (event) => {
                    const db = event.target.result;
                    const storeNames = Array.from(db.objectStoreNames);
                    const data = {};
                    let done = 0;
                    storeNames.forEach(name => {
                        const tx = db.transaction([name], 'readonly');
                        const store = tx.objectStore(name);
                        const cr = store.count();
                        cr.onsuccess = () => {
                            data[name] = {count: cr.result};
                            done++;
                            if (done === storeNames.length) { db.close(); resolve(JSON.stringify({dbName: 'e2ee_8791610426867118415', stores: data})); }
                        };
                    });
                };
                req.onerror = () => resolve(JSON.stringify({error: 'Cannot open e2ee_'}));
            });
        } catch(e) { return JSON.stringify({error: e.message}); }
    })()`);

    // ====== 10. Read preview_message store ======
    send(10, `(async function() {
        try {
            return new Promise((resolve) => {
                const req = indexedDB.open('zdb_8791610426867118415', 74);
                req.onsuccess = (event) => {
                    const db = event.target.result;
                    const tx = db.transaction(['preview_message'], 'readonly');
                    const store = tx.objectStore('preview_message');
                    const countReq = store.count();
                    countReq.onsuccess = () => {
                        const count = countReq.result;
                        const previews = [];
                        const cursorReq = store.openCursor();
                        let i = 0;
                        cursorReq.onsuccess = (e) => {
                            const cursor = e.target.result;
                            if (cursor && i < 15) {
                                const val = cursor.value;
                                previews.push({
                                    convId: val.convId,
                                    msgId: val.msgId,
                                    messageType: val.messageType,
                                    messageTime: val.messageTime,
                                    status: val.status,
                                    isGroup: val.isGroup,
                                    fromUid: val.fromUid,
                                    toUid: val.toUid,
                                    computedMessage: val.computedMessage ? val.computedMessage.substring(0, 100) : null,
                                    computedIcon: val.computedIcon
                                });
                                i++;
                                cursor.continue();
                            } else {
                                db.close();
                                resolve(JSON.stringify({previewCount: count, previews: previews}));
                            }
                        };
                    };
                };
                req.onerror = () => resolve(JSON.stringify({error: 'Cannot open for previews'}));
            });
        } catch(e) { return JSON.stringify({error: e.message}); }
    })()`);

    // ====== 11. Get ALL object store names from zdb_ ======
    send(11, `(async function() {
        try {
            return new Promise((resolve) => {
                const req = indexedDB.open('zdb_8791610426867118415', 74);
                req.onsuccess = (event) => {
                    const db = event.target.result;
                    const names = Array.from(db.objectStoreNames);
                    db.close();
                    resolve(JSON.stringify({allObjectStores: names}));
                };
                req.onerror = () => resolve(JSON.stringify({error: 'Cannot open'}));
            });
        } catch(e) { return JSON.stringify({error: e.message}); }
    })()`);

    timer = setTimeout(() => { ws.close(); process.exit(0); }, 8000);
});

ws.on('message', (data) => {
    try {
        const msg = JSON.parse(data);
        if (msg.result?.result?.value) {
            const parsed = JSON.parse(msg.result.result.value);
            console.log('========================================');
            console.log('Response #' + msg.id + ':');
            console.log(JSON.stringify(parsed, null, 2));
            done();
        }
        if (msg.error) {
            console.log('Error #' + msg.id + ':', JSON.stringify(msg.error).substring(0, 300));
            done();
        }
    } catch(e) {
        if (data.toString().length < 500) console.log('Raw:', data.toString());
    }
});

ws.on('error', (err) => { console.log('WS Error:', err.message); process.exit(1); });
