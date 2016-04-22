
# Pig

[Apache Pig](https://pig.apache.org/) is a platform for analyzing large data sets that consists of a
high-level language for expressing data analysis programs, coupled with
infrastructure for evaluating these programs. The salient property of Pig
programs is that their structure is amenable to substantial parallelization,
which in turns enables them to handle very large data sets.

    module.exports = ->
      'configure': [
        'masson/commons/java'
        'ryba/pig/configure'
      ]
      'check':
        'ryba/pig/check'
      'install': [
         'masson/commons/java'
         'ryba/hadoop/mapred_client'
         'ryba/hadoop/yarn_client'
         'ryba/hive/client' # In case pig is run through hcat
         'ryba/pig/install'
         'ryba/pig/check'
      ]
