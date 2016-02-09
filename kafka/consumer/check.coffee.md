
# Kafka Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/kafka/broker/wait'

## Check Messages PLAINTEXT

Check Message by writing to a test topic on the PLAINTEXT channel.

    module.exports.push
      header: 'Kafka Consumer # Check PLAINTEXT'
      label_true: 'CHECKED'
      if: -> @has_module 'ryba/kafka/producer'
      handler: ->
        ks_ctxs = @contexts 'ryba/kafka/broker'
        return if ks_ctxs[0].config.ryba.kafka.broker.protocols.indexOf('PLAINTEXT') == -1
        {kafka} = @config.ryba
        test_topic = "check-#{@config.host}-consumer-plaintext-topic"
        brokers = ks_ctxs.map( (ctx) => #, require('../broker').configure
          "#{ctx.config.host}:#{ctx.config.ryba.kafka.ports['PLAINTEXT']}"
        ).join ','
        @execute
          cmd: """
          (
            echo 'hello front1' | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh \
              --broker-list #{brokers} \
              --topic #{test_topic}
          )&
          /usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh \
            --topic #{test_topic} \
            --zookeeper #{kafka.consumer.config['zookeeper.connect']} --from-beginning --max-messages 1 | grep 'hello front1'
          """

## Check Messages SSL

Check Message by writing to a test topic on the SSL channel.
Trustore location and password given to line command because if executed before producer install
'/etc/kafka/conf/producer.properties' might be empty.

    module.exports.push
      header: 'Kafka Consumer # Check SSL'
      label_true: 'CHECKED'
      if: -> @has_module 'ryba/kafka/producer'
      handler: ->
        ks_ctxs = @contexts 'ryba/kafka/broker'
        return if ks_ctxs[0].config.ryba.kafka.broker.protocols.indexOf('SSL') == -1
        {kafka, user} = @config.ryba
        brokers = ks_ctxs.map( (ctx) => #, require('../broker').configure
          "#{ctx.config.host}:#{ctx.config.ryba.kafka.ports['SSL']}"
        ).join ','
        test_topic = "check-#{@config.host}-consumer-ssl-topic"
        zoo_connect = ks_ctxs[0].config.ryba.kafka.broker.config['zookeeper.connect']
        @execute
          cmd:  """
            echo 'hello front1' | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh \
              --new-producer  \
              --producer-property security.protocol=SSL \
              --broker-list #{brokers} \
              --security-protocol SSL \
              --producer-property ssl.truststore.location=#{kafka.producer.config['ssl.truststore.location']} \
              --producer-property ssl.truststore.password=#{kafka.producer.config['ssl.truststore.password']} \
              --producer.config #{kafka.producer.conf_dir}/producer.properties \
              --topic #{test_topic}
          """
        @execute
          cmd: """
            /usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh \
              --new-consumer  \
              --bootstrap-server #{brokers} \
              --topic #{test_topic} \
              --security-protocol SSL \
              --property security.protocol=SSL \
              --property ssl.truststore.location=#{kafka.consumer.config['ssl.truststore.location']} \
              --property ssl.truststore.password=#{kafka.consumer.config['ssl.truststore.password']} \
              --consumer.config #{kafka.consumer.conf_dir}/consumer.properties \
              --zookeeper #{zoo_connect} --from-beginning --max-messages 1 | grep 'hello front1'
            """

## Check Messages SASL_PLAINTEXT

