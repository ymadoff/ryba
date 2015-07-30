
# Kafka Commons

Commons configuration and deployment actions shared between broker, producer
and consumer Kafka components.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require '../lib/hdp_select'

## Configure

    module.exports.push module.exports.configure = (ctx) ->
      require('../hadoop/core').configure ctx
      kafka = ctx.config.ryba.kafka ?= {}
      # Layout
      kafka.conf_dir ?= '/etc/kafka/conf'
      # User
      kafka.user ?= {}
      kafka.user = name: kafka.user if typeof kafka.user is 'string'
      kafka.user.name ?= 'kafka'
      kafka.user.system ?= true
      kafka.user.comment ?= 'Kafka User'
      kafka.user.home = '/var/lib/kafka'
      # Group
      kafka.group = name: kafka.group if typeof kafka.group is 'string'
      kafka.group ?= {}
      kafka.group.name ?= 'kafka'
      kafka.group.system ?= true
      kafka.user.gid = kafka.group.name
      # Configuration
      kafka.consumer ?= {}
      kafka.consumer['zookeeper.connect'] ?= ctx.config.ryba.core_site['ha.zookeeper.quorum']
      kafka.consumer['group.id'] ?= 'ryba-consumer-group'

## Users & Groups

By default, the "kafka" package create the following entries:

```bash
cat /etc/passwd | grep kafka
kafka:x:496:496:KAFKA:/home/kafka:/bin/bash
cat /etc/group | grep kafka
kafka:x:496:kafka
```

    module.exports.push name: 'Kafka # Users & Groups', handler: (ctx, next) ->
      {kafka} = ctx.config.ryba
      ctx
      .group kafka.group
      .user kafka.user
      .then next

## Package

Install the Kafka broker package and set it to the latest version. Note, there
are no "kafka-producer" nor "kafka-consumer" directories.

    module.exports.push name: 'Kafka Broker # Package', handler: (ctx, next) ->
      ctx
      .service
        name: 'kafka'
      .hdp_select
        name: 'kafka-broker'
      .then next
