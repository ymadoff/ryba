
# Hbase Master Backup

## Snapshots

HBase snapshots are fully functional, feature rich, and require no cluster
downtime during their creation.

http://hbase.apache.org/book/ops.snapshots.html
https://blog.cloudera.com/blog/2013/03/introduction-to-apache-hbase-snapshots/
http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.1.3-Win/bk_user-guide/content/user-guide-hbase-snapshots.html

The `exportSnapshot` command provide offsite backup of the data. It duplicate a
table’s data into the local HDFS cluster or a remote HDFS cluster.

## Replication

HBase provides a replication mechanism to copy data between HBase clusters. It
can be used as a disaster recovery solution and as a mechanism for high
availability. 

Replication has three modes: master->slave, master<->master, and cyclic. You can
also use replication to separate web-facing operations from back-end jobs such
as MapReduce. It is for example possible to collect data into multiple clusters
and replicate the data into all the running HBase clusters. In case of failure,
client can choose an alternate location.

Replication is asynchronous, allowing clusters to be geographically distant or
to have some gaps in availability. Eventual consistency it guarantees that, if
no additional updates are made to a given data item, all reads to that item will
eventually return the same value.

http://hbase.apache.org/book.html#cluster_replication

## Export

hbase.apache.org/book/ops_mgt.html#export

## CopyTable

http://hbase.apache.org/book/ops_mgt.html#copytable
http://blog.cloudera.com/blog/2012/06/online-hbase-backups-with-copytable-2/
https://blog.safaribooksonline.com/2013/06/18/backing-up-and-restoring-data-on-a-live-hbase-cluster/
