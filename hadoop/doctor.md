
## NodeManager corrupted ownership

The permissions inside the "usercache" folder are set to yarn instead of the
user being impersonnated by yarn.

/data/1/yarn/local/usercache/ryba ryba:yarn OK
/data/1/yarn/local/usercache/ryba/appcache ryba:yarn INVALID yarn:yarn
/data/1/yarn/local/usercache/ryba/filecache ryba:yarn INVALID yarn:yarn
/data/1/yarn/local/usercache/ryba/filecache/{id} ryba:ryba INVALID yarn:yarn
/data/1/yarn/local/usercache/ryba/filecache/{id}/{file} ryba:ryba INVALID yarn:yarn

user='ryba'
chown $user /data/1/yarn/local/usercache/$user/appcache
chown $user /data/1/yarn/local/usercache/$user/filecache
chown -R $user:$user /data/1/yarn/local/usercache/$user/filecache

The cause is still unkown. 

There are a few concequences of this curruption.
