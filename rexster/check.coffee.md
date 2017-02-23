
# Rexster Check

    module.exports = header: 'Rexster Check', label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      {titan, rexster} = @config.ryba

## Check Status

Check status using JMX

      @system.execute
        header: 'Status'
        retry: 10
        wait: 10000
        cmd:"""
        #{titan.home}/bin/rexster.sh --status |  grep 'Rexster Server is running'
        """

## Check RexPro

Check REPL (rexster-console.sh). It is not equivalent to Titan REPL, as it use the
binary protocol RexPro.

      #@call header: 'RexPro', skip: true, label_true: 'CHECKED', handler: ->

## Check REST

Text mode of REST Server

      graphname = rexster.config.graphs[0].graph['graph-name']
      curl = "curl -u #{rexster.admin.name}:#{rexster.admin.password} "
      curl += "#{rexster.config.http['base-uri']}:#{rexster.config.http['server-port']}"
      curl += "/graphs/#{graphname}/"
      @system.execute
        header: 'REST API'
        cmd: curl
      , (err, executed, stdout) ->
        return if err or not executed
        try
          data = JSON.parse(stdout)
          throw Error "Invalid response: #{JSON.stringify data}" unless data?.name is graphname
        catch e then throw Error "Invalid Command Output: #{JSON.stringify stdout}"
