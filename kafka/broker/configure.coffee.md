
## Configure Kafka Broker
Example:

```json
{
  "ryba": {
    "kafka": {
      "broker": {
        "heapsize": 1024
      }
    }
  }
}
```

    module.exports = ->
      kafka = @config.ryba.kafka ?= {}
      # Group
      kafka.group = name: kafka.group if typeof kafka.group is 'string'
      kafka.group ?= {}
      kafka.group.name ?= 'kafka'
      kafka.group.system ?= true
      # User
      kafka.user ?= {}
      kafka.user = name: kafka.user if typeof kafka.user is 'string'
      kafka.user.name ?= kafka.group.name
      kafka.user.system ?= true
      kafka.user.comment ?= 'Kafka User'
      kafka.user.home = "/var/lib/#{kafka.user.name}"
      kafka.user.gid = kafka.group.name
      # ZooKeeper Quorun
      zoo_ctxs = @contexts 'ryba/zookeeper/server'
      zookeeper_quorum = kafka.zookeeper_quorum ?= for zoo_ctx in zoo_ctxs
        "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}"
      kafka.admin ?= {}
      kafka.admin.principal ?= kafka.user.name
      kafka.admin.password ?= 'kafka123'
      #list of kafka superusers
      kafka.superusers ?= ["#{kafka.admin.principal}"]

# Configuration

      kafka.broker ?= {}
      # Layout
      kafka.broker.conf_dir ?= '/etc/kafka-broker/conf'
      kafka.broker['heapsize'] ?= '1024'
      kafka.broker.config ?= {}
      if @config.metric_sinks?.graphite?
        kafka.broker.config['kafka.metrics.reporters'] ?= 'com.criteo.kafka.KafkaGraphiteMetricsReporter'
        kafka.broker.config['kafka.graphite.metrics.reporter.enabled'] ?= 'true'
        kafka.broker.config['kafka.graphite.metrics.host'] ?= @config.metric_sinks.graphite.server_host
        kafka.broker.config['kafka.graphite.metrics.port'] ?= @config.metric_sinks.graphite.server_port
        kafka.broker.config['kafka.graphite.metrics.group'] ?= "#{@config.metric_sinks.graphite.metrics_prefix}.#{@config.host}"
      kafka.broker.config['log.dirs'] ?= '/var/kafka'  # Comma-separated, default is "/tmp/kafka-logs"
      kafka.broker.config['log.dirs'] = kafka.broker['log.dirs'].join ',' if Array.isArray kafka.broker['log.dirs']
      kafka.broker.config['zookeeper.connect'] ?= zookeeper_quorum
      kafka.broker.config['log.retention.hours'] ?= '168'
      kafka.broker.config['delete.topic.enable'] ?= 'true'
      kafka.broker.config['zookeeper.set.acl'] ?= 'true'
      kafka.broker.config['super.users'] ?= kafka.superusers.map( (user) -> "User:#{user}").join(',')
      hosts = @contexts('ryba/kafka/broker').map (ctx) -> ctx.config.host
      kafka.broker.config['num.partitions'] ?= hosts.length # Default number of log partitions per topic, default is "2"
      for host, i in hosts
        kafka.broker.config['broker.id'] ?= "#{i}" if host is @config.host

