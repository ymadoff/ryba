# HBase Cluster Replication Strategy

Apache HBase provide replication feature to copy data between different HBase
Clusters. It can be used to recover data after disaster, or to increase HBase availability.

How it works ?

Each HBase region server 

Three strategies are available to deploy HBase replication:
- Master-Slave
- Master-Master
- Cyclic

Definition

Master: HBase cluster whose data are from
Slave: HBase cluster where data are copied to


## Master Slave Replication

In a Master- Slave configuration, the data are copied from the master HBAse
