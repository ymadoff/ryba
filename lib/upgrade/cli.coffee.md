
# Upgrade

## Parameters

*   `config` (array|string)   
    One or multiple configuration files and directories.   
*   `from` (int|string)   
    The current HDP version being deployed.   
*   `to` (int|string)   
    The target HDP version to deploy.    

```bash
node node_modules/ryba/bin/upgrade \
  -f 2.1 \
  -t 2.2
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
      ]

## Dependencies

    parameters = require 'parameters'
    config = require 'masson/lib/config'
    upgrade = require './upgrade_2.1-2.2'
    util = require 'util'

## Parameters and Help

    params = parameters(exports.params)
    if params.parse().help
      return util.print(params.help())

## Main Entry Point

    params = params.parse()
    config params.config, (err, config) ->
      throw err if err
      upgrade params, config, (err) ->
        if err
          if err.errors
            for err of err.errors
              console.log err.stack or err.message
          else
            console.log err.stack