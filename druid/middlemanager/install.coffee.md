
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
        content:
          'druid.service': 'druid/middleManager'
          'druid.port': '8091'
          # Number of tasks per middleManager
          'druid.worker.capacity': '3'
          # Task launch parameters
          'druid.indexer.runner.javaOpts': '-server -Xmx2g -Duser.timezone=UTC -Dfile.encoding=UTF-8 -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager'
          'druid.indexer.task.baseTaskDir': 'var/druid/task'
          # # HTTP server threads
          'druid.server.http.numThreads': '25'
          # Processing threads and buffers
          'druid.processing.buffer.sizeBytes': '536870912'
          'druid.processing.numThreads': '2'
          # Hadoop indexing
          'druid.indexer.task.hadoopWorkingPath': '/tmp/druid-indexing'
          'druid.indexer.task.defaultHadoopCoordinate': '["org.apache.hadoop:hadoop-client:2.3.0"]'
        backup: true
      @render
        header: 'rc.d'
        target: "/etc/init.d/druid-middlemanager"
        source: "#{__dirname}/../resources/druid-middlemanager.j2"
        context: @config
        local_source: true
        backup: true
        mode: 0o0755