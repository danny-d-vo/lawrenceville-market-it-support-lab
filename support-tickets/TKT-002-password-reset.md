# TKT-002 — Front-End employee cannot sign in

**User:** Evan Langston on LVM-CL01  
**Status:** Resolved (lab simulation)

**Problem:** Windows said the username or password was incorrect.

**Cause:** I used an incorrect password for this test. Evan's account was still present in the Front-End OU.

**Fix:** I reset his password in Active Directory Users and Computers and required a password change at his next sign-in.

**Verified:** Evan changed the temporary password and reached the Windows desktop.

**Handoff:** The account works. No password is stored in this ticket. For a real request, verify the user's identity before resetting a password.
