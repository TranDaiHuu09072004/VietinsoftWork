import WebSocket from 'ws';

const PAGE_ID = '290B2E4CCC5E76C33C7AF2FCA772B880';
const ws = new WebSocket(`ws://localhost:9222/devtools/page/${PAGE_ID}`);

ws.on('open', () => {
    // Step 1: Trigger IndexedDB read into window.__r
    const expr1 = `(function() {
        var R = window.__r = {};
        var dbReq = indexedDB.open("zdb_2303003661207200696", 74);
        dbReq.onsuccess = function(ev) {
            var db = ev.target.result;

            // 1. Read 3 messages
            var tx1 = db.transaction(["message"], "readonly");
            var msgStore = tx1.objectStore("message");
            msgStore.count().onsuccess = function() { R.msgCount = this.result; };
            var msgCursor = msgStore.openCursor(null, "prev");
            R.msgs = [];
            msgCursor.onsuccess = function(ce) {
                var c = ce.target.result;
                if (c && R.msgs.length < 5) {
                    var v = c.value;
                    R.msgs.push({
                        msgId: v.msgId, msgType: v.msgType, cmd: v.cmd,
                        originMsgType: v.originMsgType, status: v.status,
                        fromUid: v.fromUid, toUid: v.toUid,
                        sendDttm: v.sendDttm, src: v.src,
                        syncFromMobile: v.syncFromMobile,
                        cliMsgId: v.cliMsgId, e2eeStatus: v.e2eeStatus,
                        msgEncLen: v.message ? v.message.length : 0,
                        ttl: v.ttl, actionId: v.actionId,
                        hasMentions: v.mentions ? v.mentions.length : 0,
                        hasQuote: !!v.quote,
                        properties: v.properties ? Object.keys(v.properties) : null
                    });
                    c.continue();
                }
            };

            // 2. Read 5 conversations
            var tx2 = db.transaction(["conversation"], "readonly");
            var convStore = tx2.objectStore("conversation");
            convStore.count().onsuccess = function() { R.convCount = this.result; };
            var convCursor = convStore.openCursor();
            R.convs = [];
            convCursor.onsuccess = function(ce) {
                var c = ce.target.result;
                if (c && R.convs.length < 5) {
                    var v = c.value;
                    R.convs.push({
                        userId: v.userId, isGroup: v.isGroup,
                        numMsg: v.numMsg, respondedByMe: v.respondedByMe,
                        pinned: v.pinned, label: v.label
                    });
                    c.continue();
                }
            };

            // 3. Read 5 preview messages
            var tx3 = db.transaction(["preview_message"], "readonly");
            var pvStore = tx3.objectStore("preview_message");
            pvStore.count().onsuccess = function() { R.pvCount = this.result; };
            var pvCursor = pvStore.openCursor();
            R.previews = [];
            pvCursor.onsuccess = function(ce) {
                var c = ce.target.result;
                if (c && R.previews.length < 5) {
                    var v = c.value;
                    R.previews.push({
                        convId: v.convId, msgId: v.msgId,
                        messageType: v.messageType, status: v.status,
                        fromUid: v.fromUid, toUid: v.toUid,
                        isGroup: v.isGroup, messageTime: v.messageTime,
                        computedMessage: v.computedMessage ? v.computedMessage.substring(0, 80) : null,
                        computedIcon: v.computedIcon
                    });
                    c.continue();
                }
            };

            // 4. Read e2ee sessions
            var tx4 = db.transaction(["e2ee_session"], "readonly");
            var e2Store = tx4.objectStore("e2ee_session");
            e2Store.count().onsuccess = function() { R.e2eeSessionCount = this.result; };
            var e2Cursor = e2Store.openCursor();
            R.e2eeSessions = [];
            e2Cursor.onsuccess = function(ce) {
                var c = ce.target.result;
                if (c && R.e2eeSessions.length < 3) {
                    var v = c.value;
                    R.e2eeSessions.push({
                        userId: v.userId, deviceId: v.deviceId,
                        sessionVersion: v.sessionVersion, hasRecord: !!v.record
                    });
                    c.continue();
                }
            };

            // Close DB after a delay to let all transactions complete
            setTimeout(function() { db.close(); R._done = true; }, 2000);
        };
        dbReq.onerror = function() { R._error = 'Cannot open zdb_'; };
        return "triggered";
    })()`;

    ws.send(JSON.stringify({id: 1, method: 'Runtime.evaluate', params: {expression: expr1, returnByValue: true}}));

    // Step 2: Read socket state
    ws.send(JSON.stringify({id: 2, method: 'Runtime.evaluate', params: {
        expression: `JSON.stringify({
            sockMsg: localStorage.getItem('0_sock_msg'),
            lsMsg: localStorage.getItem('0_lsmsg'),
            sockAc: localStorage.getItem('0_sock_ac'),
            sockCtrl: localStorage.getItem('0_sock_ctrl'),
            verify510: localStorage.getItem('0_sock_verfy_510_1'),
            verify511: localStorage.getItem('0_sock_verfy_511_1'),
            sockCnted: localStorage.getItem('sh_sock_cnted'),
            sufficientMsgTs: localStorage.getItem('0_sufficient_msg_ts'),
            lrMsg: localStorage.getItem('0_l_r_msg'),
            e2eeEnable: localStorage.getItem('0_e2eenable')
        })`, returnByValue: true
    }}));

    setTimeout(() => { ws.close(); process.exit(0); }, 5000);
});

