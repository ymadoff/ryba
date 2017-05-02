
# Falcon Client Install

This procedure only support 1 Oozie server. If Falcon must interact with
multiple servers, then each Oozie server must be updated. The property
"oozie.service.HadoopAccessorService.hadoop.configurations" shall define
each HDFS cluster.

    module.exports = header: 'Falcon Install', handler: ->
      {falcon} = @config.ryba
      [falcon_ctx] = @contexts 'ryba/falcon/server', require('./configure').handler

## Identities

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep falcon
falcon:x:496:498:Falcon:/var/lib/falcon:/bin/bash
cat /etc/group | grep falcon
falcon:x:498:falcon
```

      @system.group header: 'Group', falcon.client.group
      @system.user header: 'User', falcon.client.user

## Packages

      @service
        header: 'Package'
        name: 'falcon'

## Configuration

Update the configuration file in "/etc/falcon/conf/client.properties"

      @file.ini
        header: 'Configuration'
        target: "#{falcon.client.conf_dir}/client.properties"
        content:
          'falcon.url': falcon_ctx.config.ryba.falcon.runtime['prism.falcon.local.endpoint']

## Dependencies

    url = require 'url'
