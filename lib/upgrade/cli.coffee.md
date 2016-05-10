
# Upgrade

## Main Entry Point

    module.exports = ->
      # Parameters and Help
      params = parameters(exports.params)
      if params.parse().help
        return util.print(params.help())
      # Run
      params = params.parse()
      config params.config, (err, config) ->
        throw err if err
        upgrade = ""
        switch params.service
          when 'hdfs'
            steps = require "./hdfs.coffee.md"
          when 'yarn'
            steps = require "./yarn.coffee.md"
          when 'hbase'
            steps = require "./hbase.coffee.md"
          when 'hive'
            steps = require "./hive.coffee.md"
          else
            throw Error 'Service is not supported:', params.service
        main params, config, steps, (err) ->
          if err
            if err.errors
              for err in err.errors
                console.log err.stack or err.message
            else
              console.log err.stack
            process.exit 1 if err
          else        
            process.exit 0
        
    contexts = (params, config, callback) ->
      contexts = []
      params = merge {}, params
      params.end = false
      params.modules = [
        'masson/bootstrap/connection'
        'masson/bootstrap/mecano'
        'masson/bootstrap/log'
        'masson/core/yum'
      ]
      run params, config
      .on 'context', (context) ->
        contexts.push context
      .on 'error', callback
      .on 'end', -> callback null, contexts
          
    main = (params, config, steps, callback) ->
      params.easy_download
      config.directory = '/var/ryba/upgrade'
      contexts params, config, (err, contexts) ->
        return callback err if err
        each steps
        .call (middleware, i, next) ->
          return next() if params.start? and i < params.start
          process.stdout.write "[#{i}] #{middleware.header}\n"
          each contexts
          .call (context, j, next) ->
            sign = if j+1 < contexts.length then '├' else '└'
            process.stdout.write " #{sign}  #{context.config.host}: "
            context.call middleware, (err, changed) ->
              if err
                process.stdout.write " ERROR: #{err.message or JSON.stringify err}\n"
                if err.errors
                  for err in err.errors
                    process.stdout.write "   #{err.message}\n"
              else if changed is false or changed is 0
                process.stdout.write " OK"
              else if not changed?
                process.stdout.write " SKIPPED"
              else
                process.stdout.write " CHANGED"
              process.stdout.write '\n'
              next err
          .then next
        .then (err) ->
          process.stdout.write "Disconnecting: "
          context.emit 'end' for context in contexts
          process.stdout.write if err then " ERROR" else ' OK'
          process.stdout.write '\n'
          callback err

          

    
## Parameters

*   `config` (array|string)   
    One or multiple configuration files and directories.   
*   `from` (int|string)   
    The current HDP version being deployed.   
*   `to` (int|string)   
    The target HDP version to deploy.    

```bash
node node_modules/ryba/bin/upgrade
```

    exports.params = 
      name: 'upgrade'
      description: 'Upgrade your Hadoop Cluster'
      options: [
        name: 'config', shortcut: 'c', type: 'array'
        description: 'One or multiple configuration files.'
        required: true
      ,
        name: 'start', shortcut: 's'
        description: 'Middleware to start from'
      ,
        name: 'easy_download', shortcut: 'e', type: 'boolean'
        description: 'Number of concurrent downloads, parallel unless defined'
      ,
        name: 'service', shortcut: 's', tybe: 'string'
        description: 'service to upgrade'
      ]

## Dependencies

    parameters = require 'parameters'
    config = require 'masson/lib/config'
    util = require 'util'
    each = require 'each'
    {merge} = require 'mecano/lib/misc'
    run = require 'masson/lib/run'
