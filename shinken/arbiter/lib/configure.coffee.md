
# Configure

    module.exports =

## Default Configuration

Default "shinken object" (servicegroups, hosts, etc) configuration.

      servicegroups: ->
        {servicegroups} = @config.ryba.shinken.config
        initgroup = (name, alias) ->
          servicegroups[name] ?= {}
          servicegroups[name].alias ?= if alias then alias else "#{name.charAt(0).toUpperCase()}#{name.slice 1} Services"
          servicegroups[name].members ?= []
          servicegroups[name].servicegroup_members ?= []
          servicegroups[name].servicegroup_members = [servicegroups[name].servicegroup_members] unless Array.isArray servicegroups[name].servicegroup_members
        addgroup = (group, name) ->
          servicegroups[name].servicegroup_members.push group unless group in servicegroups[name].servicegroup_members

        initgroup 'zookeeper'
        initgroup 'zookeeper_server', 'Zookeeper Server Services'
        addgroup 'zookeeper_server', 'zookeeper'
        initgroup 'zookeeper_client', 'Zookeeper Client Services'
        addgroup 'zookeeper_client', 'zookeeper'
        initgroup 'hadoop'
        initgroup 'hdfs', 'HDFS Services'
        addgroup 'hdfs', 'hadoop'
        initgroup 'hdfs_nn', 'HDFS NameNode Services'
        addgroup 'hdfs_nn', 'hdfs'
        initgroup 'hdfs_jn', 'HDFS JournalNode Services'
        addgroup 'hdfs_jn', 'hdfs'
        initgroup 'zkfc', 'HDFS ZKFC Services'
        addgroup 'zkfc', 'hdfs'
        initgroup 'hdfs_dn', 'HDFS DataNode Services'
        addgroup 'hdfs_dn', 'hdfs'
        initgroup 'httpfs', 'HttpFS Services'
        addgroup 'httpfs', 'hdfs'
        initgroup 'hdfs_client', 'HDFS Client Services'
        addgroup 'hdfs_client', 'hdfs'
        initgroup 'yarn', 'YARN Services'
        addgroup 'yarn', 'hadoop'
        initgroup 'yarn_rm', 'YARN ResourceManager Services'
        addgroup 'yarn_rm', 'yarn'
        initgroup 'yarn_nm', 'YARN NodeManager Services'
        addgroup 'yarn_nm', 'yarn'
        initgroup 'yarn_ts', 'YARN Timeline Server Services'
        addgroup 'yarn_ts', 'yarn'
        initgroup 'mapreduce', 'MapReduce Services'
        addgroup 'mapreduce', 'hadoop'
        initgroup 'mapred_jhs', 'MapReduce JobHistory Server Services'
        addgroup 'mapred_jhs', 'mapreduce'
        initgroup 'mapred_client', 'MapReduce Client Services'
        addgroup 'mapred_client', 'mapreduce'
        initgroup 'hbase', 'HBase Services'
        initgroup 'hbase_master', 'HBase Master Services'
        addgroup 'hbase_master', 'hbase'
        initgroup 'hbase_regionserver', 'HBase RegionServer Services'
        addgroup 'hbase_regionserver', 'hbase'
        initgroup 'hbase_rest', 'HBase REST Services'
        addgroup 'hbase_rest', 'hbase'
        initgroup 'hbase_thrift', 'RegionServer Services'
        addgroup 'hbase_thrift', 'hbase'
        initgroup 'phoenix'
        initgroup 'phoenix_master', 'Phoenix Master Services'
        addgroup 'phoenix_master', 'phoenix'
        initgroup 'phoenix_regionserver', 'Phoenix RegionServer Services'
        addgroup 'phoenix_regionserver', 'phoenix'
        initgroup 'phoenix_client', 'Phoenix Client Services'
        addgroup 'phoenix_client', 'phoenix'
        initgroup 'hive'
        initgroup 'hiveserver2', 'HiveServer2 Services'
        addgroup 'hiveserver2', 'hive'
        initgroup 'hcatalog', 'HCatalog Services'
        addgroup 'hcatalog', 'hive'
        initgroup 'webhcat', 'WebHCat Services'
        addgroup 'webhcat', 'hive'
        initgroup 'hive_client', 'WebHCat Services'
        addgroup 'hive_client', 'hive'
        initgroup 'oozie'
        initgroup 'oozie_server', 'Oozie Server Services'
        addgroup 'oozie_server', 'oozie'
        initgroup 'oozie_client', 'Oozie Client Services'
        addgroup 'oozie_client', 'oozie'
        initgroup 'kafka'
        initgroup 'kafka_broker', 'Kafka Broker Services'
        addgroup 'kafka_broker', 'kafka'
        initgroup 'spark'
        initgroup 'spark_hs', 'Spark History Server Services'
        addgroup 'spark_hs', 'spark'
        initgroup 'spark_client', 'Spark Client Services'
        addgroup 'spark_client', 'spark'
        initgroup 'elasticsearch', 'ElasticSearch Services'
        initgroup 'solr', 'SolR Services'
        initgroup 'titan', 'Titan DB Services'
        initgroup 'rexster'
        initgroup 'pig'
        initgroup 'falcon'
        initgroup 'flume'
        initgroup 'hue'
        initgroup 'zeppelin'

