# TKT-003 — Workstation cannot find the domain

**Device:** LVM-CL01  
**Status:** Resolved during setup

**Problem:** The workstation could not resolve `lawrencevillemarket.test`.

**Cause:** [`ipconfig /all` showed a `169.254.x.x` address](../screenshots/client-apipa.png). The static network settings had been entered but had not taken effect.

**Fix:** I saved the IPv4 settings again: IP `10.30.40.20`, subnet mask `255.255.255.0`, gateway `10.30.40.1`, and DNS `10.30.40.10`.

**Verified:** `ipconfig /all` then showed the correct settings. The workstation resolved the domain and joined it successfully.

**Handoff:** Check `ipconfig /all` after changing an adapter. The client must use the domain controller (`10.30.40.10`) for DNS.
