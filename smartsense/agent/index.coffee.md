# The Hortonworks SmartSense Tool (HST)

[The Hortonworks SmartSense Tool][hst] Collects cluster diagnostic information
to help you troubleshoot support cases.

    module.exports = ->
      'configure': [
        'ryba/hadoop/core/configure'
        'ryba/smartsense/agent/configure'
      ]
      'install': [
        'ryba/hadoop/core'
        'ryba/smartsense/agent/install'
        'ryba/smartsense/agent/check'
      ]
      'check': 'ryba/smartsense/agent/check'

[hst]: (http://docs.hortonworks.com/HDPDocuments/SS1/SmartSense-1.3.0/bk_installation/content/architecture_overview.html)
