
# Druid Historical Install

    module.exports = header: 'Druid Historical Install', handler: ->
      {druid} = @config.ryba

## IPTables

| Service           | Port | Proto    | Parameter                   |
|-------------------|------|----------|-----------------------------|
| Druid Historical  | 8083 | tcp/http |                             |

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: druid.historical.runtime['druid.port'], protocol: 'tcp', state: 'NEW', comment: "Druid Historical" }
        ]
        if: @config.iptables.action is 'start'

## Configuration

      @service.init
        header: 'rc.d'
        target: "/etc/init.d/druid-historical"
        source: "#{__dirname}/../resources/druid-historical.j2"
        context: @config
        local: true
        backup: true
        mode: 0o0755
      @file.properties
        header: 'Runtime'
        target: "/opt/druid-#{druid.version}/conf/druid/historical/runtime.properties"
        content: druid.historical.runtime
        backup: true
      @file
        header: 'JVM'
        target: "#{druid.dir}/conf/druid/historical/jvm.config"
        write: [
          match: /^-Xms.*$/m
          replace: "-Xms#{druid.historical.jvm.xms}"
        ,
          match: /^-Xmx.*$/m
          replace: "-Xmx#{druid.historical.jvm.xmx}"
        ]
      @system.mkdir (
        target: "#{path.resolve druid.dir, location.path}"
        uid: "#{druid.user.name}"
        gid: "#{druid.group.name}"
      ) for location in JSON.parse druid.historical.runtime['druid.segmentCache.locations']

## Dependencies

    path = require 'path'
