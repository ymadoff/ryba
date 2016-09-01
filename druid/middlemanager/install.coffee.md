
# Druid MiddleManager Install

    module.exports = header: 'Druid MiddleManager # Install', handler: ->
      @call once: true, handler: 'ryba/druid/install'
      {druid} = @config.ryba

## IPTables

| Service             | Port | Proto    | Parameter                   |
|---------------------|------|----------|-----------------------------|
| Druid MiddleManager | 8091, 8100–8199 | tcp/http |                             |

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8091, protocol: 'tcp', state: 'NEW', comment: "Druid MiddleManager" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: '8100–8199', protocol: 'tcp', state: 'NEW', comment: "Druid MiddleManager" }
        ]
        if: @config.iptables.action is 'start'

## Configuration

      @write.properties
        target: "/opt/druid-#{druid.version}/conf/druid/_common/common.runtime.properties"
        content: druid.runtime
        backup: true
      @render
        header: 'rc.d'
        target: "/etc/init.d/druid-middlemanager"
        source: "#{__dirname}/../resources/druid-middlemanager.j2"
        context: @config
        local_source: true
        backup: true
        mode: 0o0755
