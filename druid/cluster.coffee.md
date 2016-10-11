

    module.exports = ->
      name: 'ryba/druid'
      provides:
        broker: 'ryba/druid/broker'
        coordinator:
        historical:
        middlemanager:
        overlord:
        tranquility:

    module.exports =
      name: 'ryba/druid/broker'
      dependencies:
        hdfs: 'ryba/hadoop/hdfs'
        postgresql: 'masson/commons/postgresql'
      configure: (dependencies) ->
        require('../lib/configure') dependencies
        'install': ->
          jvm: ''
          jmx: {}
      commands:
        'install':
          'ryba/druid/broker/install'

    modules:
      'masson/commons/java': {}
      'prod_hdfs_nn':
        module: 'ryba/hadoop/hdfs_nn'
        constraint:
          "environment": "prod"
          "type": "master"
        dependencies:
          system: 'masson/system'
      'ryba/druid/broker':
        constraint:
          "environment": "prod"
          "type": "master"
        dependencies:
          java: 'masson/commons/java'
          hdfs: 'prod_hdfs_nn'
          
    servers:
      "edge.ryba":
        tags:
          "environment": "prod"
          "type": "edge"
        config: {}
      "master1.ryba":
        tags:
          "environment": "prod"
          "type": "master"
        config: {}
      "master2.ryba":
        tags:
          "environment": "prod"
          "type": "master"
        config: {}
      "master3.ryba":
        tags:
          "environment": "prod"
          "type": "master"
        config: {}
      "worker1.ryba":
        tags:
          "environment": "prod"
          "type": "worker"
        config: {}
      "worker2.ryba":
        tags:
          "environment": "prod"
          "type": "worker"
        config: {}