Check Message by writing to a test topic on the SASL_PLAINTEXT channel.

    module.exports.push
      header: 'Kafka Consumer # Check SASL_PLAINTEXT'
      label_true: 'CHECKED'
      if: -> @has_module 'ryba/kafka/producer'
      # skip: true
      handler: ->
        ks_ctxs = @contexts 'ryba/kafka/broker'
        return if ks_ctxs[0].config.ryba.kafka.broker.protocols.indexOf('SASL_PLAINTEXT') == -1
        {kafka, user} = @config.ryba
        brokers = ks_ctxs.map( (ctx) => #, require('../broker').configure
          "#{ctx.config.host}:#{ctx.config.ryba.kafka.ports['SASL_PLAINTEXT']}"
        ).join ','
        test_topic = "check-#{@config.host}-consumer-sasl-plaintext-topic"
        zoo_connect = ks_ctxs[0].config.ryba.kafka.broker.config['zookeeper.connect']
        @execute
          cmd: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create \
              --zookeeper #{zoo_connect} --partitions 1 --replication-factor 3 \
              --topic #{test_topic}
            """
          unless_exec: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --list \
            --zookeeper #{zoo_connect} | grep #{test_topic}
            """
        @execute
          cmd: mkcmd.kafka @, """
            (
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=#{zoo_connect} \
              --add --allow-principal User:#{user.name}  \
              --operation Read --operation Write --topic #{test_topic}
            )&
            (
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=#{zoo_connect} \
              --add \
              --allow-principal User:#{user.name} --consumer --group #{user.name} --topic #{test_topic}
            )
            """
          unless_exec: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh  --list \
              --authorizer-properties zookeeper.connect=#{zoo_connect}  \
              --topic #{test_topic} | grep 'User:#{user.name} has Allow permission for operations: Write from hosts: *'
            """
        @execute
          cmd:  mkcmd.test @, """
            (
              echo 'hello front1' | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh \
                --new-producer  \
                --producer-property security.protocol=SASL_PLAINTEXT \
                --broker-list #{brokers} \
                --security-protocol SASL_PLAINTEXT \
                --producer.config #{kafka.producer.conf_dir}/producer.properties \
                --topic #{test_topic}
            )&
            /usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh \
              --new-consumer \
              --bootstrap-server #{brokers} \
              --topic #{test_topic} \
              --security-protocol SASL_PLAINTEXT \
              --zookeeper #{zoo_connect} --from-beginning --max-messages 1 | grep 'hello front1'
            """

## Check Messages SASL_SSL

Check Message by writing to a test topic on the SASL_SSL channel.
Trustore location and password given to line command because if executed before producer install
'/etc/kafka/conf/producer.properties' might be empty.

    module.exports.push
      header: 'Kafka Consumer # Check SASL_SSL'
      label_true: 'CHECKED'
      if: -> @has_module 'ryba/kafka/producer'
      handler: ->
        ks_ctxs = @contexts 'ryba/kafka/broker'
        return if ks_ctxs[0].config.ryba.kafka.broker.protocols.indexOf('SASL_SSL') == -1
        {kafka, user} = @config.ryba
        brokers = ks_ctxs.map( (ctx) => #, require('../broker').configure
          "#{ctx.config.host}:#{ctx.config.ryba.kafka.ports['SASL_SSL']}"
        ).join ','
        test_topic = "check-#{@config.host}-consumer-sasl-ssl-topic"
        zoo_connect = ks_ctxs[0].config.ryba.kafka.broker.config['zookeeper.connect']
        @execute
          cmd: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create \
              --zookeeper #{zoo_connect} --partitions 1 --replication-factor 3 \
              --topic #{test_topic}
            """
          unless_exec: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --list \
            --zookeeper #{zoo_connect} | grep #{test_topic}
            """
        @execute
          cmd: mkcmd.kafka @, """
            (
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=#{zoo_connect} \
              --add --allow-principal User:#{user.name}  \
              --operation Read --operation Write --topic #{test_topic}
            )&
            (
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=#{zoo_connect} \
              --add \
              --allow-principal User:#{user.name} --consumer --group #{user.name} --topic #{test_topic}
            )
            """
          unless_exec: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh  --list \
              --authorizer-properties zookeeper.connect=#{zoo_connect}  \
              --topic #{test_topic} | grep 'User:#{user.name} has Allow permission for operations: Write from hosts: *'
            """
        @execute
          cmd:  mkcmd.test @, """
            (
              echo 'hello front1' | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh \
                --new-producer  \
                --producer-property security.protocol=SASL_SSL \
                --broker-list #{brokers} \
                --security-protocol SASL_SSL \
                --producer-property ssl.truststore.location=#{kafka.producer.config['ssl.truststore.location']} \
                --producer-property ssl.truststore.password=#{kafka.producer.config['ssl.truststore.password']} \
                --producer.config #{kafka.producer.conf_dir}/producer.properties \
                --topic #{test_topic}
            )&
            /usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh \
              --new-consumer \
              --bootstrap-server #{brokers} \
              --topic #{test_topic} \
              --security-protocol SASL_SSL \
              --property security.protocol=SASL_SSL \
              --property ssl.truststore.location=#{kafka.consumer.config['ssl.truststore.location']} \
              --property ssl.truststore.password=#{kafka.consumer.config['ssl.truststore.password']} \
              --consumer.config #{kafka.consumer.conf_dir}/consumer.properties \
              --zookeeper #{zoo_connect} --from-beginning --max-messages 1 | grep 'hello front1'
            """

## Dependencies

    mkcmd = require '../../lib/mkcmd'
