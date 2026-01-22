Alright — I’ll explain this **from first principles**, meaning we’ll build the whole thing up from zero, layer by layer, until the entire architecture makes intuitive sense.

The goal of your document is:

✅ **Host multiple services on ONE laptop**
✅ Some services run on **Windows** (Jellyfin)
✅ Some services run inside **WSL2 Linux** (SSH, backend apps, Caddy)
✅ Expose them to the internet securely using **Cloudflare Tunnel**
✅ **Without** port forwarding, static IPs, or router changes
✅ Keep it stable even though **WSL IP keeps changing**

---

# 0) What you’re *really* doing (the simplest mental model)

Imagine your laptop is a **house**.

Inside the house you have **two apartments**:

### Apartment A: Windows

* Jellyfin lives here
* It has direct access to your real home Wi-Fi network

### Apartment B: WSL2 Linux

* Your SSH server, Node/Python APIs, Caddy live here
* It’s like a **virtual apartment with its own internal network**, kind of hidden

Now you want visitors from the internet to reach services in either apartment, safely.

But there are problems:

* Your home IP changes
* Your router blocks inbound traffic
* WSL2 has a changing internal IP
* You don’t want to open ports

So instead of letting people “enter your house from outside”, you do something clever:

✅ You make your laptop **call out to Cloudflare** and keep a tunnel open.

This is the key idea.

---

# 1) First principles: How internet access normally works

## 1.1 What happens in normal self-hosting?

If someone on the internet wants your Jellyfin:

They need to reach:

`your-public-ip:8096`

That requires:

* Your public IP must be reachable
* Your router must forward port `8096` to your laptop
* Your laptop firewall must allow it

This is called **inbound hosting**.

### Why is inbound hosting hard at home?

Because of NAT (Network Address Translation).

Your router is like a receptionist:

* Internet knocks on your public IP
* Router doesn’t know which device should receive that knock
* Unless you manually configure port forwarding

Also:

* Your ISP might change your IP
* CGNAT might block you completely

So you need a “no-inbound-ports” method.

---

# 2) First principles: What Cloudflare Tunnel actually is

## 2.1 The trick: reverse the direction of connection

Instead of internet → your laptop
You do laptop → Cloudflare

Your laptop makes an **outbound connection**, like opening WhatsApp.

Outbound connections are always allowed.

So you run a small daemon:

✅ `cloudflared`

It does:

1. Your laptop opens a secure connection to Cloudflare
2. Cloudflare keeps that connection alive
3. When someone hits your domain, Cloudflare sends that request down that existing connection

So Cloudflare Tunnel is basically:

> “A permanent outbound VPN-like connection that Cloudflare can send traffic through.”

### What does this buy you?

* No port forwarding
* No static IP
* No exposing router
* Cloudflare becomes your public entry point

---

# 3) Now the big challenge: Windows + WSL2 = two networks

Even though it’s “one laptop”, networking-wise it behaves like **two machines**.

## 3.1 Windows Host networking (normal)

Windows is on your LAN:

* IP like `192.168.1.50`
* Visible to your router
* Can talk to internet normally

## 3.2 WSL2 networking (virtualized)

WSL2 runs as a Hyper-V VM.

It gets an internal IP like:

* `172.28.154.21` (example)
* This IP changes when WSL restarts
* The VM is behind a virtual switch NAT created by Windows

So inside your laptop:

* Windows has stable LAN IP
* WSL has unstable private virtual IP

This is **exactly like** having a Docker VM or VirtualBox VM.

---

# 4) The simplest “local routing” question

If Cloudflared runs on Windows and gets an incoming request:

✅ How does it reach services in Windows and WSL?

### 4.1 Windows services are easy

Jellyfin runs on Windows:

`localhost:8096`

So cloudflared can just forward to it locally.

### 4.2 WSL services are tricky

Your backend or SSH runs inside Linux.

From Windows, the VM is *not directly* the same network.

So we need a “bridge”.

And your document describes **two different bridging strategies**:

---

# 5) Bridge Strategy A: Windows “localhost forwarding” (automatic WSL bridge)

Windows has a nice feature:

If WSL is listening on `0.0.0.0:<port>`

Windows automatically forwards that port to WSL.

Meaning:

If your Node app runs in WSL and listens on:

`0.0.0.0:3000`

Then Windows can do:

`curl http://localhost:3000`

and it will reach WSL.

### Why does this work?

Because Windows detects the WSL port and creates a loopback proxy.

**But this only works if your app binds to `0.0.0.0` in Linux.**

