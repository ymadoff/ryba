
# YARN RM Doctor

## Corrupted Zookeeper

Message "yarn is trying to renew a token with wrong password"  on startup
Cause: an application fail to recover
Solution: remove the zookeeper entries `rmr /rmstore`

