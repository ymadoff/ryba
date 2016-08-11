
# Druid Historical Install

    module.exports = header: 'Druid Historical # Install', handler: ->
      @call once: true, handler: 'ryba/druid/install'

## IPTables

| Service           | Port | Proto    | Parameter                   |
|-------------------|------|----------|-----------------------------|
| Druid Historical  | 8083 | tcp/http |                             |

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8082, protocol: 'tcp', state: 'NEW', comment: "Druid Broker" }
        ]
        if: @config.iptables.action is 'start'

## Configuration

      @render
        header: 'rc.d'
        target: "/etc/init.d/druid-historical"
        source: "#{__dirname}/../resources/druid-historical.j2"
        context: @config
        local_source: true
        backup: true
        mode: 0o0755