## Configure from exports

Ryba is able to export a fully-configured cluster. Exports can then be saved and used
by shinken to autoconfigure monitoring of the cluster.

      from_exports: ->
        {shinken} = @config.ryba
        {hostgroups, hosts, realms} = shinken.config
        if shinken.exports_dir? then for file in glob.sync "#{shinken.exports_dir}/*.coffee"
          name = path.basename file
          {servers} = require file
          realms[name] ?= {}
          hostgroups[name] ?= {}
          hostgroups[name].members ?= []
          hostgroups[name].members = [hostgroups[name].members] unless Array.isArray hostgroups[name].members
          hostgroups[name].hostgroup_members ?= []
          hostgroups[name].hostgroup_members = [hostgroups[name].hostgroup_members] unless Array.isArray hostgroups[name].hostgroup_members
          hostgroups[name].realm ?= name
          for hostname, srv of servers
            hostgroups[name].members.push hostname
            hosts[hostname] ?= {}
            hosts[hostname].ip ?= srv.ip

## Normalize

This function is called at the end to normalize values

      normalize: ->
        {shinken} = @config.ryba
        # HostGroups
        for name, group of shinken.config.hostgroups
          group.alias ?= name
          group.members = [group.members] unless Array.isArray group.members
          group.hostgroup_members = [group.hostgroup_members] unless Array.isArray group.hostgroup_members
        # Hosts
        for name, host of shinken.config.hosts
          host.alias ?= name
        # ServiceGroups
        for name, group of shinken.config.servicegroups
          group.alias ?= "#{name.charAt(0).toUpperCase()}#{name.slice 1} Services"
          group.members = [group.members] unless Array.isArray group.members
          group.servicegroup_members = [group.servicegroup_members] unless Array.isArray group.servicegroup_members
        # Services
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
        realms.All.default = '1' unless default_realm
        realms.All.members ?= k unless k is 'All' for k in Object.keys realms
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
          contact.contactgroups = [contact.contactgroups] unless Array.isArray contact.contactgroups
          contact.host_notifications_enabled ?= '1'
          contact.service_notifications_enabled ?= '1'
          contact.host_notifications_period ?= '24x7'
          contact.service_notifications_period ?= '24x7'
          contact.host_notifications_options ?= 'd,u,r'
          contact.service_notifications_options ?= 'w,u,c,r'
          contact.host_notifications_command ?= 'notify-host-by-email'
          contact.service_notifications_command ?= 'notify-service-by-email'
        for name, dep of shinken.config.dependencies
          throw Error "Unvalid dependency #{name}, please provide hosts or hostsgroups" unless dep.hosts? or dep.hostgroups?
          throw Error "Unvalid dependency #{name}, please provide dependent_hosts or dependent_hostsgroups" unless dep.dependent_hosts? or dep.dependent_hostgroups?
          throw Error "Unvalid dependency #{name}, please provide service" unless dep.service?
          throw Error "Unvalid dependency #{name}, please provide dependent_service" unless dep.dependent_service?
          dep.hosts = [dep.hosts] unless Array.isArray dep.hosts
          dep.hostgroups = [dep.hostgroups] unless Array.isArray dep.hostgroups
          dep.dependent_hosts = [dep.dependent_hosts] unless Array.isArray dep.dependent_hosts
          dep.dependent_hostgroups = [dep.dependent_hostgroups] unless Array.isArray dep.dependent_hostgroups
        for name, esc of shinken.config.escalations
          throw Error "Unvalid escalation #{name}, please provide hosts or hostsgroups" unless esc.hosts? or esc.hostgroups?
          throw Error "Unvalid escalation #{name}, please provide contacts or contactgroups" unless esc.contacts? or esc.contactgroups?
          esc.hosts = [esc.hosts] unless Array.isArray esc.hosts
          esc.hostgroups = [esc.hostgroups] unless Array.isArray esc.hostgroups
          esc.contacts = [esc.contacts] unless Array.isArray esc.contacts
          esc.contactgroups = [esc.contactgroups] unless Array.isArray esc.contactgroups
          
        for name, period of shinken.config.timeperiods
          period.alias ?= name
          period.time ?= {}

## Dependencies

    glob = require 'glob'
    path = require 'path'
