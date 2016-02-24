
# MongoDB Client

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      mongodb = ctx.config.ryba.mongodb ?= {}

## Commands

    module.exports.push commands: 'check', modules: [
      'masson/bootstrap'
      'ryba/mongodb/router/wait'
      'ryba/mongodb/client/check'
    ]

    module.exports.push commands: 'install', modules: [
      'masson/bootstrap'
      'ryba/mongodb/client/install'
    ]
