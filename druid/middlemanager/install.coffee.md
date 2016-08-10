
# Druid MiddleManager Install

    module.exports = header: 'Druid MiddleManager # Install', handler: ->
      @call once: true, handler: 'ryba/druid/install'

## IPTables

| Service             | Port | Proto    | Parameter                   |
|---------------------|------|----------|-----------------------------|
| druid MiddleManager | 8091, 8100–8199 | tcp/http |                             |

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8082, protocol: 'tcp', state: 'NEW', comment: "Druid Broker" }
        ]
        if: @config.iptables.action is 'start'

## Configuration

      @render
        header: 'rc.d'
        target: "/etc/init.d/druid-middlemanager"
        source: "#{__dirname}/../resources/druid-middlemanager.j2"
        context: @config
        local_source: true
        backup: true
        mode: 0o0755
