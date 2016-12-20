
# Mongodb Cluster Deployment By Ryba

The `ryba/mongo` module aims at deploying a full distributed MongoDB Cluster, with
security enabled (as possibly allowed) using [MongoDB Community edition][mongo-ce]


## Architecture

### Components

Lets' checkout Components of a MongoDb Shard Cluster.

- Shard Server
A Shard stores the database data. Ryba deploys  mongoDB with shards, even if it is optional. This behavior is adopted
because deploying [sharding enables horizontal scaling][mongo-sharding]: 'divides the data set and distributes
the data over multiple servers, or shards'. So in the cluster config, one Shard at least will be deployed, which will
allow operator to add other shard. It makes the addition of new Shard really easy.
- Config Server
[Config Server][mongo-config-server] stores the shards server [metadata][mongo-shard-metada].
The metadata reflects state and organization of Shards.
- Router Server
The router server tracks what data is on which shard by caching the metadata from the config servers.

Let's checkout which processes and tools compose a MongoDB Cluster.

### Processes

MongoDB cluster components are divided into several processes. A process is a service
and is run with a `role`.  Two processes exists in a MongoDB Cluster.

- Mongod
This process is is run on a server which aims at manipulate data
The roles played are:
  * sharding server (stores database data)
  * config server (store databases metadata)
- Mongos
This service is known as the router server. This is the service to which
client application connects in order to be router to the right mongod processes (sharding server).
Mongos  is also used to add shard to a cluster.

### Tools

MongoDB Package comes with a set of tools, to be able to operate on the MongoDB Cluster.
The main tool used by Ryba is the mongo shell, to operate and manage the MongoDB Cluster.

### Replication

[Replication][mongo-replication] in MongoDB brings better Data availability and
redundancy. Each MongoDB component running on top of mongod process can be replicated.
A component which is replicated is called a Replica Set. So config and sharding servers
can be deployed as a replica set.
A replica set run on the model of primary-passive model. it means that in a replica set, on node
is the primary node (receives write operations) amd all the other only read operations.
But the primary role can be attributed to every secondary node in the replica set.
In case of the primary failure, all the secondary node elect a new primary node.

In Production Environment replica set is advised for every component of a sharded cluster.
A replica set should at least contain 3 server (even number and enough redundancy).
Never the less the replica set can be deployed with less than 3 nodes, it will just lack
redundancy. Because starting directly with a replica set, you can add other server easily to it.
This what Ryba does.

## Ryba Deployment Strategy

Ryba deploys a sharded MongoDB Cluster. Shard Cluster and config server are deployed as
replica sets.
Because mongos does not hold data on disk, replica set does not exist for router server.
But several router server can be deployed for a same config server replica set.
It can provide High availability for client application.

Ryba checks the configuration of your cluster to find  wether components are rightly configured
or not.
Here are some tips for you to configure rightly your cluster.
-  Router server can be dedicated to only one Config server replica set
  -> as a consequence because router server routes query to shards, a Shard Cluster
  metadata can be hold only by a config server Replica Set.
- Even if Ryba can make some deduction for you (see below), some properties are mandatory
  -> You must designated a replica set master, which play the role of primary during the
  replica set Initialization.
  So mandatory properties are (host level context):
    * `ryba.mongo_config_replica_master` (Bool):
      Designates a host to initialize config server replica set
    * `ryba.mongo_shard_replica_master` (Bool):
      Designates a host to initialize Shard Cluster replica set
    * `ryba.mongo_router_for_configsrv` (String)
      Designates Wich config servers replica set the mongos router server
      is dedicated.
- internally Ryba use two main object to have a Cluster Overview of the replica sets
for shards and config servers.
    * `ryba.mongodb.shard.replica_sets` (String:Shard => Array[String]:host)
      This object contains the list of Shard Cluster to deploy with the shard's name as a key
      and the host belonging to the Shard.
      -> If this variable is not overridden in the config, Ryba uses all the
       available shard server to belong to a single Shard Replica Set.
    * `ryba.mongodb.configsrv.replica_sets` (String:ConfigReplName => { hosts:Array[String], shards:Array[String])
      This object contains the list of Replica set to deploy for config servers, each config server replica set,
      contains the list of host belonging to the replica set and the Shards Cluster' name to hold metadata.
      -> If this variable is not overridden in the config, Ryba uses all the
       config server to create one replica set, and attributes to it all the available
       Shards.

### Security

- Authentication
  MongoDB has several authentication mechanism, unfortunately LDAP and kerberos are only
  available in Enterprise edition.
  * SCRAM-SHA-1 (Default)
  * MongoDB Challenge and Response (MONGODB-CR)
  * x.509 Certificate Authentication.
  Ryba uses SCRAM-SHA-1

- Encryption
  However we can use SSL to encrypt internal data exchance betwwen the MongoDB processes
  which is done by set `net.ssl` property to preferSSL.

  Authentication is activated by default, as a consequence,  the `LocalHost Exception`
  on the primary host of a replica set  must be use to initiate the cluster.
  Once the admin users are created the Exception is not available any more.




[mongo-ce]:(https://www.mongodb.org/community)
[mongo-sharding]:(https://docs.mongodb.org/manual/core/sharding-introduction/)
[mongo-config-server]:(https://docs.mongodb.org/manual/core/sharded-cluster-config-servers/#sharding-config-server)
[mongo-shard-metada]:(https://docs.mongodb.org/manual/core/sharded-cluster-metadata/)
[mongo-replication]:(https://docs.mongodb.org/manual/core/replication-introduction/)
