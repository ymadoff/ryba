# The Hortonworks SmartSense Tool (HST)

[The Hortonworks SmartSense Tool][hst] Collects cluster diagnostic information 
to help you troubleshoot support cases.

    module.exports = ->
      'configure': [
        'ryba/hadoop/core/configure'
        'ryba/smartsense/server/configure'
      ]
      'install': [
        'ryba/hadoop/core'
        'ryba/smartsense/server/install'
        'ryba/smartsense/server/start'
        'ryba/smartsense/server/wait'
        'ryba/smartsense/server/check'
      ]
      'start': [
        'ryba/smartsense/server/start'
      ]
      'stop': [
        'ryba/smartsense/server/stop'
      ]
      'status': [
        'ryba/smartsense/server/status'
      ]
          
[hst]: (http://docs.hortonworks.com/HDPDocuments/SS1/SmartSense-1.3.0/bk_installation/content/architecture_overview.html)