# Environment

      kafka.broker.env ?= {}
      # A more agressive configuration for production is provided here:
      # http://docs.confluent.io/1.0.1/kafka-rest/docs/deployment.html#jvm
      kafka.broker.env['KAFKA_HEAP_OPTS'] ?= "-Xmx#{kafka.broker['heapsize']}m -Xms#{kafka.broker['heapsize']}m"

      # Log4J
      # Avoid console verbose ouput in a non-rotated kafka.out file
      # kafka.broker.env['KAFKA_LOG4J_OPTS'] ?= "-Dlog4j.configuration=file:$base_dir/../config/log4j.properties -Dkafka.root.logger=INFO, kafkaAppender"
      kafka.broker.env['KAFKA_LOG4J_OPTS'] ?= "-Dlog4j.configuration=file:#{kafka.broker.conf_dir}/log4j.properties"
      kafka.broker.log4j ?= {}
      kafka.broker.log4j[k] ?= v for k, v of @config.log4j
      config = kafka.broker.log4j.config ?= {}
      config['log4j.appender.stdout'] ?= 'org.apache.log4j.ConsoleAppender'
      config['log4j.appender.stdout.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.stdout.layout.ConversionPattern'] ?= '[%d] %p %m (%c)%n'
      config['log4j.appender.kafkaAppender'] ?= 'org.apache.log4j.RollingFileAppender'
      config['log4j.appender.kafkaAppender.MaxFileSize'] ?= '10MB'
      config['log4j.appender.kafkaAppender.MaxBackupIndex'] ?= '1'
      config['log4j.appender.kafkaAppender.File'] ?= '${kafka.logs.dir}/server.log'
      config['log4j.appender.kafkaAppender.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.kafkaAppender.layout.ConversionPattern'] ?= '[%d] %p %m (%c)%n'
      config['log4j.appender.stateChangeAppender'] ?= 'org.apache.log4j.RollingFileAppender'
      config['log4j.appender.stateChangeAppender.MaxFileSize'] ?= '10MB'
      config['log4j.appender.stateChangeAppender.MaxBackupIndex'] ?= '1'
      config['log4j.appender.stateChangeAppender.File'] ?= '${kafka.logs.dir}/state-change.log'
      config['log4j.appender.stateChangeAppender.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.stateChangeAppender.layout.ConversionPattern'] ?= '[%d] %p %m (%c)%n'
      config['log4j.appender.requestAppender'] ?= 'org.apache.log4j.RollingFileAppender'
      config['log4j.appender.requestAppender.MaxFileSize'] ?= '10MB'
      config['log4j.appender.requestAppender.MaxBackupIndex'] ?= '1'
      config['log4j.appender.requestAppender.File'] ?= '${kafka.logs.dir}/kafka-request.log'
      config['log4j.appender.requestAppender.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.requestAppender.layout.ConversionPattern'] ?= '[%d] %p %m (%c)%n'
      config['log4j.appender.cleanerAppender'] ?= 'org.apache.log4j.RollingFileAppender'
      config['log4j.appender.cleanerAppender.MaxFileSize'] ?= '10MB'
      config['log4j.appender.cleanerAppender.MaxBackupIndex'] ?= '1'
      config['log4j.appender.cleanerAppender.File'] ?= '${kafka.logs.dir}/log-cleaner.log'
      config['log4j.appender.cleanerAppender.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.cleanerAppender.layout.ConversionPattern'] ?= '[%d] %p %m (%c)%n'
      config['log4j.appender.controllerAppender'] ?= 'org.apache.log4j.RollingFileAppender'
      config['log4j.appender.controllerAppender.MaxFileSize'] ?= '10MB'
      config['log4j.appender.controllerAppender.MaxBackupIndex'] ?= '1'
      config['log4j.appender.controllerAppender.File'] ?= '${kafka.logs.dir}/controller.log'
      config['log4j.appender.controllerAppender.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.controllerAppender.layout.ConversionPattern'] ?= '[%d] %p %m (%c)%n'
      config['log4j.appender.authorizerAppender'] ?= 'org.apache.log4j.RollingFileAppender'
      config['log4j.appender.authorizerAppender.MaxFileSize'] ?= '10MB'
      config['log4j.appender.authorizerAppender.MaxBackupIndex'] ?= '1'
      config['log4j.appender.authorizerAppender.File'] ?= '${kafka.logs.dir}/kafka-authorizer.log'
      config['log4j.appender.authorizerAppender.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.authorizerAppender.layout.ConversionPattern'] ?= '[%d] %p %m (%c)%n'
      kafka.broker.log4j.extra_appender = ''
      if kafka.broker.log4j.remote_host and kafka.broker.log4j.remote_port
        kafka.broker.log4j.extra_appender = ',socketAppender'
        config['log4j.appender.socketAppender'] ?= 'org.apache.log4j.net.SocketAppender'
        config['log4j.appender.socketAppender.Application'] ?= 'kafka'
        config['log4j.appender.socketAppender.RemoteHost'] ?= kafka.broker.log4j.remote_host
        config['log4j.appender.socketAppender.Port'] ?= kafka.broker.log4j.remote_port
        config['log4j.appender.socketAppender.ReconnectionDelay'] ?= '10000'
      #config['log4j.logger.kafka.producer.async.DefaultEventHandler'] ?= 'DEBUG, kafkaAppender' + kafka.broker.log4j.extra_appender
      #config['log4j.logger.kafka.client.ClientUtils'] ?= 'DEBUG, kafkaAppender' + kafka.broker.log4j.extra_appender
      #config['log4j.logger.kafka.perf'] ?= 'DEBUG, kafkaAppender' + ' socketAppender' + kafka.broker.log4j.extra_appender
      #config['log4j.logger.kafka.perf.ProducerPerformance$ProducerThread'] ?= 'DEBUG, kafkaAppender' + kafka.broker.log4j.extra_appender
      #config['log4j.logger.org.I0Itec.zkclient.ZkClient'] ?= 'DEBUG'
      #config['log4j.logger.kafka.network.Processor'] ?= 'TRACE, requestAppender' + kafka.broker.log4j.extra_appender
      #config['log4j.logger.kafka.server.KafkaApis'] ?= 'TRACE, requestAppender' + kafka.broker.log4j.extra_appender
      #config['log4j.additivity.kafka.server.KafkaApis'] ?= 'false'
      config['log4j.rootLogger'] ?= 'INFO, kafkaAppender' + kafka.broker.log4j.extra_appender
      config['log4j.logger.kafka'] ?= 'INFO, kafkaAppender' + kafka.broker.log4j.extra_appender
      config['log4j.additivity.kafka'] ?= 'false'
      config['log4j.logger.kafka.network.RequestChannel$'] ?= 'WARN, requestAppender' + kafka.broker.log4j.extra_appender
      config['log4j.additivity.kafka.network.RequestChannel$'] ?= 'false'
      config['log4j.logger.kafka.request.logger'] ?= 'WARN, requestAppender' + kafka.broker.log4j.extra_appender
      config['log4j.additivity.kafka.request.logger'] ?= 'false'
      config['log4j.logger.kafka.controller'] ?= 'TRACE, controllerAppender' + kafka.broker.log4j.extra_appender
      config['log4j.additivity.kafka.controller'] ?= 'false'
      config['log4j.logger.kafka.log.LogCleaner'] ?= 'INFO, cleanerAppender' + kafka.broker.log4j.extra_appender
      config['log4j.additivity.kafka.log.LogCleaner'] ?= 'false'
      config['log4j.logger.state.change.logger'] ?= 'TRACE, stateChangeAppender' + kafka.broker.log4j.extra_appender
      config['log4j.additivity.state.change.logger'] ?= 'false'
      config['log4j.logger.kafka.authorizer.logger'] ?= 'WARN, authorizerAppender' + kafka.broker.log4j.extra_appender
      config['log4j.additivity.kafka.authorizer.logger'] ?= 'false'

      # Push user and group configuration to consumer and producer
      # for csm_ctx in ctx.contexts ['ryba/kafka/consumer', 'ryba/kafka/producer']
      #   csm_ctx.config.ryba ?= {}
      #   csm_ctx.config.ryba.kafka ?= {}
      #   csm_ctx.config.ryba.kafka.user ?= kafka.user
      #   csm_ctx.config.ryba.kafka.group ?= kafka.group

