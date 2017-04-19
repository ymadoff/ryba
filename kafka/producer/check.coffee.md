
# Kafka Check


    module.exports = header: 'Kafka Producer Check', label_true: 'CHECKED', handler: ->
      {kafka, user} = @config.ryba
      [ranger_admin] = @contexts 'ryba/ranger/admin'
      protocols = kafka.producer.protocols

## Wait

      @call once: true, 'masson/core/krb5_client/wait'
      @call once: true, 'ryba/zookeeper/server/wait'
      @call once: true, 'ryba/kafka/broker/wait'
      @call if: ranger_admin?, once: true, 'ryba/ranger/admin/wait'

## Add Ranger Policy

      @call header: 'Add Kafka Policy', if: ranger_admin?, ->
        {install} = ranger_admin.config.ryba.ranger.kafka_plugin
        policy_name = "test-ryba-producer-#{@config.host}"
        topics = protocols.map (prot) =>
          "check-#{@config.host}-producer-#{prot.toLowerCase().split('_').join('-')}-topic"
        users = ["#{user.name}"]
        users.push 'ANONYMOUS' if ('PLAINTEXT' in protocols) or ('SSL' in protocols)
        kafka_policy =
          service: "#{install['REPOSITORY_NAME']}"
          name: policy_name
          description: "Policy for ryba kafka producer test"
          isAuditEnabled: true
          resources:
            topic:
              values: topics
              isExcludes: false
              isRecursive: false
          'policyItems': [
              "accesses": [
                'type': 'publish'
                'isAllowed': true
              ,
                'type': 'consume'
                'isAllowed': true
              ,
                'type': 'configure'
                'isAllowed': true
              ,
                'type': 'describe'
                'isAllowed': true
              ,
                'type': 'create'
                'isAllowed': true
              ,
                'type': 'delete'
                'isAllowed': true
              ,
                'type': 'kafka_admin'
                'isAllowed': true
              ],
              'users': users
              'groups': []
              'conditions': []
              'delegateAdmin': true
            ]
        @wait.execute
          cmd: """
            curl --fail -H \"Content-Type: application/json\"   -k -X GET  \
            -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
            \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{install['REPOSITORY_NAME']}\"
          """
          code_skipped: [1,7,22] #22 is for 404 not found,7 is for not connected to host
        @system.execute
          cmd: """
            curl --fail -H "Content-Type: application/json" -k -X POST \
            -d '#{JSON.stringify kafka_policy}' \
            -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
            \"#{install['POLICY_MGR_URL']}/service/public/v2/api/policy\"
          """
          unless_exec: """
            curl --fail -H \"Content-Type: application/json\" -k -X GET  \ 
            -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
            \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/#{install['REPOSITORY_NAME']}/policy/#{policy_name}\"
          """
        @wait
          time: 10000
          if: -> @status -1

## Check Messages PLAINTEXT

