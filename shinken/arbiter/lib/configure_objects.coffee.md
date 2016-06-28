
# Configure

## Default Configuration

Default "shinken object" (servicegroups, hosts, etc) configuration.

    init = ->
      {shinken} = @config.ryba
      hostgroups = shinken.config.hostgroups ?= {}
      hosts = shinken.config.hosts ?= {}
      servicegroups = shinken.config.servicegroups ?= {}
      services = shinken.config.services ?= {}
      commands = shinken.config.commands ?= {}
      realms = shinken.config.realms ?= {}
      realms.All ?= {}
      clusters = shinken.config.clusters ?= {}
      contactgroups = shinken.config.contactgroups ?= {}
      contacts = shinken.config.contacts ?= {}
      dependencies = shinken.config.dependencies ?= {}
      escalations = shinken.config.escalations ?= {}
      hostescalations = shinken.config.hostescalations ?= {}
      serviceescalations = shinken.config.serviceescalations ?= {}
      timeperiods = shinken.config.timeperiods ?= {}
      # Hostgroups
      hostgroups['by_roles'] ?= {}
      hostgroups['by_roles'].alias ?= 'Role View'
      hostgroups['by_roles'].hostgroup_members ?= []
      hostgroups['by_topology'] ?= {}
      hostgroups['by_topology'].alias ?= 'Topological View'
      hostgroups['by_topology'].hostgroup_members ?= []
      hostgroups['watcher'] ?= {}
      hostgroups['watcher'].alias ?= 'Cluster Watchers'
      hostgroups['watcher'].hostgroup_members ?= []

### Templates

