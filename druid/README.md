
# Druid

## Internal Components

A Druid Cluster is composed of several different types of nodes. Each node is designed to do a small set of things very well.

*   Historical Nodes: Historical nodes commonly form the backbone of a Druid cluster. Historical nodes download immutable segments locally and serve queries over those segments. The nodes have a shared nothing architecture and know how to load segments, drop segments, and serve queries on segments.

*   Broker Nodes: Broker nodes are what clients and applications query to get data from Druid. Broker nodes are responsible for scattering queries and gathering and merging results. Broker nodes know what segments live where.

*   Coordinator Nodes: Coordinator nodes manage segments on historical nodes in a cluster. Coordinator nodes tell historical nodes to load new segments, drop old segments, and move segments to load balance.

*   Real-time Processing: Real-time processing in Druid can currently be done using standalone realtime nodes or using the indexing service. The real-time logic is common between these two services. Real-time processing involves ingesting data, indexing the data (creating segments), and handing segments off to historical nodes. Data is queryable as soon as it is ingested by the realtime processing logic. The hand-off process is also lossless; data remains queryable throughout the entire process.

## External Dependencies

Druid has a couple of external dependencies for cluster operations.

*   Zookeeper: Druid relies on Zookeeper for intra-cluster communication.

*   Metadata Storage: Druid relies on a metadata storage to store metadata about segments and configuration. Services that create segments write new entries to the metadata store and the coordinator nodes monitor the metadata store to know when new data needs to be loaded or old data needs to be dropped. The metadata store is not involved in the query path. MySQL and PostgreSQL are popular metadata stores for production, but Derby can be used for experimentation when you are running all druid nodes on a single machine.

*   Deep Storage: Deep storage acts as a permanent backup of segments. Services that create segments upload segments to deep storage and historical nodes download segments from deep storage. Deep storage is not involved in the query path. S3 and HDFS are popular deep storages.

## Architecture

Druid Historicals and MiddleManagers can be co-located on the same hardware. Both Druid processes benefit greatly from being tuned to the hardware they run on. If you are running Tranquility Server or Kafka, you can also colocate Tranquility with these two Druid processes.

Service startup order is documented in the [cludesting page](http://druid.io/docs/latest/tutorials/cluster.html).

## Usage

```
./bin/ryba -c ./conf/env/offline.coffee start -m 'masson/**' -m 'ryba/zookeeper/**' -m 'ryba/hadoop/**'
./bin/ryba -c ./conf/env/offline.coffee install -m 'ryba/druid/**'
```

## Open ports (if using a firewall)

If you're using a firewall or some other system that only allows traffic on specific ports, allow inbound connections on the following:

*   1527 (Derby on your Coordinator; not needed if you are using a separate metadata store like MySQL or PostgreSQL)
*   2181 (ZooKeeper; not needed if you are using a separate ZooKeeper cluster)
*   8081 (Coordinator)
*   8082 (Broker)
*   8083 (Historical)
*   8084 (Standalone Realtime, if used)
*   8088 (Router, if used)
*   8090 (Overlord)
*   8091, 8100–8199 (Druid Middle Manager; you may need higher than port 8199 if you have a very high druid.worker.capacity)
*   8200 (Tranquility Server, if used)

UIs:
*   http://worker1.ryba:8090/console.html
*   http://worker2.ryba:8081/#/datasources
