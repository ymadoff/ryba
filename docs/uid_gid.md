
# Unix Users and Groups

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

To modify a group, replace the "-uid" option by "-gid".

## Users

| Service            | name        | uid  | gid  | groups  |
|--------------------|-------------|------|------|---------|
| Bind               | named       | 802  | 802  |         |
| HDFS               | hdfs        | 2401 | 2401 | 2400    |
| Zookeeper          | zookeeper   | 2402 | 2402 | 2400    |
| Yarn               | yarn        | 2403 | 2403 | 2400    |
| MapReduce          | mapred      | 2404 | 2404 | 2404    |
| Flume              | flume       | 2405 | 2405 |         |
| Ganglia Collector  | rrdcached   | 2406 | 2406 |         |
| Hive               | hive        | 2407 | 2407 |         |
| HBase              | hbase       | 2409 | 2409 |         |
| Hue                | hue         | 2410 | 2410 |         |
| Oozie              | oozie       | 2411 | 2411 |         |
| Sqoop              | sqoop       | 2412 | 2412 |         |
| Pig                | pig         | 2413 | 2413 |         |
| Ryba Test          | ryba        | 2414 | 2414 |         |
| Apache HTTP Server | apache      | 2416 | 2416 | 2419    |
| XASecure           | xasecure    | 2417 | 2417 |         |
| Nagios             | nagios      | 2418 | 2418 |         |
| Ganglia            | rrdcached   | ???? | ???? |         |
| Knox               | knox        | 2420 | 2420 |         |
| Flacon             | falcon      | 2423 | 2423 |         |

    falcon:
      group: gid: 2421
      user: uid: 2421, gid: 2421
## Groups

| Service            | name         | gid  |
|--------------------|--------------|------|
| Bind               | named        | 802  |
| Hadoop             | hadoop       | 2400 |
| HDFS               | hdfs         | 2401 |
| Zookeeper          | zookeeper    | 2402 |
| YARN               | yarn         | 2403 |
| MapReduce          | mapred       | 2404 |
| Flume              | flume        | 2405 |
| Ganglia Collector  | rrdcached    | 2406 |
| Hive               | hive         | 2407 |
| HBase              | hbase        | 2409 |
| Hue                | hue          | 2410 |
| Oozie              | oozie        | 2411 |
| Sqoop              | sqoop        | 2412 |
| Pig                | pig          | 2413 |
| Ryba Test          | ryba         | 2414 |
| Apache HTTP Server | apache       | 2416 |
| XASecure           | xasecure     | 2417 |
| Nagios             | nagios       | 2418 |
| Nagios             | groupcmd     | 2419 |
| Ganglia            | rrdcached    | ???? |
| Knox               | knox         | 2420 |
| Flacon             | falcon       | 2423 |

