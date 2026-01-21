# ✅ Standard Steps to Add a New Backend

## Step 0 — Pick your details

Decide:

* **Subdomain:** `api2.aravinthan.space`
* **WSL port:** `4444` (example)
* **Local test URL:** `http://localhost:4444`

Keep ports unique per service.

---

# ✅ Step 1 — Start backend in WSL

## Express example (port 4444)

In WSL:

```bash
PORT=4444 node index.js
```

Or in code:

```js
app.listen(4444)
```

✅ Verify inside WSL:

```bash
curl http://localhost:4444
```

Must return response.

---

## FastAPI example (port 4444)

```bash
uvicorn app:app --host 0.0.0.0 --port 4444
```

✅ Verify in WSL:

```bash
curl http://localhost:4444
```

---

# ✅ Step 2 — Port-forward WSL → Windows localhost (portproxy)

Run **Admin PowerShell**:

```powershell
$wsl_ip = (wsl hostname -I).Split(" ")[0].Trim()
netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=4444 connectaddress=$wsl_ip connectport=4444
```

✅ Verify from Windows:

```powershell
curl.exe http://127.0.0.1:4444
```

If this fails → Cloudflare won’t work yet.

---

# ✅ Step 3 — Add ingress to your Cloudflare tunnel config

Edit:

`C:\Users\aravi\.cloudflared\config.yml`

Add a new rule:

```yaml
  - hostname: api2.aravinthan.space
    service: http://localhost:4444
```

✅ Validate config:

```powershell
cloudflared tunnel ingress validate
```

---

# ✅ Step 4 — Route DNS for the hostname

Run:

```powershell
cloudflared tunnel route dns windows-core api2.aravinthan.space
```

---

# ✅ Step 5 — Restart cloudflared service

```powershell
cmd.exe /c "sc stop cloudflared"
cmd.exe /c "sc start cloudflared"
```

✅ Confirm tunnel is connected:

```powershell
cloudflared tunnel info windows-core
```

---

# ✅ Step 6 — Test from outside (Mac / phone)

From your Mac:

```bash
curl https://api2.aravinthan.space
```

✅ Should return your backend response.

---

# ✅ Step 7 — (Optional) Protect it using Cloudflare Access

If it’s private/admin:

Cloudflare Zero Trust → Access → Applications → Add → **Self-hosted**

* Hostname: `api2.aravinthan.space`
* Policy: **Admin Only**

⚠️ After this, `curl` may not work without authentication — browser will still work.

---

# ✅ Recommended structure for multiple services

### Example ports + hostnames

| Service     | Subdomain                | Port |
| ----------- | ------------------------ | ---- |
| Express API | `api.aravinthan.space`   | 3333 |
| FastAPI     | `api2.aravinthan.space`  | 4444 |
| Webhooks    | `hooks.aravinthan.space` | 5555 |
| Admin Panel | `admin.aravinthan.space` | 7777 |

---

# 🔥 The “reboot-proof” improvement you should do next

WSL IP changes after reboot → portproxy breaks.

So create a boot script that:
✅ reads WSL IP
✅ recreates all portproxy entries
✅ restarts cloudflared service

If you want, I’ll generate that exact script for your current ports:

* 2222 (ssh)
* 3333 (api)
* plus any new ones

---

# ✅ Your checklist (copy/paste version)

Every new backend:

1. **WSL:** start backend on port `PORT`
2. **Windows:** `curl.exe http://127.0.0.1:PORT`
3. Add hostname in `config.yml`
4. `cloudflared tunnel route dns windows-core <hostname>`
5. restart cloudflared service
6. test from Mac

---

If you tell me the next backend you want to add (Express/FastAPI + desired subdomain), I’ll give you the **exact port + ingress snippet + portproxy command** for it.
