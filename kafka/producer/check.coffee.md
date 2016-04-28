
# Kafka Check


    module.exports = header: 'Kafka Producer Check', label_true: 'CHECKED', handler: ->
      {kafka, user} = @config.ryba
      
## Check Messages PLAINTEXT

Check Message by writing to a test topic on the PLAINTEXT channel.

      @call header: 'Check PLAINTEXT', label_true: 'CHECKED', handler: ->
        return unless @has_module 'ryba/kafka/consumer'
        ks_ctxs = @contexts 'ryba/kafka/broker'
        return if ks_ctxs[0].config.ryba.kafka.broker.protocols.indexOf('PLAINTEXT') == -1
        brokers = ks_ctxs.map( (ctx) => #, require('../broker').configure
          "#{ctx.config.host}:#{ctx.config.ryba.kafka.broker.ports['PLAINTEXT']}"
        ).join ','
        test_topic = "check-#{@config.host}-producer-plaintext-topic"
        zoo_connect = ks_ctxs[0].config.ryba.kafka.broker.config['zookeeper.connect']
        @execute
          if: kafka.producer.env['KAFKA_KERBEROS_PARAMS']?
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
          unless: kafka.producer.env['KAFKA_KERBEROS_PARAMS']?
          cmd: """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create \
              --zookeeper #{zoo_connect} --partitions 1 --replication-factor 3 \
              --topic #{test_topic}
            """
          unless_exec: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --list \
            --zookeeper #{zoo_connect} | grep #{test_topic}
            """
        @execute
          cmd: """
          (
            echo 'hello front1' | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh \
              --new-producer \
              --producer-property security.protocol=PLAINTEXT \
              --broker-list #{brokers} \
              --security-protocol PLAINTEXT \
              --producer.config #{kafka.producer.conf_dir}/producer.properties \
              --topic #{test_topic}
          )&
          /usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh \
            --new-consumer \
            --bootstrap-server #{brokers} \
            --topic #{test_topic} \
            --security-protocol PLAINTEXT \
            --property security.protocol=PLAINTEXT \
            --consumer.config #{kafka.consumer.conf_dir}/consumer.properties \
            --zookeeper #{zoo_connect} --from-beginning --max-messages 1 | grep 'hello front1'
          """

## Check Messages SSL

Check Message by writing to a test topic on the SSL channel.
We specify the trustore location and password because if executed before consumer install
'/etc/kafka/conf/consumer.properties' might be empty

      @call
        header: 'Check SSL'
        label_true: 'CHECKED'
        if: -> @has_module 'ryba/kafka/consumer'
        handler: ->
          ks_ctxs = @contexts 'ryba/kafka/broker'
          return if ks_ctxs[0].config.ryba.kafka.broker.protocols.indexOf('SSL') == -1
          brokers = ks_ctxs.map( (ctx) => #, require('../broker').configure
            "#{ctx.config.host}:#{ctx.config.ryba.kafka.broker.ports['SSL']}"
          ).join ','
          test_topic = "check-#{@config.host}-producer-ssl-topic"
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
                --new-consumer \
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

      @call
        header: 'Check SASL_PLAINTEXT'
        label_true: 'CHECKED'
        if: -> @has_module 'ryba/kafka/consumer'
        # skip: true
        handler: ->
          ks_ctxs = @contexts 'ryba/kafka/broker'
          return if ks_ctxs[0].config.ryba.kafka.broker.protocols.indexOf('SASL_PLAINTEXT') == -1
          brokers = ks_ctxs.map( (ctx) => #, require('../broker').configure
            "#{ctx.config.host}:#{ctx.config.ryba.kafka.broker.ports['SASL_PLAINTEXT']}"
          ).join ','
          test_topic = "check-#{@config.host}-producer-sasl-plaintext-topic"
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
Specifying also the trustore location and password because if executed before consumer install
'/etc/kafka/conf/consumer.properties' might be empty

      @call
        header: 'Check SASL_SSL'
        label_true: 'CHECKED'
        if: -> @has_module 'ryba/kafka/consumer'
        handler: ->
          ks_ctxs = @contexts 'ryba/kafka/broker'
          return if ks_ctxs[0].config.ryba.kafka.broker.protocols.indexOf('SASL_SSL') == -1
          brokers = ks_ctxs.map( (ctx) => #, require('../broker').configure
            "#{ctx.config.host}:#{ctx.config.ryba.kafka.broker.ports['SASL_SSL']}"
          ).join ','
          test_topic = "check-#{@config.host}-producer-sasl-ssl-topic"
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