---

## 5.1 Why `0.0.0.0` matters (first principles)

### `127.0.0.1` means:

> “Only accept connections coming from inside the same machine/container namespace.”

Inside WSL, `127.0.0.1` means:

* Linux itself only

Windows is “outside” that Linux namespace.

So Windows can’t reach it.

### `0.0.0.0` means:

> “Listen on all network interfaces (including the virtual NIC).”

So Windows can connect via the virtual network path.

That’s why the doc screams:

✅ MUST listen on `0.0.0.0`

---

# 6) Bridge Strategy B: Windows PortProxy (manual bridge that survives changes)

In your final system, you introduced:

✅ `netsh interface portproxy`

This is a Windows feature that says:

> “When someone hits Windows port X, forward it to another IP:port.”

Example:

* Windows listens on `127.0.0.1:2222`
* Forward to WSL’s IP:2222

So Cloudflared always points to **Windows localhost**, and Windows forwards into WSL.

This is more explicit and controllable than the “automatic localhost forwarding”.

---

## 6.1 Why do you need PortProxy at all?

Because **WSL IP changes** every reboot.

Even if Cloudflared config says:

`service: ssh://localhost:2222`

It doesn’t know WSL IP.

So the stable setup becomes:

### Stable endpoint for Cloudflared:

✅ `localhost:2222`
✅ `localhost:8088`

### PortProxy maps them dynamically to the current WSL IP

So you run a script after reboot that:

1. Gets the current WSL IP (`wsl hostname -I`)
2. Rewrites portproxy rules to point to the new IP

That’s why the “After restart script” exists.

---

# 7) Why Caddy exists inside WSL

Now that Cloudflare traffic can reach WSL through portproxy, you have another problem:

You might want multiple services inside Linux:

* Node app on 3333
* FastAPI on 8000
* Something else later…

You *could* expose all of them as separate subdomains in Cloudflare, but that becomes annoying.

So you use Caddy as an **internal reverse proxy**.

Cloudflare always forwards:

✅ `api.aravinthan.space` → `localhost:8088`

Then:

Windows `8088` → PortProxy → WSL `8088` → Caddy

Then Caddy routes by path:

* `/api1/*` → Node:3333
* `/fastapi/*` → FastAPI:8000

So **Caddy is your “router inside Linux”**.

Cloudflare is only doing subdomain-level routing.
Caddy is doing service-level routing.

---

# 8) The Cloudflare config.yml ingress rules (what they truly mean)

This is the heart:

```yaml
ingress:
  - hostname: jellyfin.aravinthan.space
    service: http://localhost:8096

  - hostname: ssh.aravinthan.space
    service: ssh://localhost:2222

  - hostname: api.aravinthan.space
    service: http://localhost:8088
```

First principles view:

Cloudflared is acting like an **L7/L4 reverse proxy**.

When a request comes in, it checks the hostname:

### If hostname == jellyfin…

send to `localhost:8096`

### If hostname == ssh…

send TCP to `localhost:2222`

### If hostname == api…

send to `localhost:8088`

And Windows will handle whether those ports live in Windows or forwarded to WSL.

---

# 9) DNS routing (why “route dns” exists)

When you run:

```powershell
cloudflared tunnel route dns laptop-tunnel jellyfin.aravinthan.space
```

What happens conceptually:

* Cloudflare DNS creates a CNAME that points the hostname to your tunnel UUID
* So Cloudflare knows:

> “If someone requests jellyfin.aravinthan.space, route it into this tunnel.”

This is *not* pointing to your laptop IP.

It points to **Cloudflare’s internal tunnel mapping system**.

So even if your home IP changes, the hostname still works.

---

# 10) SSH through Cloudflare (why you need cloudflared on client)

SSH normally works like:

`ssh user@ip`

But here:

* You don’t know the IP
* Cloudflare doesn’t “open port 22 publicly” like normal hosting
* Cloudflare Access wants to verify identity

So your SSH client must connect through Cloudflare as a proxy.

That’s why you do:

```sshconfig
ProxyCommand cloudflared access ssh --hostname %h
```

This means:

1. SSH wants to connect to ssh.aravinthan.space
2. Instead of direct TCP, it launches cloudflared
3. cloudflared negotiates with Cloudflare Edge
4. Cloudflare applies Access policy
5. The tunnel is used to reach your laptop

So cloudflared becomes the “transport layer” for SSH.

---

# 11) Cloudflare Access = Identity Firewall

