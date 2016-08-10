
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