Templates are generic (abstract) objects that can define commons properties by heritage.
They must have register set to 0 to not be instanciated

      # Hosts
      hosts['generic-host'] ?= {}
      hosts['generic-host'].use ?= ''
      hosts['generic-host'].check_command ?= 'check_host'
      hosts['generic-host'].max_check_attempts ?= '2'
      hosts['generic-host'].check_interval ?= '300'
      hosts['generic-host'].retry_interval ?= '60'
      hosts['generic-host'].active_checks_enabled ?= '1'
      hosts['generic-host'].check_period ?= '24x7'
      hosts['generic-host'].event_handler_enabled ?= '0'
      hosts['generic-host'].flap_detection_enabled ?= '1'
      hosts['generic-host'].process_perf_data ?= '1'
      hosts['generic-host'].retain_status_information ?= '1'
      hosts['generic-host'].retain_nonstatus_information ?= '1'
      hosts['generic-host'].contactgroups ?= ['admins']
      hosts['generic-host'].notification_interval ?= '3600'
      hosts['generic-host'].notification_period ?= '24x7'
      hosts['generic-host'].notification_options ?= 'd,u,r,f'
      hosts['generic-host'].notification_enabled ?= '1'
      hosts['generic-host'].register = '0' # IT'S A TEMPLATE !
      hosts['linux-server'] ?= {}
      hosts['linux-server'].use ?= 'generic-host'
      hosts['linux-server'].check_interval ?= '60'
      hosts['linux-server'].retry_interval ?= '20'
      hosts['linux-server'].register = '0'
      hosts['aggregates'] ?= {}
      hosts['aggregates'].use ?= 'generic-host'
      hosts['aggregates'].check_command ?= 'ok'
      hosts['aggregates'].register = '0'
      # Services
      services['generic-service'] ?= {}
      services['generic-service'].use ?= ''
      services['generic-service'].active_checks_enabled ?= '1'
      services['generic-service'].passive_checks_enabled ?= '1'
      services['generic-service'].parallelize_check ?= '1'
      services['generic-service'].obsess_over_service ?= '1'
      services['generic-service'].check_freshness ?= '1'
      services['generic-service'].first_notification_delay ?= '0'
      services['generic-service'].freshness_threshold ?= '3600'
      services['generic-service'].notifications_enabled ?= '1'
      services['generic-service'].flap_detection_enabled ?= '0'
      services['generic-service'].failure_prediction_enabled ?= '1'
      services['generic-service'].process_perf_data ?= '1'
      services['generic-service'].retain_status_information ?= '1'
      services['generic-service'].retain_nonstatus_information ?= '1'
      services['generic-service'].is_volatile ?= '0'
      services['generic-service'].check_period ?= '24x7'
      services['generic-service'].max_check_attempts ?= '2'
      services['generic-service'].check_interval ?= '300'
      services['generic-service'].retry_interval ?= '60'
      services['generic-service'].contactgroups ?= 'admins'
      services['generic-service'].notifications_options ?= 'w,u,c,r'
      services['generic-service'].notification_interval ?= '3600'
      services['generic-service'].notification_period ?= '24x7'
      services['generic-service'].register = '0'
      services['unit-service'] ?= {}
      services['unit-service'].use ?= 'generic-service'
      services['unit-service'].register = '0'
      services['unit-service'].check_interval = '30'
      services['unit-service'].retry_interval = '10'
      services['bp-service'] ?= {}
      services['bp-service'].use ?= 'unit-service'
      services['bp-service'].business_rule_output_template ?= '$($HOSTNAME$: $SERVICEDESC$ )$'
      services['bp-service'].register ?= '0'
      services['process-service'] ?= {}
      services['process-service'].use ?= 'unit-service'
      services['process-service'].register = '0'
      services['functional-service'] ?= {}
      services['functional-service'].use ?= 'generic-service'
      services['functional-service'].check_interval = '600'
      services['functional-service'].retry_interval = '30'
      services['functional-service'].register = '0'
      # ContactGroups
      contactgroups['admins'] ?= {}
      contactgroups['admins'].alias ?= 'Shinken Administrators'
      # Contacts
      contacts['generic-contact'] ?= {}
      contacts['generic-contact'].use ?= ''
      contacts['generic-contact'].service_notification_period ?= '24x7'
      contacts['generic-contact'].host_notification_period ?= '24x7'
      contacts['generic-contact'].service_notification_options ?= 'w,u,c,r,f'
      contacts['generic-contact'].host_notification_options ?= 'd,u,r,f,s'
      contacts['generic-contact'].service_notification_commands ?= 'notify-service-by-email'
      contacts['generic-contact'].host_notification_commands ?= 'notify-host-by-email'
      contacts['generic-contact'].host_notifications_enabled ?= '1'
      contacts['generic-contact'].service_notifications_enabled ?= '1'
      contacts['generic-contact'].register = '0'
      contacts['admin-contact'] ?= {}
      contacts['admin-contact'].use ?= 'generic-contact'
      contacts['admin-contact'].can_submit_commands ?= '1'
      contacts['admin-contact'].is_admin ?= '1'
      contacts['admin-contact'].contactgroups ?= ['admins']
      contacts['admin-contact'].register = '0'
      contacts['shinken'] ?= {}
      contacts['shinken'].contactgroups ?= []
      contacts['shinken'].contactgroups.push 'admins' unless 'admins' in contacts['shinken'].contactgroups
      # Timeperiods
      timeperiods['24x7'] ?= {}
      timeperiods['24x7'].alias ?= 'Everytime'
      timeperiods['24x7'].time ?= {}
      for day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
        timeperiods['24x7'].time[day] ?= '00:00-24:00'
      timeperiods.none ?= {}
      timeperiods.none.alias ?= 'Never'
      timeperiods.none.time = {}
      # Commands
      commands['notify-host-by-email'] ?= '/usr/bin/printf "%b" "Shinken Notification\\n\\nType: $NOTIFICATIONTYPE$\\nHost: $HOSTNAME$\\nState: $HOSTSTATE$\\nAddress: $HOSTADDRESS$\\nDate: $SHORTDATETIME$\\nInfo: $HOSTOUTPUT$" | mailx -s "Host $NOTIFICATIONTYPE$: $HOSTNAME$ is $HOSTSTATE$" $CONTACTEMAIL$'
      commands['notify-service-by-email'] ?= '/usr/bin/printf "%b" "Shinken Notification\\n\\nNotification Type: $NOTIFICATIONTYPE$\\n\\nService: $SERVICEDESC$\\nHost:$HOSTALIAS$\\nAddress: $HOSTADDRESS$\\nState: $SERVICESTATE$\\nDate: $SHORTDATETIME$\\nInfo : $SERVICEOUTPUT$" | mailx -s "Service $NOTIFICATIONTYPE$: $SERVICEDESC$ ($HOSTALIAS$) is $SERVICESTATE$"  $CONTACTEMAIL$'

