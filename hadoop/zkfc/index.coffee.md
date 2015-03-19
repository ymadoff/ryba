
# Hadoop ZKFC

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push module.exports.configure = (ctx) ->
      require('../core').configure ctx
      {ryba} = ctx.config
      # Validation
      throw Error "Missing \"ryba.zkfc_password\" property" unless ryba.zkfc_password
      nn_ctxs = ctx.contexts 'ryba/hadoop/hdfs_nn',(require '../hdfs_nn').configure
      throw Error "Require 2 NameNodes" unless nn_ctxs.length is 2
      # Import NameNode properties
      require('../hdfs_nn').configure ctx

## Commands

    module.exports.push commands: 'check', modules: 'ryba/hadoop/zkfc/check'

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/zkfc/install'
      'ryba/hadoop/zkfc/start'
      'ryba/hadoop/zkfc/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/hadoop/zkfc/start'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/zkfc/stop'

    module.exports.push commands: 'status', modules: 'ryba/hadoop/zkfc/status'