Cloudflare Tunnel hides your IP, but it doesn’t automatically restrict *who* can access.

If you expose `api.aravinthan.space` publicly without Access:

Anyone can hit it.

So Access adds a new layer:

✅ **Authentication before traffic is even forwarded**

Meaning:

* Request hits Cloudflare Edge
* Cloudflare checks: “Are you allowed?”
* Only then it forwards down the tunnel

It becomes like a “bouncer at the entrance”.

That’s why it’s called **Zero Trust**:

> never trust the network, always verify identity.

---

# 12) The service conflict and your Windows logs (the SC error)

You hit:

`FAILED 1056: instance already running`

That’s because:

### When you install cloudflared as a Windows Service:

* Windows boots → service starts cloudflared automatically

Then if you manually run:

`cloudflared tunnel run ...`

you start a second process, which conflicts.

Tunnel UUID can only have a limited number of connectors (and duplicate connectors cause issues).

So rule of thumb:

✅ If installed as a service → manage with `Start-Service / Restart-Service`
❌ Don’t manually run the tunnel command unless service is removed

---

# 13) Entire request flow (end-to-end)

Let’s take one example:

### You open: `https://api.aravinthan.space/fastapi/docs`

Full flow:

1. Your browser requests DNS for `api.aravinthan.space`
2. DNS points to Cloudflare tunnel mapping
3. Request goes to Cloudflare Edge
4. Cloudflare Access checks identity (if enabled)
5. Cloudflare sends HTTP request down tunnel to your laptop
6. `cloudflared` on Windows receives it
7. config.yml sees hostname `api.aravinthan.space`
8. forwards to `localhost:8088`
9. Windows portproxy forwards to WSL IP `172.x.x.x:8088`
10. Caddy in WSL receives it
11. Caddy sees path `/fastapi/*`
12. routes to `localhost:8000` inside WSL
13. FastAPI responds
14. Response goes all the way back via tunnel to your device

That’s the whole machine.

---

# 14) Why shutdown breaks everything

Cloudflare Tunnel is outbound.

If laptop is off:

* no outbound connection exists
* Cloudflare has nowhere to forward to
* you get 502 Bad Gateway

That’s not a bug — it’s a fundamental law of the system:

✅ “No tunnel running” = “no service reachable”

So availability depends on:

* laptop staying on
* cloudflared service running
* WSL running (for WSL services)
* portproxy updated after reboot

---

# 15) The architecture in one sentence (pure essence)

**Cloudflare Tunnel brings internet traffic into Windows via an outbound tunnel, Windows routes it either to Windows services directly or forwards it into WSL via portproxy, and WSL uses Caddy to route to multiple backend apps — with Cloudflare Access acting as the identity firewall at the edge.**

---

Below is a **full start-to-finish tutorial** of **everything that was done**, with **every command**, why we ran it, and how to verify each stage.

This is written like: *“fresh Windows laptop → final working architecture”*.

---

# ✅ Goal (What you end up with)

You will have these working publicly:

* `https://jellyfin.aravinthan.space` → Jellyfin on **Windows**
* `https://api.aravinthan.space` → WSL2 services via **Caddy reverse proxy**
* `ssh home-wsl` → SSH into **WSL2** securely through **Cloudflare Access**
* No port forwarding
* No static IP
* Protected by Cloudflare Zero Trust

---

# Part 0 — Pre-checks (to avoid pain later)

## 0.1 Ensure WSL2 exists and is working

Open PowerShell:

```powershell
wsl --status
wsl -l -v
```

Expected:

* Default version: 2
* Your distro shows running version 2

If your distro is not WSL2:

```powershell
wsl --set-version <DistroName> 2
```

Example:

```powershell
wsl --set-version Ubuntu 2
```

---

# Part 1 — Jellyfin on Windows (Service 1)

## 1.1 Verify Jellyfin is running

On Windows browser:

✅ Open:

`http://localhost:8096`

If it loads, Jellyfin is good.

Or verify from PowerShell:

```powershell
curl http://localhost:8096
```

If it responds with HTML, it’s reachable.

---

# Part 2 — Backend inside WSL2 (Service 2)

## 2.1 Enter WSL

```powershell
wsl
```

You are now inside Linux.

---

## 2.2 Example Node backend (must bind to 0.0.0.0)

Example Node Express listen:

```js
app.listen(3333, "0.0.0.0", () => console.log("running"));
```

Run it:

```bash
node index.js
```

Or:

```bash
npm run start
```

---

## 2.3 Verify Windows can reach WSL backend