Check Message by writing to a test topic on the PLAINTEXT channel.

      @call header: 'Check PLAINTEXT', label_true: 'CHECKED', retry: 3, ->
        return unless @has_service  'ryba/kafka/consumer'
        ks_ctxs = @contexts 'ryba/kafka/broker'
        return if ks_ctxs[0].config.ryba.kafka.broker.protocols.indexOf('PLAINTEXT') == -1
        brokers = ks_ctxs.map( (ctx) => #, require('../broker').configure
          "#{ctx.config.host}:#{ctx.config.ryba.kafka.broker.ports['PLAINTEXT']}"
        ).join ','
        test_topic = "check-#{@config.host}-producer-plaintext-topic"
        zoo_connect = ks_ctxs[0].config.ryba.kafka.broker.config['zookeeper.connect']
        @system.execute
          if: kafka.producer.env['KAFKA_KERBEROS_PARAMS']?
          cmd: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create \
              --zookeeper #{zoo_connect} --partitions #{ks_ctxs.length} --replication-factor #{ks_ctxs.length} \
              --topic #{test_topic}
            """
          unless_exec: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --list \
            --zookeeper #{zoo_connect} | grep #{test_topic}
            """
        @system.execute
          unless: kafka.producer.env['KAFKA_KERBEROS_PARAMS']?
          cmd: """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create \
              --zookeeper #{zoo_connect} --partitions #{ks_ctxs.length} --replication-factor #{ks_ctxs.length} \
              --topic #{test_topic}
            """
          unless_exec: """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --list \
            --zookeeper #{zoo_connect} | grep #{test_topic}
            """
        @system.execute
          if:  kafka.producer.env['KAFKA_KERBEROS_PARAMS']?
          cmd: mkcmd.kafka @, """
            (
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=#{zoo_connect} \
              --add --allow-principal User:ANONYMOUS  \
              --operation Read --operation Write --topic #{test_topic}
            )&
            (
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=#{zoo_connect} \
              --add \
              --allow-principal User:ANONYMOUS --consumer --group #{kafka.consumer.config['group.id']} --topic #{test_topic}
            )
            """
          unless_exec: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh  --list \
              --authorizer-properties zookeeper.connect=#{zoo_connect}  \
              --topic #{test_topic} | grep 'User:ANONYMOUS has Allow permission for operations: Write from hosts: *'
            """
        @system.execute
          unless:  kafka.producer.env['KAFKA_KERBEROS_PARAMS']?
          cmd: """
            (
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=#{zoo_connect} \
              --add --allow-principal User:ANONYMOUS  \
              --operation Read --operation Write --topic #{test_topic}
            )&
            (
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=#{zoo_connect} \
              --add \
              --allow-principal User:ANONYMOUS --consumer --group #{kafka.consumer.config['group.id']} --topic #{test_topic}
            )
            """
          unless_exec: """
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh  --list \
              --authorizer-properties zookeeper.connect=#{zoo_connect}  \
              --topic #{test_topic} | grep 'User:ANONYMOUS has Allow permission for operations: Write from hosts: *'
            """
        @system.execute
          cmd: """
          (
            echo 'hello front1' | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh \
              --producer-property security.protocol=PLAINTEXT \
              --broker-list #{brokers} \
              --security-protocol PLAINTEXT \
              --producer.config #{kafka.producer.conf_dir}/producer.properties \
              --topic #{test_topic}
          )&
          /usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh \
            --new-consumer \
            --delete-consumer-offsets \
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
        retry: 3
      , ->
        ks_ctxs = @contexts 'ryba/kafka/broker'
        return if ks_ctxs[0].config.ryba.kafka.broker.protocols.indexOf('SSL') == -1
        brokers = ks_ctxs.map( (ctx) => #, require('../broker').configure
          "#{ctx.config.host}:#{ctx.config.ryba.kafka.broker.ports['SSL']}"
        ).join ','
        test_topic = "check-#{@config.host}-producer-ssl-topic"
        zoo_connect = ks_ctxs[0].config.ryba.kafka.broker.config['zookeeper.connect']
        @system.execute
          cmd: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create \
              --zookeeper #{zoo_connect} --partitions #{ks_ctxs.length} --replication-factor #{ks_ctxs.length} \
              --topic #{test_topic}
            """
          unless_exec: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --list \
            --zookeeper #{zoo_connect} | grep #{test_topic}
            """
        @system.execute
          cmd: mkcmd.kafka @, """
            (
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=#{zoo_connect} \
              --add --allow-principal User:ANONYMOUS  \
              --operation Read --operation Write --topic #{test_topic}
            )&
            (
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=#{zoo_connect} \
              --add \
              --allow-principal User:ANONYMOUS --consumer --group #{kafka.consumer.config['group.id']} --topic #{test_topic}
            )
            """
          unless_exec: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh  --list \
              --authorizer-properties zookeeper.connect=#{zoo_connect}  \
              --topic #{test_topic} | grep 'User:ANONYMOUS has Allow permission for operations: Write from hosts: *'
            """
        @system.execute
          cmd:  """
            echo 'hello front1' | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh \
              --producer-property security.protocol=SSL \
              --broker-list #{brokers} \
              --security-protocol SSL \
              --producer-property ssl.truststore.location=#{kafka.producer.config['ssl.truststore.location']} \
              --producer-property ssl.truststore.password=#{kafka.producer.config['ssl.truststore.password']} \
              --producer.config #{kafka.producer.conf_dir}/producer.properties \
              --topic #{test_topic}
          """
        @system.execute
          cmd: """
            /usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh \
              --new-consumer \
              --delete-consumer-offsets \
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
        if: -> @has_service 'ryba/kafka/consumer'
        retry: 3
      , ->
        ks_ctxs = @contexts 'ryba/kafka/broker'
        return if ks_ctxs[0].config.ryba.kafka.broker.protocols.indexOf('SASL_PLAINTEXT') == -1
        brokers = ks_ctxs.map( (ctx) => #, require('../broker').configure
          "#{ctx.config.host}:#{ctx.config.ryba.kafka.broker.ports['SASL_PLAINTEXT']}"
        ).join ','
        test_topic = "check-#{@config.host}-producer-sasl-plaintext-topic"
        zoo_connect = ks_ctxs[0].config.ryba.kafka.broker.config['zookeeper.connect']
        @system.execute
          cmd: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create \
              --zookeeper #{zoo_connect} --partitions #{ks_ctxs.length} --replication-factor #{ks_ctxs.length} \
              --topic #{test_topic}
            """
          unless_exec: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --list \
            --zookeeper #{zoo_connect} | grep #{test_topic}
            """
        @call  header: "Topic ACL", ->
          @system.execute
            cmd: mkcmd.kafka @, """
              /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=#{zoo_connect} \
                --add --allow-principal User:#{user.name}  \
                --operation Read --operation Write --topic #{test_topic}
            """
            unless_exec: mkcmd.kafka @, """
              /usr/hdp/current/kafka-broker/bin/kafka-acls.sh  --list \
                --authorizer-properties zookeeper.connect=#{zoo_connect}  \
                --topic #{test_topic} | grep 'User:#{user.name} has Allow permission for operations: Write from hosts: *'
              """
          @system.execute
            cmd: mkcmd.kafka @, """
              /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=#{zoo_connect} \
                --add \
                --allow-principal User:#{user.name} --consumer --group #{kafka.consumer.config['group.id']} --topic #{test_topic}
              """
            unless_exec: mkcmd.kafka @, """
              /usr/hdp/current/kafka-broker/bin/kafka-acls.sh  --list \
                --authorizer-properties zookeeper.connect=#{zoo_connect}  \
                --topic #{test_topic} | grep 'User:#{user.name} has Allow permission for operations: Read from hosts: *'
              """
        @system.execute
          cmd:  mkcmd.test @, """
            (
              echo 'hello front1' | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh \
                --producer-property security.protocol=SASL_PLAINTEXT \
                --broker-list #{brokers} \
                --security-protocol SASL_PLAINTEXT \
                --producer.config #{kafka.producer.conf_dir}/producer.properties \
                --topic #{test_topic}
            )&
            /usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh \
              --new-consumer \
              --delete-consumer-offsets \
              --bootstrap-server #{brokers} \
              --topic #{test_topic} \
              --security-protocol SASL_PLAINTEXT \
              --consumer.config #{kafka.consumer.conf_dir}/consumer.properties \
              --zookeeper #{zoo_connect} --from-beginning --max-messages 1 | grep 'hello front1'
            """

