
# Benchmark Configuration

Example:

```json
{ "ryba": { "benchmark": {
    "iterations": 10
    "datanodes_jmx_urls": [
      "https://worker1.ryba:50475/jmx",
      "https://worker2.ryba:50475/jmx"
    ],
    "output": "path/to/benchmarks/output/dir"
} }
```

    module.exports = ->
      benchmark = @config.ryba.benchmark ?= {}
      throw Error 'No benchmark configuration specified' unless benchmark?.datanodes_jmx_urls.length > 0
      
      benchmark.iterations ?= 10
      benchmark.output ?= "benchmark_results"
      benchmark.output += "/#{moment().format 'YYYYMMDDHHmmss'}"


## JMX urls

      #benchmark.is_https = true unless benchmark.datanodes_jmx_urls[0].split(":")[0] is "http"

      benchmark.datanodes = []
      for url in benchmark.datanodes_jmx_urls
        benchmark.datanodes.push 
          name: url.split("/")[2].split(":")[0]
          urls: 
            system: "#{url}?qry=java.lang:type=OperatingSystem"
            disks: "#{url}?qry=Hadoop:service=DataNode,name=DataNodeInfo"
            metrics: "#{url}?qry=Hadoop:service=DataNode,name=DataNodeActivity-#{url.split("/")[2].split(":")[0]}-1004"


## Jobs jar path

      benchmark.jars = 
        cloudera: mapreduce: "/opt/cloudera/parcels/CDH/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar"
        hortonworks: mapreduce: "/usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-examples-2*.jar"
        current: {}
        

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
        

## Imports 

    moment = require 'moment'
