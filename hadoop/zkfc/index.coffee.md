
# Hadoop ZKFC

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push module.exports.configure = (ctx) ->
      require('../core').configure ctx
      {ryba} = ctx.config
      throw Error "Missing \"ryba.zkfc_password\" property" unless ryba.zkfc_password

## Commands

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/zkfc/install'
    ]

    module.exports.push commands: 'start', modules: 'ryba/hadoop/zkfc/start'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/zkfc/stop'

    module.exports.push commands: 'status', modules: 'ryba/hadoop/zkfc/status'
