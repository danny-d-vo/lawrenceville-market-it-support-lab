# TKT-005 — Onboard Store 01 employees

**Request:** Add employees to the six store departments. Maya Brooks and Evan Langston already had accounts.  
**Status:** Completed

**Work:** I used an [employee CSV](../employees.csv) and [PowerShell script](../Import-StoreEmployees.ps1) to create 38 new accounts in their department OUs. I ran the preview first to check usernames, OUs, and department totals. The script assigned separate temporary passwords and added the new Receiving employees to the Inventory access group.

**Verified:** AD showed [18 Front-End accounts](../screenshots/ad-front-end-accounts.png) and [40 employee accounts overall](../screenshots/ad-employee-count-40.png). The [Inventory group](../screenshots/inventory-group-members.png) contained Maya, Liam Foster, and Camila Nguyen. On the client, [Evan was denied](../screenshots/inventory-access-denied-evan.png) and [Maya was allowed](../screenshots/inventory-access-allowed-maya.png) to open the share.

**Handoff:** Temporary passwords are kept on the server, outside this project. The new accounts were checked in AD; individual first sign-ins for the 38 new hires were not tested.
