
# Rexster Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./').configure
## Check Status

Check status using JMX

    module.exports.push name: 'Rexster # Check Status', label_true: 'CHECKED', retry: 10, wait: 10000, handler: (ctx, next) ->
      {titan, rexster} = ctx.config.ryba
      ctx.execute
        cmd:"""
        #{path.join titan.home, 'bin', 'rexster.sh'} --status |  grep 'Rexster Server is running'
        """
      , next

## Check REPL

Check REPL (rexster-console.sh)

    module.exports.push name: 'Rexster # Check REPL', label_true: 'CHECKED', handler: (ctx, next) ->
      next null, 'TODO'

## Check REST

Text mode of REST Server

    module.exports.push name: 'Rexster # Check REST', label_true: 'CHECKED', handler: (ctx, next) ->
      # {realm, user, rexster} = ctx.config.ryba
      # ctx.execute
      #   cmd: mkcmd.test ctx, """
      #   curl -s -k --negotiate -u : <url>
      #   """
      # , (err, executed, stdout) ->
      next null, 'TODO'

## Check Rexpro

Binary mode (DSL) of REST Server

    module.exports.push name: 'Rexster # Check RexPro', label_true: 'CHECKED', handler: (ctx, next) ->
      # {realm, user, rexster} = ctx.config.ryba
      # ctx.execute
      #   cmd: mkcmd.test ctx, """
      #   curl -s -k --negotiate -u : <url>
      #   """
      # , (err, executed, stdout) ->
      next null, 'TODO'

## Module Dependencies

    path = require 'path'
