
# Configure

    module.exports =

## Default Configuration

Default "shinken object" (servicegroups, hosts, etc) configuration.

      init: ->
        {shinken} = @config.ryba
        hostgroups = shinken.config.hostgroups ?= {}
        hosts = shinken.config.hosts ?= {}
        servicegroups = shinken.config.servicegroups ?= {}
        services = shinken.config.services ?= {}
        commands = shinken.config.commands ?= {}
        realms = shinken.config.realms ?= {}
        contactgroups = shinken.config.contactgroups ?= {}
        contacts = shinken.config.contacts ?= {}
        dependencies = shinken.config.dependencies ?= {}
        escalations = shinken.config.escalations ?= {}
        timeperiods = shinken.config.timeperiods ?= {}
        # Hostgroups
        hostgroups.by_roles ?= {}
        hostgroups.by_roles.alias ?= 'Role View'
        hostgroups.by_roles.hostgroup_members ?= []
        hostgroups.by_topology ?= {}
        hostgroups.by_topology.alias ?= 'Topological View'
        hostgroups.by_topology.hostgroup_members ?= []

### Templates

Templates are generic (abstract) objects that can define commons properties by heritage.
They must have register set to 0 to not be instanciated

        # Hosts
        hosts['generic-host'] ?= {}
        hosts['generic-host'].use ?= ''
        hosts['generic-host'].check_command ?= 'check_host'
        hosts['generic-host'].max_check_attempts ?= '2'
        hosts['generic-host'].check_interval ?= '1'
        hosts['generic-host'].retry_interval ?= '1'
        hosts['generic-host'].active_checks_enabled ?= '1'
        hosts['generic-host'].check_period ?= '24x7'
        hosts['generic-host'].event_handler_enabled ?= '0'
        hosts['generic-host'].flap_detection_enabled ?= '1'
        hosts['generic-host'].process_perf_data ?= '1'
        hosts['generic-host'].retain_status_information ?= '1'
        hosts['generic-host'].retain_nonstatus_information ?= '1'
        hosts['generic-host'].contactgroups ?= ['admins']
        hosts['generic-host'].notification_interval ?= '60'
        hosts['generic-host'].notification_period ?= '24x7'
        hosts['generic-host'].notification_options ?= 'd,u,r,f'
        hosts['generic-host'].notification_enabled ?= '1'
        hosts['generic-host'].register = '0' # IT'S A TEMPLATE !
        hosts['linux-server'] ?= {}
        hosts['linux-server'].use ?= 'generic-host'
        hosts['linux-server'].check_interval ?= '5'
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
        services['generic-service'].check_interval ?= '5'
        services['generic-service'].retry_interval ?= '1'
        services['generic-service'].contactgroups ?= 'admins'
        services['generic-service'].notifications_options ?= 'w,u,c,r'
        services['generic-service'].notification_interval ?= '60'
        services['generic-service'].notification_period ?= '24x7'
        services['generic-service'].register = '0'
        services['hadoop-service'] ?= {}
        services['hadoop-service'].use ?= 'generic-service'
        services['hadoop-service'].register ?= '0'
        services['hadoop-unit-service'] ?= {}
        services['hadoop-unit-service'].use ?= 'hadoop-service'
        services['hadoop-unit-service'].register = '0'
        services['hadoop-functional-service'] ?= {}
        services['hadoop-functional-service'].use ?= 'hadoop-service'
        services['hadoop-functional-service'].register = '0'
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

      from_ryba: ->
        {servicegroups, hostgroups} = @config.ryba.shinken.config
        initgroup = (name, parent, alias) ->
          servicegroups[name] ?= {}
          servicegroups[name].alias ?= (if alias then alias else "#{name.charAt(0).toUpperCase()}#{name.slice 1}") + ' Services'
          servicegroups[name].members ?= []
          servicegroups[name].servicegroup_members ?= []
          servicegroups[name].servicegroup_members = [servicegroups[name].servicegroup_members] unless Array.isArray servicegroups[name].servicegroup_members
          servicegroups[parent].servicegroup_members.push name if parent? and name not in servicegroups[parent].servicegroup_members
          hostgroups[name] ?= {}
          hostgroups[name].alias ?= (if alias then alias else "#{name.charAt(0).toUpperCase()}#{name.slice 1}") + ' Hosts'
          hostgroups[name].members ?= []
          hostgroups[name].hostgroup_members ?= []
          parent ?= 'by_roles'
          hostgroups[parent].hostgroup_members.push name unless name in hostgroups[parent].hostgroup_members
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

