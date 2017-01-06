# The Hortonworks SmartSense Tool (HST)

[The Hortonworks SmartSense Tool][hst] Collects cluster diagnostic information
to help you troubleshoot support cases.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        hadoop_core: implicit: true, module: 'ryba/hadoop/core'
        smartsense_server: 'ryba/smartsense/server'
      configure: 'ryba/smartsense/agent/configure'
      commands: 
        'install': [
          'ryba/smartsense/agent/install'
          'ryba/smartsense/agent/check'
        ]
        'check': 'ryba/smartsense/agent/check'

[hst]: (http://docs.hortonworks.com/HDPDocuments/SS1/SmartSense-1.3.0/bk_installation/content/architecture_overview.html)
