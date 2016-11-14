
# Pig

[Apache Pig](https://pig.apache.org/) is a platform for analyzing large data sets that consists of a
high-level language for expressing data analysis programs, coupled with
infrastructure for evaluating these programs. The salient property of Pig
programs is that their structure is amenable to substantial parallelization,
which in turns enables them to handle very large data sets.

    module.exports =
      use:
        java: implicit: true, module: 'masson/commons/java'
        hadoop_core: 'ryba/hadoop/core'
        mapred_client: 'ryba/hadoop/mapred_client'
        yarn_client: 'ryba/hadoop/yarn_client'
        hive_client: 'ryba/hive/client' # In case pig is run through hcat
      configure:
        'ryba/pig/configure'
      commands:
        'check':
          'ryba/pig/check'
        'install': [
           'ryba/pig/install'
           'ryba/pig/check'
        ]
