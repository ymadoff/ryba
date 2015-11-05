
# Rexster Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/titan/check'
    # module.exports.push require('./').configure

## Check Status

Check status using JMX

    module.exports.push header: 'Rexster # Check Status', label_true: 'CHECKED', retry: 10, wait: 10000, handler: ->
      {titan, rexster} = @config.ryba
      @execute
        cmd:"""
        #{path.join titan.home, 'bin', 'rexster.sh'} --status |  grep 'Rexster Server is running'
        """

## Check RexPro

Check REPL (rexster-console.sh). It is not equivalent to Titan REPL, as it use the
binary protocol RexPro.

    module.exports.push header: 'Rexster # Check RexPro', skip: true, label_true: 'CHECKED', handler: ->
      return # Not ready

## Check REST

Text mode of REST Server

    module.exports.push header: 'Rexster # Check REST', label_true: 'CHECKED', handler: ->
      {rexster} = @config.ryba
      graphname = rexster.config.graphs[0].graph['graph-name']
      curl = "curl -u #{rexster.admin.name}:#{rexster.admin.password} "
      curl += "#{rexster.config.http['base-uri']}:#{rexster.config.http['server-port']}"
      curl += "/graphs/#{graphname}/"
      @execute
        cmd: curl
      , (err, executed, stdout) ->
        return if err or not executed
        try
          data = JSON.parse(stdout)
          throw Error "Invalid response: #{JSON.stringify data}" unless data?.name is graphname
        catch e then throw Error "Invalid Command Output: #{JSON.stringify stdout}"

## Dependencies

    path = require 'path'
