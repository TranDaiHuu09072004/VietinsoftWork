# email_batching_guide: MS Graph API Email Batching

Reference: [23_CallAPI.md](23_CallAPI.md) (AJAX calling conventions).

The system supports batch email dispatching via Microsoft Graph API using the stored procedure `sp_EmailSendingByDuc`. This allows sending up to 20 distinct emails (different subjects, bodies, and recipients) in a single API roundtrip.

---

## 1. Client-Side Implementation (JavaScript)
Assemble email objects into a flat array, convert it to a JSON string, and transmit it via `AjaxHPAParadise`.

### 1.1. Data Object Schema
```javascript
let batchJsonArray = [];

batchJsonArray.push({
    TemplateName: "Email_Template_Code",  -- Tracking name
    EmployeeID: "EMP_ID",                -- Associated employee log
    ToEmails: "recipient@domain.com",    -- Recipients (semi-colon ';' delimited)
    CcEmails: "cc@domain.com",           -- CC (optional)
    BccEmails: "bcc@domain.com",         -- BCC (optional)
    Subject: "Email Title",              -- Subject line
    BodyContent: "HTML_Body_Or_Base64",  -- Body content
    IsBase64: 0                          -- 1 if BodyContent is Base64 UTF-16LE, 0 if raw HTML
});
```

### 1.2. Transmitting the Batch request
```javascript
AjaxHPAParadise({
    data: {
        sp_EmailSendingByDuc: [
            "LanguageID", window.LanguageID || "VN",
            "BatchJson", JSON.stringify(batchJsonArray)
        ]
    },
    success: function (res) {
        let parseRes = typeof res === "string" ? JSON.parse(res) : res;
        const resultRows = parseRes.sp_EmailSendingByDuc || [];
        
        resultRows.forEach((row) => {
            if (row.Result == 1) {
                console.log(`Email ID ${row.Id} sent.`);
            } else {
                console.error(`Email ID ${row.Id} failed: ${row.ErrorMessage}`);
            }
        });
    }
});
```
*Note*: If the size exceeds 20 items, slice the array into chunks of 20 elements and dispatch them iteratively.

---

## 2. Server-Side Execution (SQL Server)
The procedure `sp_EmailSendingByDuc` automatically detects the `@BatchJson` parameter.
1.  **Parsing**: Reads the JSON input via `OPENJSON(@BatchJson)`.
2.  **Aggregation**: Serializes parameters into a MS Graph batch payload block.
3.  **Transmission**: Dispatches a single HTTP request using `ss_RequestHttp` to: `https://graph.microsoft.com/v1.0/$batch`.
4.  **Logging & Return**: Inserts success/error logs into `tblEmailList` and returns an evaluation table containing columns `Id`, `Result`, and `ErrorMessage`.
*Backward Compatibility*: Legacy single-item parameter signatures (`@ToEmails`, `@Subject`, `@BodyContent`) remain active as execution fallback if `@BatchJson` is omitted.

---

## 3. Client-Side Chunking & Retry Workflow
```javascript
async function sendEmails(emailList) {
    const LIMIT = 20;
    let results = [];
    
    for (let i = 0; i < emailList.length; i += LIMIT) {
        let chunk = emailList.slice(i, i + LIMIT);
        let res = await sendChunkPromise(chunk); // AJAX wrapped in Promise
        results.push(...res);
    }
    
    let failed = results.filter(r => !r.success).map(r => r.item);
    if (failed.length > 0) {
        document.getElementById("btnRetry").onclick = () => sendEmails(failed); // Recursively retry failed items
    }
}
```
