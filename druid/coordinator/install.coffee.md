
# Druid Coordinator Install

    module.exports = header: 'Druid Coordinator # Install', handler: ->
      @call once: true, handler: 'ryba/druid/install'

## IPTables

| Service           | Port | Proto    | Parameter                   |
|-------------------|------|----------|-----------------------------|
| Druid Coordinator | 8081 | tcp/http |                             |

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8081, protocol: 'tcp', state: 'NEW', comment: "Druid Coordinator" }
        ]
        if: @config.iptables.action is 'start'

## Configuration

      @render
        header: 'rc.d'
        target: "/etc/init.d/druid-coordinator"
        source: "#{__dirname}/../resources/druid-coordinator.j2"
        context: @config
        local_source: true
        backup: true
        mode: 0o0755
