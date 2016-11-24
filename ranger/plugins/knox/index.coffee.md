# Ranger Knox Plugin

    module.exports =
      use:
        hadoop_core: use: true, module: 'ryba/hadoop/core'
      configure:
        'ryba/ranger/plugins/knox/configure'