## Object from Ryba

This function creates hostgroups and servicegroups from ryba (sub)modules

    from_ryba = ->
      {servicegroups, hostgroups} = @config.ryba.shinken.config
      initgroup = (name, parent, alias) ->
        alias ?= "#{name.charAt(0).toUpperCase()}#{name.slice 1}"
        servicegroups[name] ?= {}
        servicegroups[name].alias ?= "#{alias} Services"
        servicegroups[name].members ?= []
        servicegroups[name].servicegroup_members ?= []
        servicegroups[name].servicegroup_members = [servicegroups[name].servicegroup_members] unless Array.isArray servicegroups[name].servicegroup_members
        servicegroups[parent].servicegroup_members.push name if parent? and name not in servicegroups[parent].servicegroup_members
        hostgroups[name] ?= {}
        hostgroups[name].alias ?= "#{alias} Hosts"
        hostgroups[name].members ?= []
        hostgroups[name].hostgroup_members ?= []
        parent ?= 'by_roles'
        hostgroups[parent].hostgroup_members.push name unless name in hostgroups[parent].hostgroup_members
      initgroup 'mysql'
      initgroup 'mysql_server', 'mysql', 'MySQL Server'
      initgroup 'zookeeper'
      initgroup 'zookeeper_server', 'zookeeper', 'Zookeeper Server'
      initgroup 'zookeeper_client', 'zookeeper', 'Zookeeper Client'
      initgroup 'hadoop'
      initgroup 'hdfs', 'hadoop', 'HDFS'
      initgroup 'hdfs_nn', 'hdfs', 'HDFS NameNode'
      initgroup 'hdfs_jn', 'hdfs', 'HDFS JournalNode'
      initgroup 'zkfc', 'hdfs', 'HDFS ZKFC'
      initgroup 'hdfs_dn', 'hdfs', 'HDFS DataNode'
      initgroup 'httpfs', 'hdfs', 'HttpFS'
      initgroup 'hdfs_client', 'hdfs', 'HDFS Client'
      initgroup 'yarn', 'hadoop', 'YARN'
      initgroup 'yarn_rm', 'yarn', 'YARN ResourceManager'
      initgroup 'yarn_nm', 'yarn', 'YARN NodeManager'
      initgroup 'yarn_ts', 'yarn', 'YARN Timeline Server'
      initgroup 'yarn_client', 'yarn', 'YARN Client'
      initgroup 'mapreduce', 'hadoop', 'MapReduce'
      initgroup 'mapred_jhs', 'mapreduce', 'MapReduce JobHistory Server'
      initgroup 'mapred_client', 'mapreduce', 'MapReduce Client'
      initgroup 'hbase', null, 'HBase'
      initgroup 'hbase_master', 'hbase', 'HBase Master'
      initgroup 'hbase_regionserver', 'hbase', 'HBase RegionServer'
      initgroup 'hbase_rest', 'hbase', 'HBase REST'
      initgroup 'hbase_thrift', 'hbase', 'HBase Thrift'
      initgroup 'hbase_client', 'hbase', 'HBase Client'
      initgroup 'phoenix'
      initgroup 'phoenix_master', 'phoenix', 'Phoenix Master'
      initgroup 'phoenix_regionserver', 'phoenix', 'Phoenix RegionServer'
      initgroup 'phoenix_client', 'phoenix', 'Phoenix Client'
      initgroup 'opentsdb', null, 'OpenTSDB'
      initgroup 'hive'
      initgroup 'hiveserver2', 'hive', 'HiveServer2'
      initgroup 'hcatalog', 'hive', 'HCatalog'
      initgroup 'webhcat', 'hive', 'WebHCat'
      initgroup 'hive_client', 'hive', 'WebHCat'
      initgroup 'tez'
      initgroup 'oozie'
      initgroup 'oozie_server', 'oozie', 'Oozie Server'
      initgroup 'oozie_client', 'oozie', 'Oozie Client'
      initgroup 'kafka'
      initgroup 'kafka_broker', 'kafka', 'Kafka Broker'
      initgroup 'kafka_producer', 'kafka', 'Kafka Producer'
      initgroup 'kafka_consumer', 'kafka', 'Kafka Consumer'
      initgroup 'spark'
      initgroup 'spark_hs', 'spark', 'Spark History Server'
      initgroup 'spark_client', 'spark', 'Spark Client'
      initgroup 'elasticsearch', null, 'ElasticSearch'
      initgroup 'solr', null, 'SolR'
      initgroup 'titan', null, 'Titan DB'
      initgroup 'rexster'
      initgroup 'pig'
      initgroup 'sqoop'
      initgroup 'falcon'
      initgroup 'flume'
      initgroup 'hue'
      initgroup 'knox'
      initgroup 'zeppelin'