## Kafka Broker Protocols

Sarting from 0.9, kafka broker supports multiple secured and un-secured protocols when
broadcasting messages for broker/broker and client/broker communications.
They are PLAINTEXT, SSL, SASL_PLAINTEXT, SASL_SSL.
By default it set at least to SSL for broker/broker and client/broker.
For broker/client communication all protocols are supported.
For broker/broker communication we allow only SSL or SASL_SSL.
Needed protocols can be set at cluster config level.

Example only PLAINTEXT:
{
  "ryba": {
    "kafka": {
      "broker": {
        "protocols" : "PLAINTEXT"
      }
    }
  }
}
Example PLAINTEXT and SSL:
{
  "ryba": {
    "kafka": {
      "broker": {
        "protocols" : ["PLAINTEXT","SSL"]
      }
    }
  }
}

      kafka.broker.protocols ?= if @config.ryba.security is 'kerberos' then ['SASL_SSL'] else ['SSL']
      return Error 'No protocol specified' unless kafka.broker.protocols.length > 0
      kafka.broker.ports ?= {}
      kafka.broker.ports['PLAINTEXT'] ?= '9092'
      kafka.broker.ports['SSL'] ?= '9093'
      kafka.broker.ports['SASL_PLAINTEXT'] ?= '9094'
      kafka.broker.ports['SASL_SSL'] ?= '9096'

