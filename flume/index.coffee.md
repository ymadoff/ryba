
# Flume

[Flume](https://flume.apache.org/) is a distributed, reliable, and available service for efficiently
collecting, aggregating, and moving large amounts of log data. It has a simple
and flexible architecture based on streaming data flows. It is robust and fault
tolerant with tunable reliability mechanisms and many failover and recovery
mechanisms.

    module.exports =
      use:
        hadoop_core: implicit: true, module: 'ryba/hadoop/core'
      configure:
        'ryba/flume/configure'
      commands:
        'install':
          'ryba/flume/install'