## Configure from context

This function is called with a context, taken from internal context, or imported.
An external configuration can be obtained with a different instance of ryba using
'configure' command

    from_contexts = (servers, name)->
      servers ?= @contexts().map( (ctx) -> ctx.config )
      name ?= @config.ryba.nameservice or 'default'
      {shinken} = @config.ryba
      {hostgroups, hosts, clusters} = shinken.config
      clusters[name] ?= {}
      hostgroups[name] ?= {}
      hostgroups[name].members ?= []
      hostgroups[name].members = [hostgroups[name].members] unless Array.isArray hostgroups[name].members
      hostgroups[name].hostgroup_members ?= []
      hostgroups[name].hostgroup_members = [hostgroups[name].hostgroup_members] unless Array.isArray hostgroups[name].hostgroup_members
      hostgroups.by_topology.hostgroup_members.push name unless name in hostgroups.by_topology.hostgroup_members
      hostgroups[name].members.push name
      hosts[name] ?= {}
      hosts[name].ip = '0.0.0.0'
      hosts[name].alias = "#{name} Watcher"
      hosts[name].hostgroups = ['watcher']
      hosts[name].use = 'aggregates'
      hosts[name].cluster ?= name
      hosts[name].notes ?= name
      hosts[name].realm = clusters[name].realm if clusters[name].realm?
      hosts[name].modules ?= []
      hosts[name].modules = [hosts[name].modules] unless Array.isArray hosts[name].modules
      for srv in servers
        hostgroups[name].members.push srv.host
        hosts[srv.host] ?= {}
        hosts[srv.host].ip ?= srv.ip
        hosts[srv.host].hostgroups ?= []
        hosts[srv.host].hostgroups = [hosts[srv.host].hostgroups] unless Array.isArray hosts[srv.host].hostgroups
        hosts[srv.host].use ?= 'linux-server'
        hosts[srv.host].config ?= srv
        hosts[srv.host].realm ?= clusters[name].realm if clusters[name].realm?
        hosts[srv.host].cluster ?= name
        hosts[srv.host].notes ?= name
        for mod in srv.modules
          hosts[name].modules.push modules_list[mod] if modules_list[mod]? and modules_list[mod] not in hosts[name].modules
          hosts[srv.host].hostgroups.push modules_list[mod] if modules_list[mod]?

## Normalize

