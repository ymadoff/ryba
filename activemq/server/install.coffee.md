
# ActiveMQ Server Install

    module.exports = header: 'ActiveMQ Server Install', handler: ->
      {iptables} = @config
      {activemq} = @config.ryba
      tmp = "/tmp_#{Date.now()}"
      md5 = true

## IPTables

| Service      | Port  | Proto | Parameter |
|--------------|-------|-------|-----------|
| ActiveMQ JMS | 61616 | tcp   | -         |
| ActiveMQ UI  |  8161 | tcp   | -         |


IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: activemq.server.port.jms, protocol: 'tcp', state: 'NEW', comment: "ActiveMQ JMS" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: activemq.server.port.ui, protocol: 'tcp', state: 'NEW', comment: "ActiveMQ UI" }
        ]
        if: iptables.action is 'start'

## Identities

Create user and groups for solr user.

      @system.mkdir
        target: activemq.user.home
        uid: activemq.user.name
        gid: activemq.group.name
      @system.group header: 'Group', activemq.group
      @system.user header: 'User', activemq.user

## Startup Script

Write startup script to /etc/init.d/activemq

      @service.init
        header: 'Startup Script'
        source: "#{__dirname}/resources/activemq.j2"
        local: true
        target: "/etc/init.d/activemq"
        context: container: activemq.server.container_name
      @file
        header: 'Configuration'
        content: builder.create(activemq.conf, headless: true).end(pretty: true)
        target: "#{activemq.conf_dir}/activemq.xml"
        eof: true
      @file
        header: 'Log4J properties'
        target: "#{activemq.conf_dir}/log4j.properties"
        source: "#{__dirname}/resources/log4j.properties"
        local: true

## Layout directories

      @call header: 'Layout', timeout: -1, ->
        @system.mkdir
          target: activemq.log_dir
          uid: activemq.user.name
          gid: activemq.group.name
          mode: 0o777
        @system.mkdir
          target: activemq.data_dir
          uid: activemq.user.name
          gid: activemq.group.name
          mode: 0o777

## Package
Install the ActiveMQ server.

      @call header: 'Download Container', ->
        exists = false
        @docker.checksum
          image: 'activemq'
          tag: activemq.version
        , (err, status, checksum) ->
          throw err if err
          exists = checksum
        @file.download
          unless: -> exists
          binary: true
          md5: true
          source: "#{@config.nikita.cache_dir}/activemq.tar"
          target: "#{tmp}/activemq.tar"
        @docker.load
          header: 'Load Container'
          unless: -> exists
          source: "#{tmp}/activemq.tar"
          docker: @config.docker

## Run Container
Run the ActiveMQ server container

      @docker.service
        machine: @config.nikita.machine
        header: 'Run ActiveMQ Container'
        label_true: 'RUNNED'
        docker: @config.docker
        force: -> @status(-1)
        image: "rmohr/activemq:#{activemq.version}"
        env: [
        ]
        volume: [
          "#{activemq.conf_dir}/activemq.xml:/opt/apache-activemq-#{activemq.version}/conf/activemq.xml:ro"
          "#{activemq.conf_dir}/log4j.properties:/opt/apache-activemq-#{activemq.version}/conf/log4j.properties:ro"
          "#{activemq.log_dir}:/opt/apache-activemq-#{activemq.version}/log"
          "#{activemq.data_dir}:/opt/apache-activemq-#{activemq.version}/data"
        ]
        port: [
          "#{activemq.server.port.jms}:61616"
          "#{activemq.server.port.ui}:8161"
        ]
        net: 'host'
        # rm: true
        service: true
        name: activemq.server.container_name

## Dependencies

    builder = require 'xmlbuilder'
