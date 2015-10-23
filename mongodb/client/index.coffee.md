
# MongoDB Client

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      mongodb = ctx.config.ryba.mongodb ?= {}

## Commands

    module.exports.push commands: 'check', modules: 'ryba/mongodb/client/check'

    module.exports.push commands: 'install', modules: [
      'ryba/mongodb/client/install'
      'ryba/mongodb/client/check'
    ]
