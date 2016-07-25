
# Tez

[Apache Tez][tez] is aimed at building an application framework which allows for
a complex directed-acyclic-graph of tasks for processing data. It is currently
built atop Apache Hadoop YARN.

## Commands

    module.exports = ->
      'configure':
        'ryba/tez/configure'
      'install': [
        'ryba/hadoop/yarn_client'
        'ryba/tez/install'
        'ryba/tez/check'
      ]
      'check':
        'ryba/tez/check'

[tez]: http://tez.apache.org/
[instructions]: (http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.0/HDP_Man_Install_v22/index.html#Item1.8.4)
