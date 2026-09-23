# TKT-001 — Receiving employee cannot access Inventory

**User:** Maya Brooks on LVM-CL01  
**Status:** Resolved (lab simulation)

**Problem:** Maya got a [permission error](../screenshots/inventory-access-denied.png) when she opened `\\LVM-DC01\Inventory`.

**Cause:** I had removed her from `GG-Store01-Inventory-Access` to create this test. The share and folder permissions depend on that group.

**Fix:** I added Maya back to the group and had her sign out and back in so her new membership would take effect.

**Verified:** [Maya opened the share](../screenshots/inventory-access-allowed-maya.png) and edited `Receiving-Log.txt`. [Evan, who is not in the group, was denied](../screenshots/inventory-access-denied-evan.png).

**Handoff:** If access fails again, check group membership and both share and NTFS permissions. Have the user sign in again after a group change.