This function is called at the end to normalize values

    normalize = ->
      {shinken} = @config.ryba
      # HostGroups
      for name, group of shinken.config.hostgroups
        group.alias ?= name
        group.members ?= []
        group.members = [group.members] unless Array.isArray group.members
        group.hostgroup_members ?= []
        group.hostgroup_members = [group.hostgroup_members] unless Array.isArray group.hostgroup_members
      # Disable host membership !
      shinken.config.hostgroups.by_roles.members = []
      # Hosts
      for name, host of shinken.config.hosts
        host.alias ?= name
        host.use ?= 'generic-host'
        host.hostgroups = [host.hostgroups] unless Array.isArray host.hostgroups
      # ServiceGroups
      for name, group of shinken.config.servicegroups
        group.alias ?= "#{name.charAt(0).toUpperCase()}#{name.slice 1}"
        group.members ?= []
        group.members = [group.members] unless Array.isArray group.members
        group.servicegroup_members ?= []
        group.servicegroup_members = [group.servicegroup_members] unless Array.isArray group.servicegroup_members
      for name, service of shinken.config.services
        service.escalations = [service.escalations] if service.escalations? and not Array.isArray service.escalations
      # Realm
      default_realm = false
      for name, realm of shinken.config.realms
        realm.members ?= []
        realm.members = [realm.members] unless Array.isArray realm.members
        if realm.default is '1'
          throw Error 'Multiple default Realms detected. Please fix the configuration' if default_realm
          default_realm = true
        else realm.default = '0'
      shinken.config.realms.All.default = '1' unless default_realm
      shinken.config.realms.All.members ?= k unless k is 'All' for k in Object.keys shinken.config.realms
      # ContactGroups
      for name, group of shinken.config.contactgroups
        group.alias ?= name
        group.members ?= []
        group.members = [group.members] unless Array.isArray group.members
        group.contactgroup_members ?= []
        group.contactgroup_members = [group.contactgroup_members] unless Array.isArray group.contactgroup_members
      # Contacts
      for name, contact of shinken.config.contacts
        contact.alias ?= name
        contact.contactgroups ?= []
        contact.use ?= 'generic-contact'
        contact.contactgroups = [contact.contactgroups] unless Array.isArray contact.contactgroups
      # Dependencies
      for name, dep of shinken.config.dependencies
        throw Error "Unvalid dependency #{name}, please provide hosts or hostsgroups" unless dep.hosts? or dep.hostgroups?
        throw Error "Unvalid dependency #{name}, please provide dependent_hosts or dependent_hostsgroups" unless dep.dependent_hosts? or dep.dependent_hostgroups?
        throw Error "Unvalid dependency #{name}, please provide service" unless dep.service?
        throw Error "Unvalid dependency #{name}, please provide dependent_service" unless dep.dependent_service?
        dep.hosts = [dep.hosts] unless Array.isArray dep.hosts
        dep.hostgroups = [dep.hostgroups] unless Array.isArray dep.hostgroups
        dep.dependent_hosts = [dep.dependent_hosts] unless Array.isArray dep.dependent_hosts
        dep.dependent_hostgroups = [dep.dependent_hostgroups] unless Array.isArray dep.dependent_hostgroups
      # Escalations
      for name, esc of shinken.config.serviceescalations
        throw Error "Unvalid escalation #{name}, please provide hosts or hostsgroups" unless esc.hosts? or esc.hostgroups?
        throw Error "Unvalid escalation #{name}, please provide contacts or contactgroups" unless esc.contacts? or esc.contactgroups?
        throw Error "Unvalid escalation #{name}, please provide first_notification or first_notification_time" unless esc.first_notification? or esc.first_notification_time?
        throw Error "Unvalid escalation #{name}, please provide last_notification or last_notification_time" unless esc.last_notification? or esc.last_notification_time?
        esc.hosts = [esc.hosts] unless Array.isArray esc.hosts
        esc.hostgroups = [esc.hostgroups] unless Array.isArray esc.hostgroups
        esc.contacts = [esc.contacts] unless Array.isArray esc.contacts
        esc.contactgroups = [esc.contactgroups] unless Array.isArray esc.contactgroups
      for name, esc of shinken.config.escalations
        throw Error "Unvalid escalation #{name}, please provide contacts or contactgroups" unless esc.contacts? or esc.contactgroups?
        throw Error "Unvalid escalation #{name}, please provide first_notification or first_notification_time" unless esc.first_notification? or esc.first_notification_time?
        throw Error "Unvalid escalation #{name}, please provide last_notification or last_notification_time" unless esc.last_notification? or esc.last_notification_time?
        esc.contacts = [esc.contacts] unless Array.isArray esc.contacts
        esc.contactgroups = [esc.contactgroups] unless Array.isArray esc.contactgroups
      # Timeperiods
      for name, period of shinken.config.timeperiods
        period.alias ?= name
        period.time ?= {}

