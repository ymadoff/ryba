
## NodeManager corrupted ownership

The permissions inside the "usercache" folder are set to yarn instead of the
user being impersonnated by yarn.

/data/1/yarn/local/usercache/ryba ryba:yarn OK
/data/1/yarn/local/usercache/ryba/appcache yarn:yarn drwx--x--- insteadof ryba:yarn drwxr-s---
/data/1/yarn/local/usercache/ryba/filecache yarn:yarn insteadof ryba:yarn
/data/1/yarn/local/usercache/ryba/filecache/{id} yarn:yarn insteadof ryba:ryba
/data/1/yarn/local/usercache/ryba/filecache/{id}/{file} yarn:yarn insteadof ryba:ryba

user='ryba'
chown $user /data/*/yarn/local/usercache/$user/appcache
chmod 2750 /data/*/yarn/local/usercache/$user/appcache
chown $user /data/*/yarn/local/usercache/$user/filecache
chown -R $user:$user /data/*/yarn/local/usercache/$user/filecache

The cause is still unkown. 

There are a few concequences of this curruption.

Inside the NodeManager after a mapreduce:

> org.apache.hadoop.util.DiskChecker$DiskErrorException: Could not find usercache
