# TKT-004 — Workstation cannot resolve external websites

**Devices:** LVM-CL01 and LVM-DC01  
**Status:** DNS issue resolved

**Problem:** The workstation could find the AD domain, but `nslookup microsoft.com` returned a server failure.

**Cause:** The client could reach the domain controller for DNS. A direct lookup through `1.1.1.1` worked, which pointed to the DC's external DNS forwarding.

**Fix:** I added `1.1.1.1` as a DNS forwarder on LVM-DC01. I kept the client's DNS set to the DC at `10.30.40.10`.

**Verified:** The client resolved `microsoft.com`, and the site loaded in Edge.

**Handoff:** External DNS works. Windows 11 evaluation activation was still unresolved and would need separate troubleshooting.
