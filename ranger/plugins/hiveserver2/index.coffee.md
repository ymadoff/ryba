# Ranger HiveServer2 Plugin

    module.exports =
      use:
        hadoop_core: use: true, module: 'ryba/hadoop/core'
      configure:
        'ryba/ranger/plugins/hiveserver2/configure'
