
# Druid Overlord Install

    module.exports = header: 'Druid Overlord Install', handler: ->
      {druid} = @config.ryba

## IPTables

| Service           | Port | Proto    | Parameter                   |
|-------------------|------|----------|-----------------------------|
| Druid Overlord    | 8090 | tcp/http |                             |

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: druid.overlord.runtime['druid.port'], protocol: 'tcp', state: 'NEW', comment: "Druid Broker" }
        ]
        if: @config.iptables.action is 'start'

## Configuration

      @file.render
        header: 'rc.d'
        target: "/etc/init.d/druid-overlord"
        source: "#{__dirname}/../resources/druid-overlord.j2"
        context: @config
        local: true
        backup: true
        mode: 0o0755
      @file.properties
        target: "/opt/druid-#{druid.version}/conf/druid/overlord/runtime.properties"
        content: druid.overlord.runtime
        backup: true
      @file
        target: "#{druid.dir}/conf/druid/overlord/jvm.config"
        write: [
          match: /^-Xms.*$/m
          replace: "-Xms#{druid.overlord.jvm.xms}"
        ,
          match: /^-Xmx.*$/m
          replace: "-Xmx#{druid.overlord.jvm.xmx}"
        ]
