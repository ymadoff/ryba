
# HBase ThriftServer

[Apache Thrift](http://wiki.apache.org/hadoop/Hbase/ThriftApi) is a
cross-platform, cross-language development framework. HBase includes a Thrift 
API and filter language. The Thrift API relies on client and server processes.
Thrift is both cross-platform and more lightweight than REST for many operations.

From 1.0 thrift can enable impersonation for other service 
[like hue][hue-hbase-impersonation].

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        hadoop_core: 'ryba/hadoop/core'
        hbase_master: 'ryba/hbase/master'
        hbase_regionserver: 'ryba/hbase/regionserver'
        hbase_client: implicit: true, module: 'ryba/hbase/client'
      configure:
        'ryba/hbase/thrift/configure'
      commands:
        'install': [
           'ryba/hbase/thrift/install'
           'ryba/hbase/thrift/start'
           'ryba/hbase/thrift/check'
        ]
        'start':
          'ryba/hbase/thrift/start'
        'status':
          'ryba/hbase/thrift/status'
        'stop':
          'ryba/hbase/thrift/stop'

  [hue-hbase-impersonation]:(http://gethue.com/hbase-browsing-with-doas-impersonation-and-kerberos/)
  [hbase-configuration]:(http://www.cloudera.com/content/www/en-us/documentation/enterprise/latest/topics/cdh_sg_hbase_authentication.html/)
