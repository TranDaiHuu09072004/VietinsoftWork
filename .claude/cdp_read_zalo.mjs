import WebSocket from 'ws';

const PAGE_ID = '290B2E4CCC5E76C33C7AF2FCA772B880';
const ws = new WebSocket(`ws://localhost:9222/devtools/page/${PAGE_ID}`);

const results = {};

function send(id, expression) {
    ws.send(JSON.stringify({id, method: 'Runtime.evaluate', params: {expression, returnByValue: true}}));
}

ws.on('open', () => {
    // 1. Basic page info + DOM structure
    send(1, `(function() {
        const getText = (el) => el?.innerText?.trim()?.substring(0, 200) || '';

        // Find main layout sections
        const sections = [];
        document.querySelectorAll('section, main, nav, aside, header, [id*=app], [class*=app], [class*=layout], [class*=container]').forEach(el => {
            const text = getText(el);
            if (text && text.length > 5) {
                sections.push({tag: el.tagName, id: el.id?.substring(0,100), class: el.className?.substring(0,200), text: text.substring(0,150)});
            }
        });

        // Get all visible text grouped
        const bodyText = document.body?.innerText?.substring(0, 5000) || '';

        // Get elements with useful text
        const headings = Array.from(document.querySelectorAll('h1,h2,h3,h4')).map(e => ({tag: e.tagName, text: e.innerText?.trim()?.substring(0,150)})).filter(t => t.text);

        return JSON.stringify({
            title: document.title,
            url: window.location.href,
            topSections: sections.slice(0, 25),
            headings: headings.slice(0, 20),
            totalElements: { div: document.querySelectorAll('div').length, span: document.querySelectorAll('span').length, img: document.querySelectorAll('img').length, input: document.querySelectorAll('input').length, button: document.querySelectorAll('button').length }
        });
    })()`);

    // 2. Chat list / conversation list
    send(2, `(function() {
        const items = [];
        // Try various selectors for conversation items
        const selectors = ['[class*=conv-item]', '[class*=chat-item]', '[class*=contact-item]', '[class*=conversation]', '[data-id]', '[class*=list-item]', '[class*=friend-item]'];
        for (const sel of selectors) {
            document.querySelectorAll(sel).forEach(el => {
                const text = el.innerText?.trim()?.substring(0, 200);
                if (text && text.length > 2) items.push({selector: sel, text: text, className: el.className?.substring(0,150)});
            });
        }
        return JSON.stringify({convItems: items.slice(0, 40)});
    })()`);

    // 3. Input area / message composer
    send(3, `(function() {
        const inputs = Array.from(document.querySelectorAll('input, textarea, [contenteditable=true], [role=textbox], [class*=input], [class*=composer], [class*=editor], [class*=rich-input], [class*=chat-input]')).map(el => ({
            tag: el.tagName,
            class: el.className?.substring(0,200),
            placeholder: el.placeholder || el.getAttribute('aria-label') || '',
            role: el.getAttribute('role') || '',
            isContentEditable: el.isContentEditable
        }));
        return JSON.stringify({messageInputs: inputs.slice(0, 10)});
    })()`);

    // 4. toolbar/actions
    send(4, `(function() {
        const tools = Array.from(document.querySelectorAll('[class*=toolbar], [class*=tool], [class*=action], [class*=icon-btn], [class*=icon], button[title], button[aria-label], [class*=right-layout], [class*=left-layout]')).map(el => ({
            tag: el.tagName,
            class: el.className?.substring(0,200),
            text: el.innerText?.trim()?.substring(0,100) || el.title || el.getAttribute('aria-label') || '',
            title: el.title || ''
        }));
        return JSON.stringify({toolbar: tools.slice(0, 30)});
    })()`);

    // 5. localStorage keys related to socket & app
    send(5, `(function() {
        const keys = Object.keys(localStorage).filter(k => k.startsWith('0_') || k.startsWith('sh_') || k.includes('sock') || k.includes('msg') || k.includes('user'));
        return JSON.stringify({localStorageKeys: keys.slice(0, 50)});
    })()`);

    // 6. WebSocket connections (via Performance API)
    send(6, `(function() {
        const resources = performance.getEntriesByType('resource').filter(r => r.name.includes('ws') || r.name.includes('socket') || r.name.includes('wpa')).map(r => r.name).slice(0, 10);
        return JSON.stringify({socketResources: resources});
    })()`);

    // 7. What the page is actually showing - get the MAIN visible text
    send(7, `(function() {
        // Remove hidden elements
        const clone = document.body.cloneNode(true);
        clone.querySelectorAll('script, style, [aria-hidden=true], [hidden]').forEach(e => e.remove());
        const visibleText = clone.innerText?.substring(0, 8000) || '';
        return JSON.stringify({visibleText: visibleText});
    })()`);

    setTimeout(() => { ws.close(); process.exit(0); }, 3000);
});

ws.on('message', (data) => {
    try {
        const msg = JSON.parse(data);
        if (msg.result?.result?.value) {
            const parsed = JSON.parse(msg.result.result.value);
            const id = msg.id;
            results[id] = parsed;
            console.log('--- Response', id, '---');
            console.log(JSON.stringify(parsed, null, 2).substring(0, 4000));
        }
        if (msg.error) console.log('Error', id, ':', JSON.stringify(msg.error).substring(0, 500));
    } catch(e) {
        if (data.toString().length < 500) console.log('Raw:', data.toString());
    }
});

ws.on('error', (err) => { console.log('WS Error:', err.message); process.exit(1); });
