
# Benchmark Configuration

Example:

```json
{ "ryba": { "benchmark": {
    "iterations": 10
    "datanodes": [
      "https://worker1.ryba:50475/jmx",
      "https://worker2.ryba:50475/jmx"
    ],
    "output": "path/to/benchmarks/output/dir"
} }
```

    module.exports = ->
      benchmark = @config.ryba.benchmark ?= {}
      throw Error 'No benchmark configuration specified' unless benchmark?.datanodes?.length > 0
      benchmark.iterations ?= 10
      benchmark.output ?= "benchmark_results"
      benchmark.output += "/#{moment().format 'YYYYMMDDHHmmss'}"

## JMX urls

      benchmark.datanodes ?= []
      for datanode, i in benchmark.datanodes
        datanode = benchmark.datanodes[i] = url: datanode if typeof datanode is 'string'
        datanode.name ?= datanode.url.split("/")[2].split(":")[0]
        datanode.urls ?= {}
        datanode.urls.system ?= "#{datanode.url}?qry=java.lang:type=OperatingSystem"
        datanode.urls.disks ?= "#{datanode.url}?qry=Hadoop:service=DataNode,name=DataNodeInfo"
        datanode.urls.metrics ?= "#{datanode.url}?qry=Hadoop:service=DataNode,name=DataNodeActivity-#{datanode.url.split("/")[2].split(":")[0]}-1004"

## Jobs jar path

      benchmark.jars ?= {}
      benchmark.jars.cloudera ?= "/opt/cloudera/parcels/CDH/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar"
      benchmark.jars.hortonworks ?= "/usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-examples-2*.jar"
      benchmark.jars.current ?= {}

## TeraGen / TeraSort output values 

      benchmark.terasort =
        stdout_value_names: [
          "HDFS: Number of bytes read"
          "HDFS: Number of bytes written"
          "HDFS: Number of large read operations"
          "HDFS: Number of write operations"
          "CPU time spent (ms)"
          "Physical memory (bytes)"
          "Virtual memory (bytes)"
        ]

## Kerberos

      benchmark.kerberos = @config.ryba.krb5_user ?= {}

## Normalization

Once normalized, the benchmark property looks like:

```json
{ iterations: 1,
  datanodes_jmx_urls: 
   [ 'https://worker1.ryba:50475/jmx',
     'https://worker2.ryba:50475/jmx' ],
  output: './benchmark/20170428174520',
  datanodes: 
   [ { name: 'worker1.ryba',
       urls: 
        { system: 'https://worker1.ryba:50475/jmx?qry=java.lang:type=OperatingSystem',
          disks: 'https://worker1.ryba:50475/jmx?qry=Hadoop:service=DataNode,name=DataNodeInfo',
          metrics: 'https://worker1.ryba:50475/jmx?qry=Hadoop:service=DataNode,name=DataNodeActivity-worker1.ryba-1004' } },
     { name: 'worker2.ryba',
       urls: 
        { system: 'https://worker2.ryba:50475/jmx?qry=java.lang:type=OperatingSystem',
          disks: 'https://worker2.ryba:50475/jmx?qry=Hadoop:service=DataNode,name=DataNodeInfo',
          metrics: 'https://worker2.ryba:50475/jmx?qry=Hadoop:service=DataNode,name=DataNodeActivity-worker2.ryba-1004' } } ],
  jars: 
   { cloudera: { mapreduce: '/opt/cloudera/parcels/CDH/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar' },
     hortonworks: { mapreduce: '/usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-examples-2*.jar' },
     current: {} },
  terasort: 
   { stdout_value_names: 
      [ 'HDFS: Number of bytes read',
        'HDFS: Number of bytes written',
        'HDFS: Number of large read operations',
        'HDFS: Number of write operations',
        'CPU time spent (ms)',
        'Physical memory (bytes)',
        'Virtual memory (bytes)' ] },
  kerberos: 
   { password: 'test123',
     password_sync: true,
     principal: 'ryba@HADOOP.RYBA' } }
```

## Imports 

    moment = require 'moment'