## Configure from exports

Ryba is able to export a fully-configured cluster. Exports can then be saved and used
by shinken to autoconfigure monitoring of the cluster.

For now masson modules are not available.

      from_exports: ->
        {shinken} = @config.ryba
        {hostgroups, hosts} = shinken.config
        if shinken.exports_dir? then for file in glob.sync "#{shinken.exports_dir}/*.coffee"
          name = path.basename file, '.coffee'
          {servers} = require file
          hostgroups[name] ?= {}
          hostgroups[name].members ?= []
          hostgroups[name].members = [hostgroups[name].members] unless Array.isArray hostgroups[name].members
          hostgroups[name].hostgroup_members ?= []
          hostgroups[name].hostgroup_members = [hostgroups[name].hostgroup_members] unless Array.isArray hostgroups[name].hostgroup_members
          hostgroups.by_topology.hostgroup_members.push name unless name in hostgroups.by_topology.hostgroup_members
          hostgroups[name].members.push "#{name}_aggregates"
          hosts["#{name}_aggregates"] ?= {}
          hosts["#{name}_aggregates"].ip = '0.0.0.0'
          hosts["#{name}_aggregates"].alias = "#{name} Aggregates"
          hosts["#{name}_aggregates"].hostgroups = []
          hosts["#{name}_aggregates"].use = 'aggregates'
          for hostname, srv of servers
            hostgroups[name].members.push hostname
            hosts[hostname] ?= {}
            hosts[hostname].ip ?= srv.ip
            hosts[hostname].hostgroups ?= []
            hosts[hostname].use ?= 'linux-server'
            for mod in srv.modules
              hosts[hostname].hostgroups.push modules_list[mod] if modules_list[mod]?
          shinken.exports = merge.apply @, (srv for _, srv of servers)

## Normalize

This function is called at the end to normalize values

      normalize: ->
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
        # ServiceGroups
        for name, group of shinken.config.servicegroups
          group.alias ?= "#{name.charAt(0).toUpperCase()}#{name.slice 1}"
          group.members ?= []
          group.members = [group.members] unless Array.isArray group.members
          group.servicegroup_members ?= []
          group.servicegroup_members = [group.servicegroup_members] unless Array.isArray group.servicegroup_members
        #
        #for name, service of shinken.config.services
        
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
        for name, esc of shinken.config.escalations
          throw Error "Unvalid escalation #{name}, please provide hosts or hostsgroups" unless esc.hosts? or esc.hostgroups?
          throw Error "Unvalid escalation #{name}, please provide contacts or contactgroups" unless esc.contacts? or esc.contactgroups?
          esc.hosts = [esc.hosts] unless Array.isArray esc.hosts
          esc.hostgroups = [esc.hostgroups] unless Array.isArray esc.hostgroups
          esc.contacts = [esc.contacts] unless Array.isArray esc.contacts
          esc.contactgroups = [esc.contactgroups] unless Array.isArray esc.contactgroups
        # Timeperiods
        for name, period of shinken.config.timeperiods
          period.alias ?= name
          period.time ?= {}

## Dependencies

For now, masson are ignored

'masson/commons/docker'
'masson/commons/mysql_server'
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

    glob = require 'glob'
    {merge} = require 'mecano/lib/misc'
    path = require 'path'