
# Nagios

[Nagios][hdp] is an open source network monitoring system designed to monitor 
all aspects of your Hadoop cluster (such as hosts, services, and so forth) over 
the network. It can monitor many facets of your installation, ranging from 
operating system attributes like CPU and memory usage to the status of 
applications, files, and more. Nagios provides a flexible, customizable 
framework for collecting data on the state of your Hadoop cluster.

    module.exports = ->
      'backup': 'ryba/nagios/backup'
      'check': 'ryba/nagios/check'
      'configure':
        'ryba/nagios/configure'
      'install': [
        'masson/commons/httpd'
        'masson/commons/java'
        'ryba/oozie/client/install'
        'ryba/nagios/install'
        'ryba/nagios/check' # Must be executed before start
        'ryba/nagios/start'
      ]
      'start': 'ryba/nagios/start'
      'status': 'ryba/nagios/status'
      'stop': 'ryba/nagios/stop'

[hdp]: http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.1/bk_Monitoring_Hadoop_Book/content/monitor-chap3-1.html
