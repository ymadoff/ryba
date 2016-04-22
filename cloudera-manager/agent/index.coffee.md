# Cloudera Manager Agent

[Cloudera Manager Agents][Cloudera-agent-install] on hosts enables the cloudera
manager server to be aware of the hosts where it will deploy the Hadoop stack.
The cloudera manager server must be installed before performing manual registration.
You must have configured yum to use the [cloudera manager repo][Cloudera-manager-repo]
or the [cloudera cdh repo][Cloudera-cdh-repo].


    module.exports = ->
      'configure' : [
        'ryba/cloudera-manager/agent/configure'
      ]
      'install' : [
        'ryba/cloudera-manager/agent/install'
        'ryba/cloudera-manager/agent/start'
      ]
      'stop' : [
        'ryba/cloudera-manager/agent/stop'
      ]
      'start' : [
        'ryba/cloudera-manager/agent/start'
      ]

[Cloudera-agent-install]: http://www.cloudera.com/content/www/en-us/documentation/enterprise/5-2-x/topics/cm_ig_install_path_b.html#cmig_topic_6_6_3_unique_1
[Cloudera-manager-repo]: http://archive.cloudera.com/cm5/redhat/6/x86_64/cm/cloudera-manager.repo
[Cloudera-cdh-repo]: http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/cloudera-cdh5.repo
