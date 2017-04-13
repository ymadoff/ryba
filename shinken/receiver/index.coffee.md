
# Shinken Receiver (optional)

Receives data passively from local or remote protocols. Passive data reception
that is buffered before forwarding to the appropriate Scheduler (or receiver for global commands).
Allows to set up a "farm" of Receivers to handle a high rate of incoming events.
Modules for receivers:

* NSCA - NSCA protocol receiver
* Collectd - Receive performance data from collectd via the network
* CommandPipe - Receive commands, status updates and performance data
* TSCA - Apache Thrift interface to send check results using a high rate buffered TCP connection directly from programs
* Web Service - A web service that accepts http posts of check results (beta)

This module is only needed when enabling passive checks

    module.exports =
      use:
        yum: implicit: true, module: 'masson/core/yum'
        iptables: implicit: true, module: 'masson/core/iptables'
      configure: [
        'ryba/shinken/commons/configure'
        'ryba/shinken/receiver/configure'
      ]
      commands:
        'check':
          'ryba/shinken/receiver/check'
        'install': [
          'ryba/shinken/commons/install'
          'ryba/shinken/receiver/install'
          'ryba/shinken/receiver/start'
          'ryba/shinken/receiver/check'
        ]
        'start':
          'ryba/shinken/receiver/start'
        'status':
          'ryba/shinken/receiver/status'
        'stop':
          'ryba/shinken/receiver/stop'
