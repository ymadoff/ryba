# HBase Cluster Replication Strategy

Apache HBase provide replication feature to copy data between different HBase
Clusters. It can be used to recover data after a natural disaster, or to increase HBase availability.

Master:
Slave: The HBase cluster where data are copied to.

## Types of Replication

Three architectures are available to deploy HBase replication:
- Master-Slave
- Master-Master
- Cyclic

In thoses architecture Master designates the HBase cluster whose data are from (source) and
Slave designates the HBase cluster where data are copied to (target).

## Master Slave Replication

In a Master- Slave configuration, the data are copied from the master cluster to the slave cluster.
The relation is uni-directional.
It makes available the master's cluster data on the slave cluster, in case the master cluster is not online.
Whoever the data are only available on reading, no writing is possible.

## Master Master Replication
if