## Entrypoint

    module.exports = ->
      {shinken} = @config.ryba
      init.call @
      from_ryba.call @
      if shinken.exports_dir
        throw Error 'Invalid parameter: exports_dir should be false or a path' unless typeof shinken.exports_dir is 'string'
        for exp in glob.sync "#{shinken.exports_dir}/*"
          stat = fs.statSync exp
          clustername = path.parse(exp).name
          servers = []
          if stat.isFile()
            servers.push require exp
          else
            servers.push require k for k in glob.sync "#{exp}/*"
          from_contexts.call @, servers, clustername
      else
        from_contexts.call @
      normalize.call @

## Dependencies

For now, masson are ignored

'masson/commons/docker'
'masson/commons/phpldapadmin'
'masson/core/bind_server'
'masson/core/fstab'
'masson/core/iptables'
'masson/core/krb5_client'
'masson/core/krb5_server'
'masson/core/network'
'masson/core/network_check'
'masson/core/ntp'
'masson/core/openldap_client'
'masson/core/openldap_server'
'masson/core/openldap_server/install_acl'
'masson/core/openldap_server/install_krb5'
'masson/core/openldap_server/install_tls'
'masson/core/proxy'
'masson/core/reload'
'masson/core/security'
'masson/core/ssh'
'masson/core/sssd'
'masson/core/users'
'masson/core/yum'

    modules_list =
      'masson/commons/mysql_server': 'mysql_server'
      'ryba/elasticsearch': 'elasticsearch'
      'ryba/falcon': 'falcon'
      'ryba/flume': 'flume'
      'ryba/hadoop/hdfs_client': 'hdfs_client'
      'ryba/hadoop/hdfs_dn': 'hdfs_dn'
      'ryba/hadoop/hdfs_jn': 'hdfs_jn'
      'ryba/hadoop/hdfs_nn': 'hdfs_nn'
      'ryba/hadoop/httpfs': 'httpfs'
      'ryba/hadoop/mapred_client': 'mapred_client'
      'ryba/hadoop/mapred_jhs': 'mapred_jhs'
      'ryba/hadoop/yarn_client': 'yarn_client'
      'ryba/hadoop/yarn_nm': 'yarn_nm'
      'ryba/hadoop/yarn_rm': 'yarn_rm'
      'ryba/hadoop/yarn_ts': 'yarn_ts'
      'ryba/hadoop/zkfc': 'zkfc'
      'ryba/hbase/client': 'hbase_client'
      'ryba/hbase/master': 'hbase_master'
      'ryba/hbase/regionserver': 'hbase_regionserver'
      'ryba/hbase/rest': 'hbase_rest'
      'ryba/hive/client': 'hive_client'
      'ryba/hive/hcatalog': 'hcatalog'
      'ryba/hive/server2': 'hiveserver2'
      'ryba/hive/webhcat': 'webhcat'
      'ryba/hue': 'hue'
      'ryba/huedocker': 'hue'
      'ryba/kafka/broker': 'kafka_broker'
      'ryba/kafka/consumer': 'kafka_consumer'
      'ryba/kafka/producer': 'kafka_producer'
      'ryba/knox': 'knox'
      # 'ryba/mahout': 'mahout'
      'ryba/oozie/client': 'oozie_client'
      'ryba/oozie/server': 'oozie_server'
      'ryba/opentsdb': 'opentsdb'
      'ryba/phoenix/client': 'phoenix_client'
      'ryba/phoenix/master': 'phoenix_master'
      'ryba/phoenix/regionserver': 'phoenix_regionserver'
      'ryba/pig': 'pig'
      'ryba/rexster': 'rexster'
      'ryba/spark/client': 'spark_client'
      'ryba/spark/history_server': 'spark_hs'
      'ryba/sqoop': 'sqoop'
      'ryba/tez': 'tez'
      'ryba/zookeeper/client': 'zookeeper_client'
      'ryba/zookeeper/server': 'zookeeper_server'

    fs = require 'fs'
    glob = require 'glob'
    {merge} = require 'mecano/lib/misc'
    path = require 'path'
