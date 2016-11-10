
# Druid Broker Install

    module.exports = header: 'Druid Broker Install', handler: ->
      {druid} = @config.ryba
      @call once: true, handler: 'ryba/druid/install'
 
## IPTables

| Service      | Port | Proto    | Parameter                   |
|--------------|------|----------|-----------------------------|
| Druid Broker | 8082 | tcp/http |                             |

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: druid.broker.runtime['druid.port'], protocol: 'tcp', state: 'NEW', comment: "Druid Broker" }
        ]
        if: @config.iptables.action is 'start'

## Configuration

      @render
        header: 'rc.d'
        target: "/etc/init.d/druid-broker"
        source: "#{__dirname}/../resources/druid-broker.j2"
        context: @config
        local_source: true
        backup: true
        mode: 0o0755
      @file.properties
        target: "/opt/druid-#{druid.version}/conf/druid/broker/runtime.properties"
        content: druid.broker.runtime
        backup: true
      @file
        target: "#{druid.dir}/conf/druid/broker/jvm.config"
        write: [
          match: /^-Xms.*$/m
          replace: "-Xms#{druid.broker.jvm.xms}"
        ,
          match: /^-Xmx.*$/m
          replace: "-Xmx#{druid.broker.jvm.xmx}"
        ]