## Security protocol used to communicate between brokers

Valid values are: PLAINTEXT, SSL, SASL_PLAINTEXT, SASL_SSL.

      kafka.broker.config['security.inter.broker.protocol'] ?= if @config.ryba.security is 'kerberos' then ['SASL_SSL'] else ['SSL']

## Security SSL

      # for protocol in kafka.broker.protocols
      #   continue unless ['SASL_SSL','SSL'].indexOf(protocol) > -1
      kafka.broker.config['ssl.keystore.location'] ?= "#{kafka.broker.conf_dir}/keystore"
      kafka.broker.config['ssl.keystore.password'] ?= 'ryba123'
      kafka.broker.config['ssl.key.password'] ?= 'ryba123'
      kafka.broker.config['ssl.truststore.location'] ?= "#{kafka.broker.conf_dir}/truststore"
      kafka.broker.config['ssl.truststore.password'] ?= 'ryba123'

## Security Kerberos & ACL

      secure_cluster = false
      if kafka.broker.config['zookeeper.set.acl'] is 'true'
        secure_cluster = true
        kafka.broker.kerberos ?= {}
        kafka.broker.kerberos['principal'] ?= "#{kafka.user.name}/#{@config.host}@#{@config.ryba.realm}"
        kafka.broker.kerberos['keyTab'] ?= '/etc/security/keytabs/kafka.service.keytab'
        match = /^(.+?)[@\/]/.exec kafka.broker.kerberos['principal']
        kafka.broker.config['sasl.kerberos.service.name'] = "#{match[1]}"
        # set to true to be able to use 9092 if PLAINTEXT only mode is enabled
        kafka.broker.config['allow.everyone.if.no.acl.found'] ?= 'false'
        kafka.broker.config['authorizer.class.name'] ?= 'kafka.security.auth.SimpleAclAuthorizer'
        kafka.broker.env['KAFKA_KERBEROS_PARAMS'] ?= "-Djava.security.auth.login.config=#{kafka.broker.conf_dir}/kafka-server.jaas"

## Brokers internal communication

        kafka.broker.config['replication.security.protocol'] ?= 'SASL_SSL'
      else
        kafka.broker.config['replication.security.protocol'] ?= 'SSL'
      for prot in kafka.broker.protocols
          throw Error 'ACL must be activated' if ( prot.indexOf('SASL') > -1 and not secure_cluster)

## Listeners Protocols

      #HDP 2.5.0
      error = 'security.inter.broker.protocol must be a protocol in the configured set of advertised.listeners'
      throw Error error unless kafka.broker.config['replication.security.protocol'] in kafka.broker.protocols
      kafka.broker.config['listeners'] ?= kafka.broker.protocols.map( (protocol) =>
        "#{protocol}://#{@config.host}:#{kafka.broker.ports[protocol]}").join(',')

[kafka-security]:(http://kafka.apache.org/documentation.html#security)
[hdp-security-kafka]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.4/bk_Security_Guide/content/ch_wire-kafka.html)
