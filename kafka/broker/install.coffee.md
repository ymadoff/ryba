
# Kafka Broker Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/core/krb5_client'
    module.exports.push 'ryba/lib/hdp_select'
    module.exports.push 'ryba/lib/write_jaas'


## Users & Groups

By default, the "kafka" package create the following entries:

```bash
cat /etc/passwd | grep kafka
kafka:x:496:496:KAFKA:/home/kafka:/bin/bash
cat /etc/group | grep kafka
kafka:x:496:kafka
```

    module.exports.push header: 'Kafka # Users & Groups', handler: ->
      {kafka} = @config.ryba
      @group kafka.group
      @user kafka.user

## IPTables

| Service      | Port  | Proto       | Parameter          |
|--------------|-------|-------------|--------------------|
| Kafka Broker | 9092  | http        | port               |
| Kafka Broker | 9093  | https       | port               |
| Kafka Broker | 9094  | sasl_http   | port               |
| Kafka Broker | 9096  | sasl_https  | port               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push
      header: 'Kafka Broker # IPTables',
      handler: ->
        {kafka} = @config.ryba
        return unless @config.iptables.action is 'start'
        @iptables
          if: kafka.broker.protocols.indexOf('PLAINTEXT') != -1
          rules: [
            { chain: 'INPUT', jump: 'ACCEPT', dport: kafka.ports['PLAINTEXT'], protocol: 'tcp', state: 'NEW', comment: "Kafka Broker PLAINTEXT" }
          ]
        @iptables
          if: kafka.broker.protocols.indexOf('SASL_PLAINTEXT') != -1
          rules: [
            { chain: 'INPUT', jump: 'ACCEPT', dport: kafka.ports['SASL_PLAINTEXT'], protocol: 'tcp', state: 'NEW', comment: "Kafka Broker SASL_PLAINTEXT" }
          ]
        @iptables
          if: kafka.broker.protocols.indexOf('SSL') != -1
          rules: [
            { chain: 'INPUT', jump: 'ACCEPT', dport: kafka.ports['SSL'], protocol: 'tcp', state: 'NEW', comment: "Kafka Broker SSL" }
          ]
        @iptables
          if: kafka.broker.protocols.indexOf('SASL_SSL') != -1
          rules: [
            { chain: 'INPUT', jump: 'ACCEPT', dport: kafka.ports['SASL_SSL'], protocol: 'tcp', state: 'NEW', comment: "Kafka Broker SASL_SSL" }
          ]


## Package

Install the Kafka consumer package and set it to the latest version. Note, we
select the "kafka-broker" hdp directory. There is no "kafka-consumer"
directories.

    module.exports.push header: 'Kafka Broker # Package', handler: ->
      @service
        name: 'kafka'
      @hdp_select
        name: 'kafka-broker'
      @render
        destination: '/etc/init.d/kafka-broker'
        source: "#{__dirname}/../resources/kafka-broker.js2"
        local_source: true
        mode: 0o0755
        context: @config
        unlink: true

## Configure

Update the file "broker.properties" with the properties defined by the
"ryba.kafka.broker" configuration.

    module.exports.push header: 'Kafka Broker # Configure', handler: ->
      {kafka} = @config.ryba
      @write
        destination: "#{kafka.broker.conf_dir}/server.properties"
        write: for k, v of kafka.broker.config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true

## Metrics

Upload *.properties files in /etc/kafka-broker/conf directory.

    module.exports.push header: 'Kafka Broker # Metrics', handler: ->
      {kafka} = @config.ryba
      @call (_, callback) ->
        glob "#{__dirname}/../resources/*.properties", (err, files) =>
          for file in files
            continue if /^\./.test path.basename file
            @upload
              source: file
              destination: "#{kafka.broker.conf_dir}/#{path.basename file}"
              binary: true
          @then callback
      @upload
        source: "#{__dirname}/../resources/connect-console-sink.properties"
        destination: "#{kafka.broker.conf_dir}/connect-console-sink.properties"
        binary: true
      @upload
        source: "#{__dirname}/../resources/connect-console-sink.properties"
        destination: "#{kafka.broker.conf_dir}/connect-console-sink.properties"
        binary: true
      @upload
        source: "#{__dirname}/../resources/connect-console-sink.properties"
        destination: "#{kafka.broker.conf_dir}/connect-console-sink.properties"
        binary: true

## Env