// Poll for async results
setTimeout(() => {
    ws.send(JSON.stringify({id: 100, method: 'Runtime.evaluate', params: {
        expression: 'JSON.stringify(window.__r || {status: "not ready"})',
        returnByValue: true
    }}));
}, 3000);

ws.on('message', (data) => {
    try {
        const msg = JSON.parse(data);
        const id = msg.id;

        if (msg.result?.result?.value) {
            const val = msg.result.result.value;
            if (id === 1) {
                console.log('=== Triggered IndexedDB read: ' + val + ' ===');
            } else if (id === 2) {
                console.log('=== SOCKET STATE (localStorage) ===');
                const parsed = JSON.parse(val);
                console.log(JSON.stringify(parsed, null, 2));
            } else if (id >= 100) {
                console.log('=== INDEXEDDB DATA ===');
                const parsed = JSON.parse(val);
                if (parsed.msgCount !== undefined) console.log('Message count:', parsed.msgCount);
                if (parsed.convCount !== undefined) console.log('Conversation count:', parsed.convCount);
                if (parsed.pvCount !== undefined) console.log('Preview count:', parsed.pvCount);
                if (parsed.e2eeSessionCount !== undefined) console.log('E2EE session count:', parsed.e2eeSessionCount);
                if (parsed.msgs && parsed.msgs.length > 0) {
                    console.log('\n--- Messages (' + parsed.msgs.length + ') ---');
                    parsed.msgs.forEach((m, i) => console.log(JSON.stringify(m, null, 2)));
                }
                if (parsed.convs && parsed.convs.length > 0) {
                    console.log('\n--- Conversations (' + parsed.convs.length + ') ---');
                    parsed.convs.forEach((c, i) => console.log(JSON.stringify(c)));
                }
                if (parsed.previews && parsed.previews.length > 0) {
                    console.log('\n--- Preview Messages (' + parsed.previews.length + ') ---');
                    parsed.previews.forEach((p, i) => console.log(JSON.stringify(p)));
                }
                if (parsed.e2eeSessions && parsed.e2eeSessions.length > 0) {
                    console.log('\n--- E2EE Sessions (' + parsed.e2eeSessions.length + ') ---');
                    parsed.e2eeSessions.forEach((s, i) => console.log(JSON.stringify(s)));
                }
            }
        }
        if (msg.error) {
            console.log('Error #' + id + ':', JSON.stringify(msg.error).substring(0, 400));
        }
    } catch(e) {
        // Ignore parse errors
    }
});

ws.on('error', (err) => { console.log('WS Error:', err.message); process.exit(1); });
