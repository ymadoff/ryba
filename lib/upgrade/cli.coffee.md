
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
        upgrade = require "./upgrade_#{params.from}-#{params.to}"
        upgrade params, config, (err) ->
          if err
            if err.errors
              for err in err.errors
                console.log err.stack or err.message
            else
              console.log err.stack

## Parameters

*   `config` (array|string)   
    One or multiple configuration files and directories.   
*   `from` (int|string)   
    The current HDP version being deployed.   
*   `to` (int|string)   
    The target HDP version to deploy.    

```bash
node node_modules/ryba/bin/upgrade \
  -f 2.2 \
  -t 2.3
```

    exports.params = 
      name: 'upgrade'
      description: 'Upgrade your Hadoop Cluster'
      options: [
        name: 'config', shortcut: 'c', type: 'array'
        description: 'One or multiple configuration files.'
        required: true
      ,
        name: 'from', shortcut: 'f'
        description: 'Current version.'
        required: true
      ,
        name: 'to', shortcut: 't'
        description: 'Target version.'
        required: true
      ,
        name: 'start', shortcut: 's'
        description: 'Middleware to start from'
      ,
        name: 'easy_download', shortcut: 'e', type: 'boolean'
        description: 'Number of concurrent downloads, parallel unless defined'
      ]

## Dependencies

    parameters = require 'parameters'
    config = require 'masson/lib/config'
    util = require 'util'
