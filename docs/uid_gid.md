
# Unix Users and Groups Provisionning

List the system user and group created by the various services. For those using
the "vagrant" example, the information below list the reserved uid and gid
defined in the configuration.

## UID or GID modification

It is recommanded to configure the correct UID and GID before the first
deployment. In case those values are defined after the initial creation
of the user or group or they are modified, you must manually update the
ownership of all the files owned by the previous UID or GID.

Here is a Unix command to migrate all the affected files:

```
find / -uid $old_uid -exec chown $new_uid {} \; 2>/dev/null
find / -gid $old_gid -exec chgrp $new_gid {} \; 2>/dev/null
```

## Users

| service  | name       | uid  | gid  | login         | home             | comments
|----------|------------|------|------|---------------|------------------|----------------
| Bind     | named      | 802  | 802  | /sbin/nologin | /var/named       | Bind Server
| OpenLDAP | ldap       | 803  | 803  | /sbin/nologin | /var/lib/ldap    | LDAP Server
| HTTPD    | apache     | 2416 | 2416 | /sbin/nologin | /var/www         | Apache HTTPD User
| Ryba     | ryba       | 2414 | 2414 | /bin/bash     | /home/ryba       | Ryba Test User
| Ambari   | ambari     | 2408 | 2408 | /bin/bash | /var/lib/ambari      | Ambari user
| ZooKeeper | zookeeper | 2402 | 2402 | /bin/bash | /var/lib/zookeeper   | ZooKeeper user
| Hadoop   | hdfs       | 2416 | 2416 | /bin/bash | /var/lib/hadoop-hdfs | Hadoop HDFS user
| Hadoop   | httpfs     | 2427 | 2427 | /bin/bash | /var/lib/httpfs      | HttpFS User
| Hadoop   | yarn       | 2403 | 2403 | /bin/bash | /var/lib/hadoop-yarn | Hadoop YARN User
| Hadoop   | mapred     | 2404 | 2404 | /bin/bash | /var/lib/hadoop-mapreduce | Hadoop MapReduce User
| Flume    | flume      | 2405 | 2405 | /bin/bash | /var/lib/flume            | Flume User
| Ganglia  | rrdcached  | 2406 | 2406 | /sbin/nologin | /var/rrdtool/rrdcached | RRDtool Ganglia User
| Hive     | hive       | 2407 | 2407 | /bin/bash | /var/lib/hive        | Hive User
| HBase    | hbase      | 2409 | 2409 | /bin/bash | /var/run/hbase       | HBase User
| Hue      | hue        | 2410 | 2410 | /bin/bash | /var/lib/hue         | Hue User
| Oozie    | oozie      | 2411 | 2411 | /bin/bash | /var/lib/oozie       | Oozie User
| Sqoop    | sqoop      | 2412 | 2412 | /bin/bash | /var/lib/sqoop       | Sqoop
| Nagios   | nagios     | 2418 | 2418 | /bin/sh   | /var/log/nagios      | Nagios User
| Knox     | knox       | 2420 | 2420 | /bin/bash | /var/lib/knox        | Knox Gateway User
| Falcon   | falcon     | 2421 | 2421 | /bin/bash | /var/lib/falcon      | Falcon User
| ElasticSearch | elasticsearch | 2422 | 2422 | /bin/bash | /home/elasticsearch | ElasticSearch User
| Rexter   | rexster    | 2423 | 2423 | /bin/bash | /opt/titan/rexhome   | Rexster User
| Kafka    | kafka      | 2424 | 2424 | /bin/bash | /var/lib/kafka       | Kafka User
| Presto   | presto     | 2425 | 2425 | /bin/bash | /var/lib/presto      | Presto User
| Spark    | spark      | 2426 | 2426 | /bin/bash | /var/lib/spark       | Spark User
| OpenTSDB | opentsdb   | 2428 | 2428 | /bin/bash | /usr/share/opentsdb  | OpenTSDB User
| MongoDB  | mongodb    | 2429 | 2429 | /bin/bash | /var/lib/mongo       | MongoDB User
| Nifi     | nifi       | 2431 | 2431 | /bin/bash | /var/lib/nifi        | Nifi User
| Solr     | solr       | 2432 | 2432 | /bin/bash | /var/solr/data       | Solr User
| Hawq     | hawq       | 2433 | 2433 | /bin/bash | -                    | Hawq User
| Ranger   | ranger     | 2434 | 2434 | /bin/bash | /var/lib/ranger      | Ranger User
| Druid    | druid      | 2435 | 2435 | /bin/bash | /var/lib/druid       | Druid User
| Smartsense | smartsense | 2436 | 2436 | /bin/bash | /var/lib/smartsense | Smartsense User
| Atlas    | atlas      | 2437 | 2437 | /bin/bash | /var/lib/atlas       | Atlas User
| Zeppelin | zeppelin   | 2438 | 2438 | /bin/bash | /var/lib/zeppelin    | Zeppelin User
| Livy     | livy       | 2439 | 2439 | /sbin/nologin | /var/lib/livy    | Livy User
| Dataiku  | dataiku    | 2441 | 2441 | /bin/bash | /var/lib/dataiku     | Dataiku User

## Groups

| service       | name          | gid  | System | Users
|---------------|---------------|------|--------|--------
| Bind          | named         | 802  | Y      |
| OpenLDAP      | ldap          | 803  | Y      |
| HTTPD         | apache        | 2416 | Y      |
| Ryba          | ryba          | 2414 | Y      |
| Ambari        | ambari        | 2408 | Y      |
| Hadoop        | hadoop        | 2400 | Y      | zookeeper,hdfs,yarn,mapred
| ZooKeeper     | zookeeper     | 2402 | Y      |
| Hadoop        | hdfs          | 2416 | Y      |
| Hadoop        | httpfs        | 2427 | Y      |
| Hadoop        | yarn          | 2403 | Y      |
| Hadoop        | mapred        | 2404 | Y      |
| Flume         | flume         | 2405 | Y      |
| Ganglia       | rrdcached     | 2405 | Y      |
| Hive          | hive          | 2407 | Y      |
| HBase         | hbase         | 2409 | Y      |
| Hue           | hue           | 2410 | Y      |
| Oozie         | oozie         | 2411 | Y      |
| Sqoop         | sqoop         | 2412 | Y      |
| Nagios        | nagios        | 2418 | Y      |
| Nagios        | nagiocmd      | 2419 | Y      |
| Knox          | knox          | 2420 | Y      |
| Falcon        | falcon        | 2421 | Y      |
| ElasticSearch | elasticsearch | 2422 | Y      |
| Rexter        | rexster       | 2423 | Y      |
| Kafka         | kafka         | 2424 | Y      |
| Presto        | presto        | 2425 | Y      |
| Spark         | spark         | 2426 | Y      |
| OpenTSDB      | opentsdb      | 2428 | Y      |
| MongoDB       | mongodb       | 2429 | Y      |
| Nifi          | nifi          | 2431 | Y      |
| Solr          | solr          | 2432 | Y      |
| Hawq          | hawq          | 2433 | Y      |
| Ranger        | ranger        | 2434 | Y      |
| Druid         | druid         | 2435 | Y      |
| Smartsense    | smartsense    | 2436 | Y      |
| Atlas         | atlas         | 2437 | Y      |
| Zeppelin      | zeppelin      | 2438 | Y      |
| Livy          | livy          | 2439 | Y      |
| Dataiku       | dataiku       | 2441 | Y      |
