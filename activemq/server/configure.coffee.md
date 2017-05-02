    # builder = require 'xmlbuilder'

# ActiveMQ Configure

    module.exports = ->
      activemq = @config.ryba.activemq ?= {}

## Environment

      activemq.version ?= '5.14.3'
      activemq.server ?= {}
      activemq.conf_dir ?= '/etc/activemq/conf'
      activemq.log_dir ?= '/var/log/activemq'
      activemq.data_dir ?= '/var/activemq/data'

## Identities

      # Group
      activemq.group ?= {}
      activemq.group = name: activemq.group if typeof activemq.group is 'string'
      activemq.group.name ?= 'activemq'
      activemq.group.system ?= true
      # User
      activemq.user ?= {}
      activemq.user = name: activemq.user if typeof activemq.user is 'string'
      activemq.user.name ?= 'activemq'
      activemq.user.home ?= "/var/#{activemq.user.name}"
      activemq.user.system ?= true
      activemq.user.comment ?= 'ActiveMQ User'
      activemq.user.groups ?= 'hadoop'
      activemq.user.gid ?= activemq.group.name

## Ports

      activemq.server.port ?= {}
      activemq.server.port.jms ?= '61616'
      activemq.server.port.ui ?= '8161'
      activemq.server.container_name ?= 'activemq_server'
      activemq.server.ports ?= {
        openwire: { protocol: 'tcp',   port: 61616 },
        amqp:     { protocol: 'amqp',  port: 5672  },
        stomp:    { protocol: 'stomp', port: 61613 },
        mqtt:     { protocol: 'mqtt',  port: 1883  },
        ws:       { protocol: 'ws',    port: 61614 }
      }

## Configuration

      activemq.conf ?= {}
      activemq.conf['beans'] = {
        '@xmlns': "http://www.springframework.org/schema/beans"
        '@xmlns:xsi': "http://www.w3.org/2001/XMLSchema-instance"
        '@xsi:schemaLocation': "http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
        http://activemq.apache.org/schema/core http://activemq.apache.org/schema/core/activemq-core.xsd",
        bean: [
          {
           '@class': "org.springframework.beans.factory.config.PropertyPlaceholderConfigurer",
           'property': {'@name': 'locations', value: 'file:${activemq.conf}/credentials.properties'}
          },
          {
            '@id': 'logQuery'
            '@class': "io.fabric8.insight.log.log4j.Log4jLogQuery",
            '@lazy-init': "false",
            '@scope': "singleton",
            '@init-method': "start",
            '@destroy-method': "stop"
          }
        ],
        broker: {
          '@xmlns': "http://activemq.apache.org/schema/core",
          '@brokerName': "#{@config.host}",
          '@dataDirectory': "${activemq.data}",
          '@networkConnectorStartAsync': true,
          destinationPolicy: {
            policyMap: {
              policyEntries: [
                policyEntry : { '@topic': '>',  pendingMessageLimitStrategy: {constantPendingMessageLimitStrategy: {'@limit':1000}} }
              ]
            }
          },
          managementContext : { managementContext : {'@createConnector': "false"} },
          persistenceAdapter : { kahaDB : {'@directory': "${activemq.data}/kahadb"} },
          systemUsage: {
            systemUsage: {
              memoryUsage : { memoryUsage : {'@percentOfJvmHeap': 70} },
              storeUsage  : { storeUsage  : {'@limit': "10 gb"} },
              tempUsage   : { tempUsage   : {'@limit': "1 gb"} }
            }
          },
          shutdownHooks: {
            bean: [
              { '@xmlns': 'http://www.springframework.org/schema/beans',  '@class': 'org.apache.activemq.hooks.SpringContextHook' }
            ]
          },
          transportConnectors: { transportConnector: [] },
          networkConnectors: { networkConnector: [] }
        },
        import: {'@resource': "jetty.xml"}
      }
      # Ports enabled
      for k,v of activemq.server.ports
        activemq.conf['beans'].broker.transportConnectors.transportConnector.push {
          '@name': "#{k}", '@uri': "#{v['protocol']}"+'://0.0.0.0:'+"#{v['port']}"+'?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600'
        }
      # Network of Brokers
      localhost = @config.host
      for host in @contexts('ryba/activemq/server').filter((c)->c.config.host != localhost).map((c)->c.config.host)
        activemq.conf['beans'].broker.networkConnectors.networkConnector.push {
          '@name': "#{host}",
          '@uri': "static:(tcp://#{host}:61616)",
          '@duplex': 'true',
          '@decreaseNetworkConsumerPriority': false,
          '@networkTTL': 2,
          '@dynamicOnly': true
        }
      # Connection string
      hosts = @contexts('ryba/activemq/server').map((c)->"tcp://#{c.config.host}:#{activemq.server.ports['openwire'].port}")
      if hosts.length > 1
        jms_url = "failover:(" + hosts.join(',') + ")?randomize=false&maxReconnectAttempts=10&initialReconnectDelay=100&priorityBackup=true"
      else
        jms_url = "#{hosts[0]}"
      # Integrate Oozie with ActiveMQ
      @config.ryba.oozie ?= {}
      @config.ryba.oozie.jms_url ?= jms_url
      # Integrate HCatalog with ActiveMQ
      @config.ryba.hive ?= {}
      @config.ryba.hive.hcatalog ?= {}
      @config.ryba.hive.hcatalog.jms_url ?= jms_url
