
# OpenTSDB

[OpenTSDB][website] is a distributed, scalable Time Series Database (TSDB) written on
top of HBase.  OpenTSDB was written to address a common need: store, index
and serve metrics collected from computer systems (network gear, operating
systems, applications) at a large scale, and make this data easily accessible
and graphable.
OpenTSDB does not seem to work without the hbase rights

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        hbase_client: implicit: true, module: 'ryba/hbase/client'
      configure:
        'ryba/opentsdb/configure'
      commands:
        'install': [
          'ryba/opentsdb/install'
          'ryba/opentsdb/start'
          'ryba/opentsdb/check'
        ]
        'prepare':
          'ryba/opentsdb/prepare'
        'start':
          'ryba/opentsdb/start'
        'check':
          'ryba/opentsdb/check'
        'status':
          'ryba/opentsdb/status'
        'stop':
          'ryba/opentsdb/stop'

## Resources

*   [OpentTSDB: Configuration](http://opentsdb.net/docs/build/html/user_guide/configuration.html)

[website]: http://opentsdb.net/
