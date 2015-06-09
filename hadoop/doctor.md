
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

## FileSystem appear full while not full

Some files (such as log files) have been removed while the service is still
running. Here's how to list removed files:

```
# Disk Usage for directory
# -m: in MB
# -n: skip directories on different file systems
du -mx /var/ | sort -n | tail -30
# File system disk space
df -h
# List open files
lsof | grep deleted
```

Solution: restart the service using those files.

## FileSystem is not balanced

http://www.swiss-scalability.com/2013/08/hadoop-hdfs-balancer-explained.html
http://hadoop.apache.org/docs/r2.7.0/hadoop-project-dist/hadoop-hdfs/HDFSCommands.html#balancer