Back on **Windows PowerShell**:

```powershell
curl http://localhost:3333
```

If this works → Windows ↔ WSL bridge is working.

If it fails → your app is probably bound to `127.0.0.1`.

---

# Part 3 — SSH inside WSL2 on port 2222 (Service 3)

## 3.1 Install and enable OpenSSH in WSL

Inside WSL:

```bash
sudo apt update
sudo apt install openssh-server -y
```

Enable it:

```bash
sudo systemctl enable ssh
```

Start it:

```bash
sudo systemctl start ssh
```

Check status:

```bash
sudo systemctl status ssh
```

---

## 3.2 Change SSH port to 2222

Edit config:

```bash
sudo nano /etc/ssh/sshd_config
```

Ensure these lines exist:

```text
Port 2222
ListenAddress 0.0.0.0
PasswordAuthentication yes
```

Restart SSH:

```bash
sudo systemctl restart ssh
```

---

## 3.3 Verify SSH is listening

Inside WSL:

```bash
ss -ltnp | grep 2222
```

Expected output shows `sshd` listening on `0.0.0.0:2222`.

---

## 3.4 Verify Windows can SSH into WSL

Back in Windows PowerShell:

```powershell
ssh -p 2222 <your_wsl_username>@localhost
```

If it logs in → your WSL SSH is accessible from Windows.

✅ Perfect.

---

# Part 4 — Install Caddy in WSL (API gateway / router)

This is what lets you expose multiple services behind **one port** (8088).

## 4.1 Install Caddy