Update the kafka-env.sh file (/etc/kafka-broker/conf/kafka-enh.sh)

    module.exports.push header: 'Kafka Broker # Env', handler: ->
      {kafka} = @config.ryba
      @write
        destination: "#{kafka.broker.conf_dir}/kafka-env.sh"
        write: for k, v of kafka.broker.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
          append: true
        backup: true
        eof: true
        mode:0o0750
        uid: kafka.user.name
        gid: kafka.group.name
      @write
        destination: "#{kafka.broker.conf_dir}/log4j.properties"
        write: for k, v of kafka.broker.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      @write
        destination: "/etc/kafka/conf/log4j.properties"
        write: for k, v of kafka.broker.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true


Modify bin scripts to set $KAFKA_HOME variable to match /etc/kafka-broker/conf.
Replace KAFKA_BROKER_CMD kafka-broker conf directory path
Replace KAFKA_BROKER_CMD kafka-broker conf directory path

    module.exports.push header: 'Kafka Broker # Startup Script', handler: ->
      {kafka} = @config.ryba
      @write
        destination: "/usr/hdp/current/kafka-broker/bin/kafka"
        write: [
          match: /^KAFKA_BROKER_CMD=(.*)/m
          replace: "KAFKA_BROKER_CMD=\"$KAFKA_HOME/bin/kafka-server-start.sh #{kafka.broker.conf_dir}/server.properties\""
        ]
        backup: true
        eof: true
      @write
        destination: "/usr/hdp/current/kafka-broker/bin/kafka-server-start.sh"
        write: [
          match: RegExp "^exec.*\\$@$", 'm'
          replace: ". /etc/kafka-broker/conf/kafka-env.sh # RYBA, don't overwrite\nexec /usr/hdp/current/kafka-broker/bin/kafka-run-class.sh $EXTRA_ARGS kafka.Kafka $@ # RYBA, don't overwrite"
        ]
        backup: true
        eof: true

## Kerberos

    module.exports.push 'masson/core/krb5_client/wait'

    module.exports.push header: 'Kafka Broker # Kerberos', timeout: -1, handler: ->
      {kafka, hadoop_group, realm} = @config.ryba
      return unless kafka.broker.config['zookeeper.set.acl'] is 'true'
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: kafka.broker.kerberos['principal']
        randkey: true
        keytab: kafka.broker.kerberos['keyTab']
        uid: kafka.user.name
        gid: kafka.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      @write_jaas
        destination: "#{kafka.broker.conf_dir}/kafka-server.jaas"
        content:
          KafkaServer:
            principal: kafka.broker.kerberos['principal']
            keyTab: kafka.broker.kerberos['keyTab']
            useKeyTab: true
            storeKey: true
          Client:
            principal: kafka.broker.kerberos['principal']
            keyTab: kafka.broker.kerberos['keyTab']
            useKeyTab: true
            storeKey: true
        uid: kafka.user.name
        gid: kafka.group.name

    module.exports.push header: 'Kafka Broker # Admin ', handler: ->
      {kafka, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: kafka.admin.principal
        password: kafka.admin.password
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

# SSL Server

Upload and register the SSL certificate and private key.
SSL is enabled at least for inter broker communication

    module.exports.push header: 'Kafka Broker # SSL', handler: ->
      {kafka, ssl} = @config.ryba
      @java_keystore_add
        keystore: kafka.broker.config['ssl.keystore.location']
        storepass: kafka.broker.config['ssl.keystore.password']
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        key: "#{ssl.key}"
        cert: "#{ssl.cert}"
        keypass: kafka.broker.config['ssl.key.password']
        name: @config.shortname
        local_source: true
      @java_keystore_add
        keystore: kafka.broker.config['ssl.keystore.location']
        storepass: kafka.broker.config['ssl.keystore.password']
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        local_source: true
      # imports kafka broker server hadoop_root_ca CA trustore
      @java_keystore_add
        keystore: kafka.broker.config['ssl.truststore.location']
        storepass: kafka.broker.config['ssl.truststore.password']
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        local_source: true


## Layout

Directories in which Kafka data is stored. Each new partition that is created
will be placed in the directory which currently has the fewest partitions.

    module.exports.push header: 'Kafka Broker # Layout', handler: ->
      {kafka} = @config.ryba
      @mkdir (
        destination: dir
        uid: kafka.user.name
        gid: kafka.group.name
        mode: 0o0750
        parent: true
      ) for dir in kafka.broker.config['log.dirs'].split ','


## Dependencies

    glob = require 'glob'
    path = require 'path'
    quote = require 'regexp-quote'
