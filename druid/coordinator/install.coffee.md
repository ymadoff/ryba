
# Druid Coordinator Install

    module.exports = header: 'Druid Coordinator Install', handler: ->
      {druid} = @config.ryba
      @call once: true, 'ryba/druid/install'

## IPTables

| Service           | Port | Proto    | Parameter                   |
|-------------------|------|----------|-----------------------------|
| Druid Coordinator | 8081 | tcp/http |                             |

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: druid.coordinator.runtime['druid.port'], protocol: 'tcp', state: 'NEW', comment: "Druid Coordinator" }
        ]
        if: @config.iptables.action is 'start'

## Configuration

      @file.render
        header: 'rc.d'
        target: "/etc/init.d/druid-coordinator"
        source: "#{__dirname}/../resources/druid-coordinator.j2"
        context: @config
        local: true
        backup: true
        mode: 0o0755
      @file.properties
        target: "/opt/druid-#{druid.version}/conf/druid/coordinator/runtime.properties"
        content: druid.coordinator.runtime
        backup: true
      @file
        target: "#{druid.dir}/conf/druid/coordinator/jvm.config"
        write: [
          match: /^-Xms.*$/m
          replace: "-Xms#{druid.coordinator.jvm.xms}"
        ,
          match: /^-Xmx.*$/m
          replace: "-Xmx#{druid.coordinator.jvm.xmx}"
        ]
