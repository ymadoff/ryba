
# Unix Users and Groups

List the system user and group created by the various services. For those using
the "vagrant" example, the information below list the reserved uid and gid
defined in the configuration.

## Users

| Service            | name        | uid  | gid  | groups  |
|--------------------|-------------|------|------|---------|
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
| Knox               | knox        | 2420 | 2420 |         |

## Groups

| Service            | name         | gid  |
|--------------------|--------------|------|
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
| Knox               | knox         | 2420 |

