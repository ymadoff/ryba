
# Rexster Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/titan/check'
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

## Check RexPro

Check REPL (rexster-console.sh). It is not equivalent to Titan REPL, as it use the
binary protocol RexPro.

    module.exports.push name: 'Rexster # Check RexPro', skip: true, label_true: 'CHECKED', handler: (ctx, next) ->
      return next() # Not ready

## Check REST

Text mode of REST Server

    module.exports.push name: 'Rexster # Check REST', label_true: 'CHECKED', handler: (ctx, next) ->
      {rexster} = ctx.config.ryba
      graphname = rexster.config.graphs[0].graph['graph-name']
      curl = "curl -u #{rexster.admin.name}:#{rexster.admin.password} "
      curl += "#{rexster.config.http['base-uri']}:#{rexster.config.http['server-port']}"
      curl += "/graphs/#{graphname}/"
      ctx.execute
        cmd: curl
      , (err, executed, stdout) ->
        return next err, false if err or not executed
        try
          data = JSON.parse(stdout)
          return next Error "Invalid response: #{data}" unless data?.name is graphname
        catch e then return next Error "Invalid Command Output: #{JSON.stringify stdout}"
        next err, executed

## Dependencies

    path = require 'path'