## Check Messages SASL_SSL

Check Message by writing to a test topic on the SASL_SSL channel.
Specifying also the trustore location and password because if executed before consumer install
'/etc/kafka/conf/consumer.properties' might be empty

      @call
        header: 'Check SASL_SSL'
        label_true: 'CHECKED'
        retry: 3
        if: -> @has_service 'ryba/kafka/consumer'
      , ->
        ks_ctxs = @contexts 'ryba/kafka/broker'
        return if ks_ctxs[0].config.ryba.kafka.broker.protocols.indexOf('SASL_SSL') == -1
        brokers = ks_ctxs.map( (ctx) => #, require('../broker').configure
          "#{ctx.config.host}:#{ctx.config.ryba.kafka.broker.ports['SASL_SSL']}"
        ).join ','
        test_topic = "check-#{@config.host}-producer-sasl-ssl-topic"
        zoo_connect = ks_ctxs[0].config.ryba.kafka.broker.config['zookeeper.connect']
        @system.execute
          cmd: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create \
              --zookeeper #{zoo_connect} --partitions #{ks_ctxs.length} --replication-factor #{ks_ctxs.length} \
              --topic #{test_topic}
            """
          unless_exec: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --list \
            --zookeeper #{zoo_connect} | grep #{test_topic}
            """
        @system.execute
          cmd: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=#{zoo_connect} \
              --add --allow-principal User:#{user.name}  \
              --operation Read --operation Write --topic #{test_topic}
            """
          unless_exec: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh  --list \
              --authorizer-properties zookeeper.connect=#{zoo_connect}  \
              --topic #{test_topic} | grep 'User:#{user.name} has Allow permission for operations: Write from hosts: *'
            """
        @system.execute
          cmd: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=#{zoo_connect} \
              --add \
              --allow-principal User:#{user.name} --consumer --group #{kafka.consumer.config['group.id']} --topic #{test_topic}
            """
          unless_exec: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh  --list \
              --authorizer-properties zookeeper.connect=#{zoo_connect}  \
              --topic #{test_topic} | grep 'User:#{user.name} has Allow permission for operations: Read from hosts: *'
            """
        @system.execute
          cmd:  mkcmd.test @, """
            (
              echo 'hello front1' | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh \
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
              --delete-consumer-offsets \
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