Inside WSL:

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf https://dl.cloudsmith.io/public/caddy/stable/gpg.key | sudo tee /usr/share/keyrings/caddy-stable-archive-keyring.gpg > /dev/null
curl -1sLf https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy -y
```

Enable + start:

```bash
sudo systemctl enable caddy
sudo systemctl start caddy
```

Check status:

```bash
sudo systemctl status caddy
```

---

## 4.2 Configure Caddy to listen on port 8088

Edit file:

```bash
sudo nano /etc/caddy/Caddyfile
```

Put this:

```caddy
:8088 {
    handle /health {
        respond "ok" 200
    }

    handle /api1/* {
        reverse_proxy localhost:3333
    }
}
```

Reload:

```bash
sudo systemctl reload caddy
```

---

## 4.3 Verify Caddy works inside WSL

Inside WSL:

```bash
curl http://localhost:8088/health
```

Expected:

```text
ok
```

---

# Part 5 — Windows PortProxy (the critical glue)

This is needed because **WSL IP changes** after reboot.

We will make Windows listen on stable ports and forward to WSL’s dynamic IP.

---

## 5.1 Get WSL’s current IP address (from Windows)

In PowerShell:

```powershell
wsl hostname -I
```

Example output:

```text
172.28.154.21
```

Take the first IP.

---

## 5.2 Reset existing portproxy rules (clean slate)

Run as admin PowerShell:

```powershell
netsh interface portproxy reset
```

---

## 5.3 Add PortProxy rules

### SSH forward

Windows `localhost:2222` → WSL `172.x.x.x:2222`

```powershell
netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=2222 connectaddress=<WSL_IP> connectport=2222
```

### API gateway forward

Windows `localhost:8088` → WSL `172.x.x.x:8088`

```powershell
netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=8088 connectaddress=<WSL_IP> connectport=8088
```

Example:

```powershell
netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=2222 connectaddress=172.28.154.21 connectport=2222
netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=8088 connectaddress=172.28.154.21 connectport=8088
```

---

## 5.4 Verify portproxy rules

```powershell
netsh interface portproxy show all
```

Expected: 2 rules, ports 2222 and 8088.

---

## 5.5 Verify from Windows

### Check Caddy through Windows:

```powershell
curl http://localhost:8088/health
```

Expected:

```text
ok
```

### Check SSH through Windows:

```powershell
ssh -p 2222 <username>@localhost
```

✅ If both succeed → glue is perfect.

---

# Part 6 — Install Cloudflared on Windows

## 6.1 Install using winget

Open PowerShell **as Administrator**:

```powershell
winget install --id Cloudflare.cloudflared
```

Verify:

```powershell
cloudflared --version
```

---

## 6.2 Authenticate cloudflared

```powershell
cloudflared tunnel login
```

This opens browser → choose domain → approve.

It creates:

📌 `C:\Users\<USER>\.cloudflared\cert.pem`

---

## 6.3 Create tunnel

```powershell
cloudflared tunnel create windows-core
```

Output includes a UUID like:

`06cf80e4-69e9-4327-b814-a8c4860546aa`

Also creates:

📌 `C:\Users\<USER>\.cloudflared\<UUID>.json`

---

# Part 7 — Map subdomains to the tunnel

Run these:

```powershell
cloudflared tunnel route dns windows-core jellyfin.aravinthan.space
cloudflared tunnel route dns windows-core api.aravinthan.space
cloudflared tunnel route dns windows-core ssh.aravinthan.space
```

This creates DNS records in Cloudflare automatically.

---

# Part 8 — Create Cloudflare Tunnel config.yml

Create:

📌 `C:\Users\<USER>\.cloudflared\config.yml`

Paste:

```yaml
tunnel: 06cf80e4-69e9-4327-b814-a8c4860546aa
credentials-file: C:\Users\<USER>\.cloudflared\06cf80e4-69e9-4327-b814-a8c4860546aa.json

ingress:
  - hostname: jellyfin.aravinthan.space
    service: http://localhost:8096

  - hostname: ssh.aravinthan.space
    service: ssh://localhost:2222

  - hostname: api.aravinthan.space
    service: http://localhost:8088

  - service: http_status:404
```

---

## 8.1 Validate config

```powershell
cloudflared tunnel ingress validate
```

Expected: no errors.

---

# Part 9 — Run Cloudflared as a Windows service

## 9.1 Install service

```powershell
cloudflared service install
```

## 9.2 Start service

```powershell
cloudflared service start
```

Or:

```powershell
Start-Service cloudflared
```

## 9.3 Check service status

```powershell
Get-Service cloudflared
```

Expected: Running ✅

---

# Part 10 — The restart problem (WSL IP changes)

After a reboot:

* WSL gets new IP
* Portproxy rules still point to OLD IP
* SSH + API break
* Jellyfin still works

So you must update portproxy after restart.

---

# Part 11 — Create the restart automation script

Create file:

📌 `C:\Scripts\Update-WSL-Bridge.ps1`

Paste:

```powershell
$wsl_ip = (wsl hostname -I).Split(" ")[0].Trim()

if (-not $wsl_ip) {
    Write-Error "WSL is not running or IP could not be determined."
    exit
}

Write-Host "New WSL IP Detected: $wsl_ip"

netsh interface portproxy reset

netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=2222 connectaddress=$wsl_ip connectport=2222
netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=8088 connectaddress=$wsl_ip connectport=8088

$cf_status = (Get-Service cloudflared).Status
if ($cf_status -ne "Running") {
    Start-Service cloudflared
}

Write-Host "Bridge Updated Successfully."
netsh interface portproxy show all
```

Run it as Administrator:

```powershell
C:\Scripts\Update-WSL-Bridge.ps1
```

---

# Part 12 — SSH access from MacBook (client setup)

## 12.1 Install cloudflared

```bash
brew install cloudflared
```

## 12.2 Add SSH profile

Edit:

```bash
nano ~/.ssh/config
```

Add:

```text
Host home-wsl
  HostName ssh.aravinthan.space
  User <YOUR_WSL_USERNAME>
  ProxyCommand /opt/homebrew/bin/cloudflared access ssh --hostname %h
```

Connect:

```bash
ssh home-wsl
```

---

# Part 13 — Final health checks (all commands)

## ✅ On Windows

### Cloudflared service alive

```powershell
Get-Service cloudflared
```

### Portproxy correct

```powershell
netsh interface portproxy show all
```

### Jellyfin local

```powershell
curl http://localhost:8096
```

### API gateway local

```powershell
curl http://localhost:8088/health
```

---

## ✅ In WSL

### ssh + caddy running

```bash
sudo systemctl status ssh
sudo systemctl status caddy
```

### check ports open

```bash
ss -ltnp
```

Expected ports:

* `2222` ssh
* `8088` caddy
* `3333` node app

---

# ✅ What you do after every restart (the daily routine)

1. Login to Windows
2. Start WSL once:

   ```powershell
   wsl
   ```
3. Run bridge update script (Admin):

   ```powershell
   C:\Scripts\Update-WSL-Bridge.ps1
   ```
4. Ensure services inside WSL are running:

   ```bash
   sudo systemctl start ssh
   sudo systemctl start caddy
   npm run start
   ```
5. Done.

---

If you want, I can also give you a **one-click “startup” solution** using **Task Scheduler** so the script runs automatically after login (with admin rights) and you never have to manually run it again.
