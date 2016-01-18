
# Configuration for Servicegroups

    module.exports = ->
      {servicegroups} = @config.ryba.shinken.config

Function to create a group

      initgroup = (name, alias) ->
        servicegroups[name] ?= {}
        servicegroups[name].alias ?= if alias then alias else "#{name.charAt(0).toUpperCase()+name.slice(1)} Services"
        servicegroups[name].members ?= []
        servicegroups[name].servicegroups_members ?= []
        servicegroups[name].servicegroups_members = [servicegroups[name].servicegroups_members] if typeof servicegroups[name].servicegroups_members is 'string'
      addgroup = (group, name) ->
        servicegroups[name].servicegroups_members.push group unless group in servicegroups[name].servicegroups_members

## Zookeeper

Zookeeper Service Group

      initgroup 'zookeeper'

Zookeeper Server Service Group

      initgroup 'zookeeper_server', 'Zookeeper Server Services'
      addgroup 'zookeeper_server', 'zookeeper'

Zookeeper Client Service Group

      initgroup 'zookeeper_client', 'Zookeeper Client Services'
      addgroup 'zookeeper_client', 'zookeeper'

## Hadoop

Hadoop Service Group
      
      initgroup 'hadoop'

### HDFS

HDFS Service Group

      initgroup 'hdfs', 'HDFS Services'
      addgroup 'hdfs', 'hadoop'
      
NameNode Service Group

      initgroup 'hdfs_nn', 'HDFS NameNode Services'
      addgroup 'hdfs_nn', 'hdfs'

JournalNode Service Group

      initgroup 'hdfs_jn', 'HDFS JournalNode Services'
      addgroup 'hdfs_jn', 'hdfs'

ZKFC Service Group

      initgroup 'zkfc', 'HDFS ZKFC Services'
      addgroup 'zkfc', 'hdfs'

DataNode Service Group

      initgroup 'hdfs_dn', 'HDFS DataNode Services'
      addgroup 'hdfs_dn', 'hdfs'

HttpFS Service Group

      initgroup 'httpfs', 'HttpFS Services'
      addgroup 'httpfs', 'hdfs'

HDFS Client Service Group

      initgroup 'hdfs_client', 'HDFS Client Services'
      addgroup 'hdfs_client', 'hdfs'

### YARN

YARN Service Group

      initgroup 'yarn', 'YARN Services'
      addgroup 'yarn', 'hadoop'
      
YARN ResourceManager Service Group

      initgroup 'yarn_rm', 'YARN ResourceManager Services'
      addgroup 'yarn_rm', 'yarn'

YARN NodeManager Service Group

      initgroup 'yarn_nm', 'YARN NodeManager Services'
      addgroup 'yarn_nm', 'yarn'

YARN Timeline Service Group

      initgroup 'yarn_ts', 'YARN Timeline Server Services'
      addgroup 'yarn_ts', 'yarn'

### MapReduce

MapReduce Service Group

      initgroup 'mapreduce', 'MapReduce Services'
      addgroup 'mapreduce', 'hadoop'

MapReduce JobHistory Server Service Group

      initgroup 'mapred_jhs', 'MapReduce JobHistory Server Services'
      addgroup 'mapred_jhs', 'mapreduce'

MapReduce Client Service Group

      initgroup 'mapred_client', 'MapReduce Client Services'
      addgroup 'mapred_client', 'mapreduce'

## HBase

HBase Service Group

      initgroup 'hbase', 'HBase Services'

HBase Master Service Group

      initgroup 'hbase_master', 'HBase Master Services'
      addgroup 'hbase_master', 'hbase'

RegionServer Service Group

      initgroup 'hbase_regionserver', 'HBase RegionServer Services'
      addgroup 'hbase_regionserver', 'hbase'

HBase REST Service Group

      initgroup 'hbase_rest', 'HBase REST Services'
      addgroup 'hbase_rest', 'hbase'

HBase Thrift Service Group

      initgroup 'hbase_thrift', 'RegionServer Services'
      addgroup 'hbase_thrift', 'hbase'

## Phoenix

Phoenix Service Group

      initgroup 'phoenix'

Phoenix Master Service Group

      initgroup 'phoenix_master', 'Phoenix Master Services'
      addgroup 'phoenix_master', 'phoenix'

Phoenix regionserver Service Group

      initgroup 'phoenix_regionserver', 'Phoenix RegionServer Services'
      addgroup 'phoenix_regionserver', 'phoenix'

Phoenix Client Service Group

      initgroup 'phoenix_client', 'Phoenix Client Services'
      addgroup 'phoenix_client', 'phoenix'

## Hive

Hive Service Group

      initgroup 'hive'
      
HiveServer2 Service Group

      initgroup 'hiveserver2', 'HiveServer2 Services'
      addgroup 'hiveserver2', 'hive'

Hive HCatalog Service Group

      initgroup 'hcatalog', 'HCatalog Services'
      addgroup 'hcatalog', 'hive'

WebHCat Service Group

      initgroup 'webhcat', 'WebHCat Services'
      addgroup 'webhcat', 'hive'

Hive Client Service Group

      initgroup 'hive_client', 'WebHCat Services'
      addgroup 'hive_client', 'hive'

## Oozie

Oozie Service Group

      initgroup 'oozie'

Oozie Server Service Group

      initgroup 'oozie_server', 'Oozie Server Services'
      addgroup 'oozie_server', 'oozie'

Oozie Client Service Group

      initgroup 'oozie_client', 'Oozie Client Services'
      addgroup 'oozie_client', 'oozie'

## Kafka

Kafka Service Group

      initgroup 'kafka'

Kafka Broker Service Group

      initgroup 'kafka_broker', 'Kafka Broker Services'
      addgroup 'kafka_broker', 'kafka'

## Spark

Spark Service Group

      initgroup 'spark'

Spark History Server Service Group

      initgroup 'spark_hs', 'Spark History Server Services'
      addgroup 'spark_hs', 'spark'

Spark Client Service Group

      initgroup 'spark_client', 'Spark Client Services'
      addgroup 'spark_client', 'spark'

## ElasticSearch

ElasticSearch Service Group

      initgroup 'elasticsearch', 'ElasticSearch Services'

## SolR

SolR Service Group

      initgroup 'solr', 'SolR Services'

## Titan DB

Titan DB Service Group

      initgroup 'titan', 'Titan DB Services'

## Rexster WebUI

Rexster WebUI Service Group

      initgroup 'rexster'

## Pig

Pig Service Group

      initgroup 'pig'

## Falcon

Falcon Service Group

      initgroup 'falcon'

## Flume

Flume Service Group

      initgroup 'flume'

## Hue

Hue Service Group

      initgroup 'hue'

## Zeppelin

Zeppelin Service Group

      initgroup 'zeppelin'
