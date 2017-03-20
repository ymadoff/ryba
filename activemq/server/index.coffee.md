# ActiveMQ

Apache ActiveMQ ™ is the most popular and powerful open source messaging and Integration Patterns server.
Apache ActiveMQ
  is fast,
  supports many Cross Language Clients and Protocols,
  comes with easy to use Enterprise Integration Patterns
  and many advanced features while fully supporting JMS 1.1 and J2EE 1.4.
Apache ActiveMQ is released under the Apache 2.0 License.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        docker: implicit: true, module: 'masson/commons/docker'
      configure:
        'ryba/activemq/server/configure'
      commands:
        'check':
          'ryba/activemq/server/check'
        'install': [
          'ryba/activemq/server/install'
          # 'ryba/activemq/server/start'
          # 'ryba/activemq/server/check'
        ]
        'prepare':
          'ryba/activemq/server/prepare'
        "start":
          'ryba/activemq/server/start'
        "stop":
          'ryba/activemq/server/stop'
