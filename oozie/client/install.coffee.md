
# Oozie Client Install

    url = require 'url'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'ryba/hadoop/mapred_client'
    module.exports.push 'ryba/hadoop/yarn_client'
    module.exports.push require('./index').configure

## Install

Install the oozie client package. This package doesn't create any user and group.

    module.exports.push name: 'Oozie Client # Install', timeout: -1, handler: (ctx, next) ->
      ctx.service [
        name: 'oozie-client'
      ], next

    module.exports.push name: 'Oozie Client # Profile', handler: (ctx, next) ->
      {oozie} = ctx.config.ryba
      ctx.write
        destination: '/etc/profile.d/oozie.sh'
        content: """
        #!/bin/bash
        export OOZIE_URL=#{oozie.site['oozie.base.url']}
        """
        mode: 0o0755
      , next

    module.exports.push 'ryba/oozie/client/check'
