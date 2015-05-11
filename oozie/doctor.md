
# Oozie doctor

## wrong user imporsonalisation (kerberos, client, delegation token)

### Description

In Kerberos mode, it is possible for Oozie to execute a workflow with an
unexpected user. This is reproducable with a kerberos ticket is present in cache
or after destroing any Kerberos ticket.

When contacting Oozie, the Kerberos ticket is transmitted from the client to the
server through SPNEGO. The server return an authentication token wich is store
inside the home directory of the current unix user in a file named
".oozie-auth-token".

The authentication token which is later used to communicate with the
Oozie server. The Oozie client doesnt check if a Kerberos ticket exists or
worst if a Kerberos ticket exists under a different principal and bypass the
ticket cache usage if it is found invalid.

### Solution

The file can safely be removed with a command like `rm ~/.oozie-auth-token`.
