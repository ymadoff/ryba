

Ryba boostraps and manages a full secured Hadoop cluster with one command. This
is an [Open-source software (OSS) project][oss] released under the
[new BSD license][license] developed for one of the World largest utility
company. Its used every day to manager and keep to date the cluster for every
components.

Ryba is our answer to DevOps integration need for product delivery and quality
testing. It provides the flexibilty to answer the demand of your internal 
information technology (IT) operations team. It is written in JavaScript and
CoffeeScript to facilitate and accelerate feature developments and maintenance 
releases. The language encourages self-documented code, look by yourself the
source code deploying two [HA namenodes][hdfs_nn].

Install Ryba locally or on a remote server and you are ready to go. It uses SSH
to connect to each server of your cluster and will fully install all the
components you wish. You don't need to prepare your cluster nodes as long as a
minimal installation of RHEL or CentOS is installed with a root user or a user
with sudo access.

## Ryba motivations

-   Use secured comminication with SSH
-   No database used, full distribution across multiple servers relying on GIT
-   No agent or pre-installation required on your cluster nodes
-   Version control all your configuration and modifications with GIT and NPM, the Node.js Package Manager
-   Command-based to integrate with your [Business Continuity Plan (BCP)][bcp] and existing scripts
-   For developer, as simple as learning Node.js and not a new framework
-   Self-documented code written in [Literate CoffeeScript ][literate]
-   Idempotent and executable on a running cluster without any negative impact

## Ryba features

-   Bootstrap the nodes from a fresh install
-   Configure proxy environment if needed
-   Optionnaly create a bind server (useful in Vagrant development environment)
-   Install OpenLDAP and Kerberos and/or integrate with your existing infrastructure
-   Deploy the latest Hortonworks Data Platform (HDP)
-   Setup High Availabity for HDFS
-   Integrate Kerberos with cross realm support
-   Set IPTables rules and startup scripts
-   Check the running components
-   Provide convenient utilities such as global start/stop/status commands, 
    distributed shell execution, ...

Installation
------------

### Node.js

First download Node.js. You might need to adjust the name of the Node.js archive
depending on the version you choose to install. Also, replace the path
"/usr/local/node" to another location (eg "~/node") if you don't have the
permission to write inside "/usr/local".

```bash
# Download the Node.js package
wget --no-check-certificate https://nodejs.org/download/release/v6.2.2/node-v6.2.2-linux-x64.tar.gz

# Extract the Node.js package
tar xzf node-v6.2.2-linux-x64.tar.gz
# Move Node.js into its final destination
sudo mv node-v6.2.2-linux-x64 /usr/local/node
# Add path to Node.js binary
echo 'export PATH=/usr/local/node/bin:$PATH' >> ~/.bashrc
# Source the update profile
. ~/.bashrc
# Check if node is installed
node -v
# Clean up uploaded archive
rm -rf node-v6.2.2-linux-x64.tar.gz
```

If you are behind a proxy, configure the [Node.js Pakage Manager (NPM)][npm] with
the commands:

```bash
npm config set proxy http://proxy.company.com:8080
npm config set https-proxy http://proxy.company.com:8080
```

### Ryba

Run `npm install` to download the project dependencies. 

### Components

For now Ryba contains the scripts for set up the following components:
https://github.com/ryba-io/ryba/tree/master/ambari

- [Apache Atlas][atlas]
- [Druid](http://druid.io)
- [Elasticsearch][elastic]
- [Apache Falcon][falcon]
- [Apache Flume][flume]
- [Apache HADOOP][hadoop] (Including HDFS, YARN)
- [Apache HBase][hbase]
- [Apache Hive][hive]
- [HUE](https://github.com/cloudera/hue)
- [Apache Kafka][kafka]
- [Apache Knox][knox]
- [Apache Mahout][mahout]
- MongoDB
- Nagios
- [Apache Nifi][nifi] ( HDF or Apache version)
- [Apache Oozie][oozie]
- [Apache Phoenix][phoenix]
- [Apache Pig][pig]
- [Apache Ranger][ranger]
- Shinken
- [Apache Solr][solr]
- [Apache Sqoop][sqoop]
- [Apache Spark][spark]
- Docker Swarm
- [Apache TEZ][tez]
- [Apache Zookeeper][zookeeper]

### Security

- Authentication
Ryba does configure every components to work with Kerberos when possible.
All the components listed above (except Elasticsearch, MongoDB, Nagios in community version) does support Kerberos.

- Authorization
Since Ryba does support Apache Ranger, you can manage  easily the Access Control List from Ranger Admin. Indeed Apache Ranger provides support for ACL administration for the main Big Data components under the Apache project.

- Encryption
Ryba does configure TLS/SSL encryption for every service. You can generate
(see an example on  https://github.com/ryba-io/ryba-cluster) or provide your certificate, and Ryba will upload the certificates on the nodes and configure the components.

At the end of the ryba installation, you have a full Kerberized cluster with SSL
encryption enabled.

### High Availability

Ryba does configure every service with High Availibity, if the service supports it.
It does the configuration according to the layout of the cluster. Just define where you want the service to be installed, and Ryba does every step left, start and check
if the service is running rightly

### Check

Ryba has a check command which run components, to verifiy that it is rightly configured
and running. Check can be port binding verification (for example port 50470 for the Hadoop HDFS Namenode), or complete functional test like launching mapreduce jobs on YARN.

Contributors
------------

*   David Worms: <https://github.com/wdavidw>
*   Pierre Sauvage: <https://github.com/pierrotws>
*   Lucas Bakalian: <https://github.com/lucasbak>
*   Selim Nemsi:  <https://github.com/selim-namsi>
*   Damien Claveau: <https://github.com/damienclaveau>
*   César Berezowski: <https://github.com/cesarBere>

[oss]: http://en.wikipedia.org/wiki/Open-source_software
[npm]: https://www.npmjs.org/
[masson]: https://github.com/wdavidw/node-masson
[license]: https://github.com/wdavidw/ryba/blob/master/LICENSE.md
[hdfs_nn]: https://github.com/wdavidw/ryba/blob/master/hadoop/hdfs_nn.coffee.md
[bcp]: http://en.wikipedia.org/wiki/Business_continuity_planning
[literate]: http://coffeescript.org/#literate
[ambari]: https://ambari.apache.org/
[atlas]: https://atlas.apache.org
[elastic]: http://www.elastic.co
[falcon]: https://falcon.apache.org
[flume]: https://flume.apache.org
[hadoop]: https://flume.apache.org
[hbase]: https://hbase.apache.org
[hive]: https://hive.apache.org
[kafka]: https://kafka.apache.org
[knox]: https://knox.apache.org
[mahout]: https://mahout.apache.org
[nifi]: https://nifi.apache.org
[oozie]: https://oozie.apache.org
[phoenix]: https://phoenix.apache.org
[pig]: https://pig.apache.org
[ranger]: https://ranger.apache.org
[solr]: https://solr.apache.org
[sqoop]: https://sqoop.apache.org
[spark]: https://spark.apache.org
[tez]: https://tez.apache.org
[zookeeper]: https://zookeeper.apache.org
