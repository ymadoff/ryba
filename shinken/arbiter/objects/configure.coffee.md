
# Configure Shinken Objects

    module.exports = ->
      {shinken} = @config.ryba

## Default Configuration

Default "shinken object" (servicegroups, hosts, etc) configuration.

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
      hosts['generic-host'].check_period ?= 'everytime'
      hosts['generic-host'].event_handler_enabled ?= '0'
      hosts['generic-host'].flap_detection_enabled ?= '1'
      hosts['generic-host'].process_perf_data ?= '1'
      hosts['generic-host'].retain_status_information ?= '1'
      hosts['generic-host'].retain_nonstatus_information ?= '1'
      hosts['generic-host'].contactgroups ?= ['admins']
      hosts['generic-host'].notification_interval ?= '3600'
      hosts['generic-host'].notification_period ?= 'everytime'
      hosts['generic-host'].notification_options ?= 'd,u,r,f'
      hosts['generic-host'].notification_enabled ?= '1'
      hosts['generic-host'].register = '0' # IT'S A TEMPLATE !
      hosts['linux-server'] ?= {}
      hosts['linux-server'].use ?= 'generic-host'
      hosts['linux-server'].check_interval ?= '60'
      hosts['linux-server'].retry_interval ?= '20'
      hosts['linux-server'].register = '0' # IT'S A TEMPLATE !
      hosts['aggregates'] ?= {}
      hosts['aggregates'].use ?= 'generic-host'
      hosts['aggregates'].check_command ?= 'ok'
      hosts['aggregates'].register = '0' # IT'S A TEMPLATE !
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
      services['generic-service'].check_period ?= 'everytime'
      services['generic-service'].max_check_attempts ?= '2'
      services['generic-service'].check_interval ?= '300'
      services['generic-service'].retry_interval ?= '60'
      services['generic-service'].contactgroups ?= 'admins'
      services['generic-service'].notifications_options ?= 'w,u,c,r'
      services['generic-service'].notification_interval ?= '3600'
      services['generic-service'].notification_period ?= 'everytime'
      services['generic-service'].business_rule_output_template ?= '$($HOSTNAME$: $SERVICEDESC$)$'
      services['generic-service'].register = '0'
      services['unit-service'] ?= {}
      services['unit-service'].use ?= 'generic-service'
      services['unit-service'].register = '0'
      services['unit-service'].check_interval = '30'
      services['unit-service'].retry_interval = '10'
      services['bp-service'] ?= {}
      services['bp-service'].use ?= 'unit-service'
      services['bp-service'].register ?= '0'
      services['process-service'] ?= {}
      services['process-service'].use ?= 'unit-service'
      services['process-service'].event_handler_enabled ?= '1'
      services['process-service'].event_handler ?= 'service_start!$_SERVICEPROCESS_NAME$'
      services['process-service'].register = '0'
      services['cert-service'] ?= {}
      services['cert-service'].use ?= 'unit-service'
      services['cert-service'].check_interval = '1800'
      services['cert-service'].register ?= '0'
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
      contacts['generic-contact'].service_notification_period ?= 'everytime'
      contacts['generic-contact'].host_notification_period ?= 'everytime'
      contacts['generic-contact'].service_notification_options ?= 'w,u,c,r,f'
      contacts['generic-contact'].host_notification_options ?= 'd,u,r,f,s'
      contacts['generic-contact'].service_notification_commands ?= 'notify-service-by-email'
      contacts['generic-contact'].host_notification_commands ?= 'notify-host-by-email'
      contacts['generic-contact'].host_notifications_enabled ?= '1'
      contacts['generic-contact'].service_notifications_enabled ?= '1'
      contacts['generic-contact'].can_submit_commands ?= '0'
      contacts['generic-contact'].register = '0'
      contacts['admin-contact'] ?= {}
      contacts['admin-contact'].use ?= 'generic-contact'
      contacts['admin-contact'].can_submit_commands ?= '1'
      contacts['admin-contact'].is_admin ?= '1'
      contacts['admin-contact'].contactgroups ?= ['admins']
      contacts['admin-contact'].register = '0'
      contacts['readonly-contact'] ?= {}
      contacts['readonly-contact'].use ?= 'generic-contact'
      contacts['readonly-contact'].contactgroups ?= ['readonly']
      contacts['readonly-contact'].host_notifications_enabled ?= '0'
      contacts['readonly-contact'].service_notifications_enabled ?= '0'
      contacts['readonly-contact'].register = '0'
      contacts['shinken'] ?= {}
      contacts['shinken'].contactgroups ?= []
      contacts['shinken'].contactgroups.push 'admins' unless 'admins' in contacts['shinken'].contactgroups
      # Timeperiods
      timeperiods['everytime'] ?= {}
      timeperiods['everytime'].alias ?= 'Everytime'
      timeperiods['everytime'].time ?= {}
      for day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
        timeperiods['everytime'].time[day] ?= '00:00-24:00'
      # Timeperiods
      timeperiods['office'] ?= {}
      timeperiods['office'].alias ?= 'Office time'
      timeperiods['office'].time ?= {}
      for day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday']
        timeperiods['office'].time[day] ?= '07:00-19:00'
      timeperiods.none ?= {}
      timeperiods.none.alias ?= 'Never'
      timeperiods.none.time = {}
      # Commands
      commands['notify-host-by-email'] ?= '/usr/bin/printf "%b" "Shinken Notification\\n\\nType: $NOTIFICATIONTYPE$\\nHost: $HOSTNAME$\\nState: $HOSTSTATE$\\nAddress: $HOSTADDRESS$\\nDate: $SHORTDATETIME$\\nInfo: $HOSTOUTPUT$" | mailx -s "Host $NOTIFICATIONTYPE$: $HOSTNAME$ is $HOSTSTATE$" $CONTACTEMAIL$'
      commands['notify-service-by-email'] ?= '/usr/bin/printf "%b" "Shinken Notification\\n\\nNotification Type: $NOTIFICATIONTYPE$\\n\\nService: $SERVICEDESC$\\nHost:$HOSTALIAS$\\nAddress: $HOSTADDRESS$\\nState: $SERVICESTATE$\\nDate: $SHORTDATETIME$\\nInfo : $SERVICEOUTPUT$" | mailx -s "Service $NOTIFICATIONTYPE$: $SERVICEDESC$ ($HOSTALIAS$) is $SERVICESTATE$"  $CONTACTEMAIL$'

## Object from Ryba

This function creates hostgroups and servicegroups from ryba (sub)modules

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

      create_dependency = (s1, s2, h1, h2) ->
        h2 ?= h1
        dep = shinken.config.dependencies["#{s1} / #{s2}"] ?= {}
        dep.service ?= s2
        dep.dependent_service ?= s1
        dep.hosts ?= [h2]
        dep.dependent_hosts ?= [h1]
        dep.inherits_parent ?= '1'
        dep.execution_failure_criteria ?= 'c,u,p'
        dep.notification_failure_criteria ?= 'c,u,p'

### Declare ALL services

      # initgroup 'mysql'
      # initgroup 'mysql_server', 'mysql', 'MySQL Server'
      # initgroup 'zookeeper'
      # initgroup 'zookeeper_server', 'zookeeper', 'Zookeeper Server'
      # initgroup 'zookeeper_client', 'zookeeper', 'Zookeeper Client'
      # initgroup 'hadoop'
      # initgroup 'hdfs', 'hadoop', 'HDFS'
      # initgroup 'hdfs_nn', 'hdfs', 'HDFS NameNode'
      # initgroup 'hdfs_jn', 'hdfs', 'HDFS JournalNode'
      # initgroup 'zkfc', 'hdfs', 'HDFS ZKFC'
      # initgroup 'hdfs_dn', 'hdfs', 'HDFS DataNode'
      # initgroup 'httpfs', 'hdfs', 'HttpFS'
      # initgroup 'hdfs_client', 'hdfs', 'HDFS Client'
      # initgroup 'yarn', 'hadoop', 'YARN'
      # initgroup 'yarn_rm', 'yarn', 'YARN ResourceManager'
      # initgroup 'yarn_nm', 'yarn', 'YARN NodeManager'
      # initgroup 'yarn_ts', 'yarn', 'YARN Timeline Server'
      # initgroup 'yarn_client', 'yarn', 'YARN Client'
      # initgroup 'mapreduce', 'hadoop', 'MapReduce'
      # initgroup 'mapred_jhs', 'mapreduce', 'MapReduce JobHistory Server'
      # initgroup 'mapred_client', 'mapreduce', 'MapReduce Client'
      # initgroup 'hbase', null, 'HBase'
      # initgroup 'hbase_master', 'hbase', 'HBase Master'
      # initgroup 'hbase_regionserver', 'hbase', 'HBase RegionServer'
      # initgroup 'hbase_rest', 'hbase', 'HBase REST'
      # initgroup 'hbase_thrift', 'hbase', 'HBase Thrift'
      # initgroup 'hbase_client', 'hbase', 'HBase Client'
      # initgroup 'phoenix'
      # initgroup 'phoenix_master', 'phoenix', 'Phoenix Master'
      # initgroup 'phoenix_regionserver', 'phoenix', 'Phoenix RegionServer'
      # initgroup 'phoenix_client', 'phoenix', 'Phoenix Client'
      # initgroup 'opentsdb', null, 'OpenTSDB'
      # initgroup 'hive'
      # initgroup 'hiveserver2', 'hive', 'HiveServer2'
      # initgroup 'hcatalog', 'hive', 'HCatalog'
      # initgroup 'webhcat', 'hive', 'WebHCat'
      # initgroup 'hive_client', 'hive', 'WebHCat'
      # initgroup 'tez'
      # initgroup 'oozie'
      # initgroup 'oozie_server', 'oozie', 'Oozie Server'
      # initgroup 'oozie_client', 'oozie', 'Oozie Client'
      # initgroup 'kafka'
      # initgroup 'kafka_broker', 'kafka', 'Kafka Broker'
      # initgroup 'kafka_producer', 'kafka', 'Kafka Producer'
      # initgroup 'kafka_consumer', 'kafka', 'Kafka Consumer'
      # initgroup 'spark'
      # initgroup 'spark_hs', 'spark', 'Spark History Server'
      # initgroup 'spark_client', 'spark', 'Spark Client'
      # initgroup 'elasticsearch', null, 'ElasticSearch'
      # initgroup 'solr', null, 'SolR'
      # initgroup 'titan', null, 'Titan DB'
      # initgroup 'rexster'
      # initgroup 'pig'
      # initgroup 'sqoop'
      # initgroup 'falcon'
      # initgroup 'flume'
      # initgroup 'hue'
      # initgroup 'knox'
      # initgroup 'zeppelin'

## Configure from context

This function is called with a context, taken from internal context, or imported.
An external configuration can be obtained with an instance of ryba using
'configure' command

Theses functions are used to generate business rules

      bp_miss = (n, name, g) -> "bp_rule!(100%,1,-#{n} of: #{ if g? then "g:#{g}" else '*'},r:^#{name}?)"
      bp_has_quorum = (name, g) -> "bp_rule!(100%,1,50% of: #{ if g? then "g:#{g}" else '*'},r:^#{name}?)"
      bp_has_one = (name, g) -> "bp_rule!(100%,1,100% of: #{ if g? then "g:#{g}" else '*'},r:^#{name}?)"
      bp_has_all = (name, g) -> "bp_rule!(100%,1,1 of: #{ if g? then "g:#{g}" else '*'},r:^#{name}?)"
      #bp_has_percent = (name, w, c, g) -> "bp_rule!(100%,#{w}%,#{c}% of: #{ if g? then "g:#{g}" else '*'},r:^#{name}?)"

      from_contexts = (ctxs) ->
        clustername = ctxs[0].config.ryba.nameservice or 'default'
        clusters[clustername] ?= {}
        hg = hostgroups[clustername] ?= {}
        hg.members ?= []
        hg.members = [hg.members] unless Array.isArray hg.members
        hg.hostgroup_members ?= []
        hg.hostgroup_members = [hg.hostgroup_members] unless Array.isArray hg.hostgroup_members
        hostgroups.by_topology.hostgroup_members.push clustername unless clustername in hostgroups.by_topology.hostgroup_members
        # Watchers -> Special host with name of the cluster, for cluster business rules
        w = hosts[clustername] ?= {}
        w.ip = '0.0.0.0'
        w.alias = "#{clustername} Watcher"
        w.hostgroups = ['watcher']
        w.use = 'aggregates'
        w.cluster ?= clustername
        w.notes ?= clustername
        w.realm = clusters[clustername].realm if clusters[clustername].realm?
        w.modules ?= []
        w.modules = [w.modules] unless Array.isArray w.modules
        hostgroups[clustername].members.push clustername
        # True Servers
        for ctx in ctxs
          {host, shortname, ip, ryba, mysql} = ctx.config
          hostgroups[clustername].members.push host
          h = hosts[host] ?= {}
          h.ip ?= ip
          h.hostgroups ?= []
          h.hostgroups = [h.hostgroups] unless Array.isArray h.hostgroups
          h.use ?= 'linux-server'
          #h.config ?= ctx.config
          h.realm ?= clusters[clustername].realm
          h.cluster ?= clustername
          h.notes ?= clustername

###  Declare services

          # TODO: put db_admin username/password
          if 'masson/commons/mysql/server' in ctx.services
            w.modules.push 'mysql_server' if 'mysql_server' not in w.modules
            h.hostgroups.push 'mysql_server' if 'mysql_server' not in h.hostgroups
            services['MySQL - TCP'] ?= {}
            services['MySQL - TCP'].hosts ?= []
            services['MySQL - TCP'].hosts.push host
            services['MySQL - TCP'].servicegroups ?= ['mysql_server']
            services['MySQL - TCP'].use ?= 'process-service'
            services['MySQL - TCP']['_process_name'] ?= 'mysqld'
            services['MySQL - TCP'].check_command ?= "check_tcp!#{mysql.server.my_cnf.mysqld.port}"
            if ryba.db_admin?.mysql?.admin_username? and ryba.db_admin?.mysql?.admin_password?
              services['MySQL - Connection time'] ?= {}
              services['MySQL - Connection time'].hosts ?= []
              services['MySQL - Connection time'].hosts.push host
              services['MySQL - Connection time'].servicegroups ?= ['mysql_server']
              services['MySQL - Connection time'].use ?= 'unit-service'
              services['MySQL - Connection time'].check_command ?= "check_mysql!#{mysql.server.my_cnf.mysqld.port}!connection-time!3!10!#{ryba.db_admin.mysql.admin_username}!#{ryba.db_admin.mysql.admin_password}"
              create_dependency 'MySQL - Connection time', 'MySQL - TCP', host
              services['MySQL - Slow queries'] ?= {}
              services['MySQL - Slow queries'].hosts ?= []
              services['MySQL - Slow queries'].hosts.push host
              services['MySQL - Slow queries'].servicegroups ?= ['mysql_server']
              services['MySQL - Slow queries'].use ?= 'functional-service'
              services['MySQL - Slow queries'].check_command ?= "check_mysql!#{mysql.server.my_cnf.mysqld.port}!!slow-queries!0,25!1!!#{ryba.db_admin.mysql.admin_username}!#{ryba.db_admin.mysql.admin_password}"
              create_dependency 'MySQL - Slow queries', 'MySQL - TCP', host
              services['MySQL - Slave lag'] ?= {}
              services['MySQL - Slave lag'].hosts ?= []
              services['MySQL - Slave lag'].hosts.push host
              services['MySQL - Slave lag'].servicegroups ?= ['mysql_server']
              services['MySQL - Slave lag'].use ?= 'unit-service'
              services['MySQL - Slave lag'].check_command ?= "check_mysql!#{mysql.server.my_cnf.mysqld.port}!slave-lag!3!10!#{ryba.db_admin.mysql.admin_username}!#{ryba.db_admin.mysql.admin_password}"
              create_dependency 'MySQL - Slave lag', 'MySQL - TCP', host
              services['MySQL - Slave IO running'] ?= {}
              services['MySQL - Slave IO running'].hosts ?= []
              services['MySQL - Slave IO running'].hosts.push host
              services['MySQL - Slave IO running'].servicegroups ?= ['mysql_server']
              services['MySQL - Slave IO running'].use ?= 'unit-service'
              services['MySQL - Slave IO running'].check_command ?= "check_mysql!#{mysql.server.my_cnf.mysqld.port}!slave-io-running!1!1!#{ryba.db_admin.mysql.admin_username}!#{ryba.db_admin.mysql.admin_password}"
              create_dependency 'MySQL - Slave IO running', 'MySQL - TCP', host
              services['MySQL - Connected Threads'] ?= {}
              services['MySQL - Connected Threads'].hosts ?= []
              services['MySQL - Connected Threads'].hosts.push host
              services['MySQL - Connected Threads'].servicegroups ?= ['mysql_server']
              services['MySQL - Connected Threads'].use ?= 'unit-service'
              services['MySQL - Connected Threads'].check_command ?= "check_mysql!#{mysql.server.my_cnf.mysqld.port}!threads-connected!50!80!#{ryba.db_admin.mysql.admin_username}!#{ryba.db_admin.mysql.admin_password}"
              create_dependency 'MySQL - Connected Threads', 'MySQL - TCP', host
          if 'ryba/zookeeper/server' in ctx.services
            w.modules.push 'zookeeper_server' if 'zookeeper_server' not in w.modules
            h.hostgroups.push 'zookeeper_server' if 'zookeeper_server' not in h.hostgroups
            services['Zookeeper Server - TCP'] ?= {}
            services['Zookeeper Server - TCP'].hosts ?= []
            services['Zookeeper Server - TCP'].hosts.push host
            services['Zookeeper Server - TCP'].servicegroups ?= ['zookeeper_server']
            services['Zookeeper Server - TCP'].use ?= 'process-service'
            services['Zookeeper Server - TCP']['_process_name'] ?= 'zookeeper-server'
            services['Zookeeper Server - TCP'].check_command ?= "check_tcp!#{ryba.zookeeper.port}"
            services['Zookeeper Server - State'] ?= {}
            services['Zookeeper Server - State'].hosts ?= []
            services['Zookeeper Server - State'].hosts.push host
            services['Zookeeper Server - State'].servicegroups ?= ['zookeeper_server']
            services['Zookeeper Server - State'].use ?= 'unit-service'
            services['Zookeeper Server - State'].check_command ?= "check_socket!#{ryba.zookeeper.port}!ruok!imok"
            create_dependency 'Zookeeper Server - State', 'Zookeeper Server - TCP', host
            services['Zookeeper Server - Connections'] ?= {}
            services['Zookeeper Server - Connections'].hosts ?= []
            services['Zookeeper Server - Connections'].hosts.push host
            services['Zookeeper Server - Connections'].servicegroups ?= ['zookeeper_server']
            services['Zookeeper Server - Connections'].use ?= 'unit-service'
            services['Zookeeper Server - Connections'].check_command ?= "check_zk_stat!#{ryba.zookeeper.port}!connections!300!350"
            create_dependency 'Zookeeper Server - Connections', 'Zookeeper Server - TCP', host
          if 'ryba/hadoop/hdfs_nn' in ctx.services
            w.modules.push 'hdfs_nn' if 'hdfs_nn' not in w.modules
            h.hostgroups.push 'hdfs_nn' if 'hdfs_nn' not in h.hostgroups
            services['HDFS NN - TCP'] ?= {}
            services['HDFS NN - TCP'].hosts ?= []
            services['HDFS NN - TCP'].hosts.push host
            services['HDFS NN - TCP'].servicegroups ?= ['hdfs_nn']
            services['HDFS NN - TCP'].use ?= 'process-service'
            services['HDFS NN - TCP']['_process_name'] ?= 'hadoop-hdfs-namenode'
            rpc = ryba.hdfs.nn.site["dfs.namenode.rpc-address.#{ryba.nameservice}.#{shortname}"].split(':')[1]
            services['HDFS NN - TCP'].check_command ?= "check_tcp!#{rpc}"
            services['HDFS NN - WebService'] ?= {}
            services['HDFS NN - WebService'].hosts ?= []
            services['HDFS NN - WebService'].hosts.push host
            services['HDFS NN - WebService'].servicegroups ?= ['hdfs_nn']
            services['HDFS NN - WebService'].use ?= 'unit-service'
            https = ryba.hdfs.nn.site["dfs.namenode.https-address.#{ryba.nameservice}.#{shortname}"].split(':')[1]
            services['HDFS NN - WebService'].check_command ?= "check_tcp!#{https}!-S"
            create_dependency 'HDFS NN - WebService', 'HDFS NN - TCP', host
            services['HDFS NN - Certificate'] ?= {}
            services['HDFS NN - Certificate'].hosts ?= []
            services['HDFS NN - Certificate'].hosts.push host
            services['HDFS NN - Certificate'].servicegroups ?= ['hdfs_nn']
            services['HDFS NN - Certificate'].use ?= 'cert-service'
            services['HDFS NN - Certificate'].check_command ?= "check_cert!#{https}!120!60"
            create_dependency 'HDFS NN - Certificate', 'HDFS NN - WebService', host
            services['HDFS NN - RPC latency'] ?= {}
            services['HDFS NN - RPC latency'].hosts ?= []
            services['HDFS NN - RPC latency'].hosts.push host
            services['HDFS NN - RPC latency'].servicegroups ?= ['hdfs_nn']
            services['HDFS NN - RPC latency'].use ?= 'unit-service'
            services['HDFS NN - RPC latency'].check_command ?= "check_rpc_latency!NameNode!#{https}!3000!5000!-S"
            create_dependency 'HDFS NN - RPC latency', 'HDFS NN - WebService', host
            services['HDFS NN - Last checkpoint'] ?= {}
            services['HDFS NN - Last checkpoint'].hosts ?= []
            services['HDFS NN - Last checkpoint'].hosts.push host
            services['HDFS NN - Last checkpoint'].servicegroups ?= ['hdfs_nn']
            services['HDFS NN - Last checkpoint'].use ?= 'unit-service'
            services['HDFS NN - Last checkpoint'].check_command ?= "check_nn_last_checkpoint!#{https}!21600!1000000!120%!200%!-S"
            create_dependency 'HDFS NN - RPC latency', 'HDFS NN - WebService', host
            services['HDFS NN - Name Dir status'] ?= {}
            services['HDFS NN - Name Dir status'].hosts ?= []
            services['HDFS NN - Name Dir status'].hosts.push host
            services['HDFS NN - Name Dir status'].servicegroups ?= ['hdfs_nn']
            services['HDFS NN - Name Dir status'].use ?= 'unit-service'
            services['HDFS NN - Name Dir status'].check_command ?= "check_nn_namedirs_status!#{https}!-S"
            create_dependency 'HDFS NN - Name Dir status', 'HDFS NN - WebService', host
            services['HDFS NN - Utilization'] ?= {}
            services['HDFS NN - Utilization'].hosts ?= []
            services['HDFS NN - Utilization'].hosts.push host
            services['HDFS NN - Utilization'].servicegroups ?= ['hdfs_nn']
            services['HDFS NN - Utilization'].use ?= 'unit-service'
            services['HDFS NN - Utilization'].check_command ?= "check_hdfs_capacity!#{https}!80%!90%!-S"
            create_dependency 'HDFS NN - Utilization', 'HDFS NN - WebService', host
            services['HDFS NN - UnderReplicated blocks'] ?= {}
            services['HDFS NN - UnderReplicated blocks'].hosts ?= []
            services['HDFS NN - UnderReplicated blocks'].hosts.push host
            services['HDFS NN - UnderReplicated blocks'].servicegroups ?= ['hdfs_nn']
            services['HDFS NN - UnderReplicated blocks'].use ?= 'unit-service'
            services['HDFS NN - UnderReplicated blocks'].check_command ?= "check_hdfs_state!#{https}!FSNamesystemState!UnderReplicatedBlocks!1000!2000!-S"
            create_dependency 'HDFS NN - UnderReplicated blocks', 'HDFS NN - WebService', host
          if 'ryba/hadoop/hdfs_jn' in ctx.services
            w.modules.push 'hdfs_jn' if 'hdfs_jn' not in w.modules
            h.hostgroups.push 'hdfs_jn' if 'hdfs_jn' not in h.hostgroups
            services['HDFS JN - TCP SSL'] ?= {}
            services['HDFS JN - TCP SSL'].hosts ?= []
            services['HDFS JN - TCP SSL'].hosts.push host
            services['HDFS JN - TCP SSL'].servicegroups ?= ['hdfs_jn']
            services['HDFS JN - TCP SSL'].use ?= 'process-service'
            services['HDFS JN - TCP SSL']['_process_name'] ?= 'hadoop-hdfs-journalnode'
            https = ryba.hdfs.site['dfs.journalnode.https-address'].split(':')[1]
            services['HDFS JN - TCP SSL'].check_command ?= "check_tcp!#{https}!-S"
            services['HDFS JN - Certificate'] ?= {}
            services['HDFS JN - Certificate'].hosts ?= []
            services['HDFS JN - Certificate'].hosts.push host
            services['HDFS JN - Certificate'].servicegroups ?= ['hdfs_jn']
            services['HDFS JN - Certificate'].use ?= 'process-service'
            services['HDFS JN - Certificate'].check_command ?= "check_cert!#{https}!120!60"
            create_dependency 'HDFS JN - Certificate', 'HDFS JN - TCP SSL', host
          if '/ryba/hadoop/hdfs_dn' in ctx.services
            w.modules.push 'hdfs_dn' if 'hdfs_dn' not in w.modules
            h.hostgroups.push 'hdfs_dn' if 'hdfs_dn' not in h.hostgroups
            services['HDFS DN - TCP SSL'] ?= {}
            services['HDFS DN - TCP SSL'].hosts ?= []
            services['HDFS DN - TCP SSL'].hosts.push host
            services['HDFS DN - TCP SSL'].servicegroups ?= ['hdfs_dn']
            services['HDFS DN - TCP SSL'].use ?= 'process-service'
            services['HDFS DN - TCP SSL']['_process_name'] ?= 'hadoop-hdfs-datanode'
            services['HDFS DN - TCP SSL'].check_command ?= "check_tcp!#{ryba.hdfs.site['dfs.datanode.https.address'].split(':')[1]}!-S"
            services['HDFS DN - Certificate'] ?= {}
            services['HDFS DN - Certificate'].hosts ?= []
            services['HDFS DN - Certificate'].hosts.push host
            services['HDFS DN - Certificate'].servicegroups ?= ['hdfs_dn']
            services['HDFS DN - Certificate'].use ?= 'cert-service'
            services['HDFS DN - Certificate'].check_command ?= "check_cert!#{ryba.hdfs.site['dfs.datanode.https.address'].split(':')[1]}!120!60"
            create_dependency 'HDFS DN - Certificate', 'HDFS DN - TCP SSL', host
            services['HDFS DN - Free space'] ?= {}
            services['HDFS DN - Free space'].hosts ?= []
            services['HDFS DN - Free space'].hosts.push host
            services['HDFS DN - Free space'].servicegroups ?= ['hdfs_dn']
            services['HDFS DN - Free space'].use ?= 'unit-service'
            services['HDFS DN - Free space'].check_command ?= "check_dn_storage!#{ryba.hdfs.site['dfs.datanode.https.address'].split(':')[1]}!75%!90%!-S"
            create_dependency 'HDFS DN - Free space', 'HDFS DN - TCP SSL', host
          if 'ryba/hadoop/zkfc' in ctx.services
            w.modules.push 'hdfs_zkfc' if 'hdfs_zkfc' not in w.modules
            h.hostgroups.push 'hdfs_zkfc' if 'hdfs_zkfc' not in h.hostgroups
            services['ZKFC - TCP'] ?= {}
            services['ZKFC - TCP'].hosts ?= []
            services['ZKFC - TCP'].hosts.push host
            services['ZKFC - TCP'].servicegroups ?= ['hdfs_zkfc']
            services['ZKFC - TCP'].use ?= 'process-service'
            services['ZKFC - TCP']['_process_name'] ?= 'hadoop-hdfs-zkfc'
            services['ZKFC - TCP'].check_command ?= "check_tcp!#{ryba.hdfs.nn.site['dfs.ha.zkfc.port']}"
          if 'ryba/hadoop/httpfs' in ctx.services
            w.modules.push 'httpfs' if 'httpfs' not in w.modules
            h.hostgroups.push 'httpfs' if 'httpfs' not in h.hostgroups
            services['HttpFS - WebService'] ?= {}
            services['HttpFS - WebService'].hosts ?= []
            services['HttpFS - WebService'].hosts.push host
            services['HttpFS - WebService'].servicegroups ?= ['httpfs']
            services['HttpFS - WebService'].use ?= 'process-service'
            services['HttpFS - WebService']['_process_name'] ?= 'hadoop-httpfs'
            services['HttpFS - WebService'].check_command ?= "check_tcp!#{ryba.httpfs.http_port}"
            services['HttpFS - Certificate'] ?= {}
            services['HttpFS - Certificate'].hosts ?= []
            services['HttpFS - Certificate'].hosts.push host
            services['HttpFS - Certificate'].servicegroups ?= ['httpfs']
            services['HttpFS - Certificate'].use ?= 'cert-service'
            services['HttpFS - Certificate'].check_command ?= "check_cert!#{ryba.httpfs.http_port}!120!60"
            create_dependency 'HttpFS - Certificate', 'HttpFS - WebService', host
          if 'ryba/hadoop/yarn_rm' in ctx.services
            w.modules.push 'yarn_rm' if 'yarn_rm' not in w.modules
            h.hostgroups.push 'yarn_rm' if 'yarn_rm' not in h.hostgroups
            services['YARN RM - Admin TCP'] ?= {}
            services['YARN RM - Admin TCP'].hosts ?= []
            services['YARN RM - Admin TCP'].hosts.push host
            services['YARN RM - Admin TCP'].servicegroups ?= ['yarn_rm']
            services['YARN RM - Admin TCP'].use ?= 'process-service'
            services['YARN RM - Admin TCP']['_process_name'] ?= 'hadoop-yarn-resourcemanager'
            services['YARN RM - Admin TCP'].check_command ?= "check_tcp!8141"
            services['YARN RM - WebService'] ?= {}
            services['YARN RM - WebService'].hosts ?= []
            services['YARN RM - WebService'].hosts.push host
            services['YARN RM - WebService'].servicegroups ?= ['yarn_rm']
            services['YARN RM - WebService'].use ?= 'unit-service'
            services['YARN RM - WebService'].check_command ?= 'check_tcp!8090!-S'
            services['YARN RM - Certificate'] ?= {}
            services['YARN RM - Certificate'].hosts ?= []
            services['YARN RM - Certificate'].hosts.push host
            services['YARN RM - Certificate'].servicegroups ?= ['yarn_rm']
            services['YARN RM - Certificate'].use ?= 'cert-service'
            services['YARN RM - Certificate'].check_command ?= "check_cert!8090!120!60"
            create_dependency 'YARN RM - Certificate', 'YARN RM - WebService', host
          if 'ryba/hadoop/yarn_nm' in ctx.services
            w.modules.push 'yarn_nm' if 'yarn_nm' not in w.modules
            h.hostgroups.push 'yarn_nm' if 'yarn_nm' not in h.hostgroups
            services['YARN NM - TCP'] ?= {}
            services['YARN NM - TCP'].hosts ?= []
            services['YARN NM - TCP'].hosts.push host
            services['YARN NM - TCP'].servicegroups ?= ['yarn_nm']
            services['YARN NM - TCP'].use ?= 'process-service'
            services['YARN NM - TCP']['_process_name'] ?= 'hadoop-yarn-nodemanager'
            services['YARN NM - TCP'].check_command ?= "check_tcp!45454"
            services['YARN NM - WebService'] ?= {}
            services['YARN NM - WebService'].hosts ?= []
            services['YARN NM - WebService'].hosts.push host
            services['YARN NM - WebService'].servicegroups ?= ['yarn_nm']
            services['YARN NM - WebService'].use ?= 'unit-service'
            services['YARN NM - WebService'].check_command ?= 'check_tcp!8044!-S'
            services['YARN NM - Certificate'] ?= {}
            services['YARN NM - Certificate'].hosts ?= []
            services['YARN NM - Certificate'].hosts.push host
            services['YARN NM - Certificate'].servicegroups ?= ['yarn_nm']
            services['YARN NM - Certificate'].use ?= 'cert-service'
            services['YARN NM - Certificate'].check_command ?= 'check_cert!8044!120!60'
            create_dependency 'YARN NM - Certificate', 'YARN NM - WebService', host
            services['YARN NM - Health'] ?= {}
            services['YARN NM - Health'].hosts ?= []
            services['YARN NM - Health'].hosts.push host
            services['YARN NM - Health'].servicegroups ?= ['yarn_nm']
            services['YARN NM - Health'].use ?= 'unit-service'
            services['YARN NM - Health'].check_command ?= 'check_nm_info!8044!nodeHealthy!true!-S'
            create_dependency 'YARN NM - Health', 'YARN NM - WebService', host
          if 'ryba/hadoop/yarn_ts' in ctx.services
            w.modules.push 'yarn_ts' if 'yarn_ts' not in w.modules
            h.hostgroups.push 'yarn_ts' if 'yarn_ts' not in h.hostgroups
            services['YARN TS - TCP'] ?= {}
            services['YARN TS - TCP'].hosts ?= []
            services['YARN TS - TCP'].hosts.push host
            services['YARN TS - TCP'].servicegroups ?= ['yarn_ts']
            services['YARN TS - TCP'].use ?= 'process-service'
            services['YARN TS - TCP']['_process_name'] ?= 'hadoop-yarn-timelineserver'
            services['YARN TS - TCP'].check_command ?= "check_tcp!10200"
            services['YARN TS - WebService'] ?= {}
            services['YARN TS - WebService'].hosts ?= []
            services['YARN TS - WebService'].hosts.push host
            services['YARN TS - WebService'].servicegroups ?= ['yarn_ts']
            services['YARN TS - WebService'].use ?= 'unit-service'
            services['YARN TS - WebService'].check_command ?= 'check_tcp!8190!-S'
            services['YARN TS - Certificate'] ?= {}
            services['YARN TS - Certificate'].hosts ?= []
            services['YARN TS - Certificate'].hosts.push host
            services['YARN TS - Certificate'].servicegroups ?= ['yarn_ts']
            services['YARN TS - Certificate'].use ?= 'cert-service'
            services['YARN TS - Certificate'].check_command ?= 'check_cert!8190!120!60'
            create_dependency 'YARN TS - Certificate', 'YARN TS - WebService', host
          if 'ryba/hbase/master' in ctx.services
            w.modules.push 'hbase_master' if 'hbase_master' not in w.modules
            h.hostgroups.push 'hbase_master' if 'hbase_master' not in h.hostgroups
            services['HBase Master - TCP'] ?= {}
            services['HBase Master - TCP'].hosts ?= []
            services['HBase Master - TCP'].hosts.push host
            services['HBase Master - TCP'].servicegroups ?= ['hbase_master']
            services['HBase Master - TCP'].use ?= 'process-service'
            services['HBase Master - TCP']['_process_name'] ?= 'hbase-master'
            services['HBase Master - TCP'].check_command ?= "check_tcp!#{ryba.hbase.master.site['hbase.master.port']}"
            services['HBase Master - WebUI'] ?= {}
            services['HBase Master - WebUI'].hosts ?= []
            services['HBase Master - WebUI'].hosts.push host
            services['HBase Master - WebUI'].servicegroups ?= ['hbase_master']
            services['HBase Master - WebUI'].use ?= 'unit-service'
            services['HBase Master - WebUI'].check_command ?= "check_tcp!#{ryba.hbase.master.site['hbase.master.info.port']}!-S"
            create_dependency 'HBase Master - WebUI', 'HBase Master - TCP', host
            services['HBase Master - Certificate'] ?= {}
            services['HBase Master - Certificate'].hosts ?= []
            services['HBase Master - Certificate'].hosts.push host
            services['HBase Master - Certificate'].servicegroups ?= ['hbase_master']
            services['HBase Master - Certificate'].use ?= 'cert-service'
            services['HBase Master - Certificate'].check_command ?= "check_cert!#{ryba.hbase.master.site['hbase.master.info.port']}!120!60"
            create_dependency 'HBase Master - Certificate', 'HBase Master - WebUI', host
          if 'ryba/hbase/regionserver' in ctx.services
            w.modules.push 'hbase_regionserver' if 'hbase_regionserver' not in w.modules
            h.hostgroups.push 'hbase_regionserver' if 'hbase_regionserver' not in h.hostgroups
            services['HBase RegionServer - TCP'] ?= {}
            services['HBase RegionServer - TCP'].hosts ?= []
            services['HBase RegionServer - TCP'].hosts.push host
            services['HBase RegionServer - TCP'].servicegroups ?= ['hbase_regionserver']
            services['HBase RegionServer - TCP'].use ?= 'process-service'
            services['HBase RegionServer - TCP']['_process_name'] ?= 'hbase-regionserver'
            services['HBase RegionServer - TCP'].check_command ?= "check_tcp!#{ryba.hbase.rs.site['hbase.regionserver.port']}"
            services['HBase RegionServer - WebUI'] ?= {}
            services['HBase RegionServer - WebUI'].hosts ?= []
            services['HBase RegionServer - WebUI'].hosts.push host
            services['HBase RegionServer - WebUI'].servicegroups ?= ['hbase_regionserver']
            services['HBase RegionServer - WebUI'].use ?= 'unit-service'
            services['HBase RegionServer - WebUI'].check_command ?= "check_tcp!#{ryba.hbase.rs.site['hbase.regionserver.info.port']}!-S"
            services['HBase RegionServer - Certificate'] ?= {}
            services['HBase RegionServer - Certificate'].hosts ?= []
            services['HBase RegionServer - Certificate'].hosts.push host
            services['HBase RegionServer - Certificate'].servicegroups ?= ['hbase_regionserver']
            services['HBase RegionServer - Certificate'].use ?= 'cert-service'
            services['HBase RegionServer - Certificate'].check_command ?= "check_cert!#{ryba.hbase.rs.site['hbase.regionserver.info.port']}!120!60"
            create_dependency 'HBase RegionServer - Certificate', 'HBase RegionServer - WebUI', host
          if 'ryba/hbase/rest' in ctx.services
            w.modules.push 'hbase_rest' if 'hbase_rest' not in w.modules
            h.hostgroups.push 'hbase_rest' if 'hbase_rest' not in h.hostgroups
            services['HBase REST - WebService'] ?= {}
            services['HBase REST - WebService'].hosts ?= []
            services['HBase REST - WebService'].hosts.push host
            services['HBase REST - WebService'].servicegroups ?= ['hbase_rest']
            services['HBase REST - WebService'].use ?= 'process-service'
            services['HBase REST - WebService']['_process_name'] ?= 'hbase-rest'
            services['HBase REST - WebService'].check_command ?= "check_tcp!#{ryba.hbase.rest.site['hbase.rest.port']}!-S"
            services['HBase REST - Certificate'] ?= {}
            services['HBase REST - Certificate'].hosts ?= []
            services['HBase REST - Certificate'].hosts.push host
            services['HBase REST - Certificate'].servicegroups ?= ['hbase_rest']
            services['HBase REST - Certificate'].use ?= 'cert-service'
            services['HBase REST - Certificate'].check_command ?= "check_cert!#{ryba.hbase.rest.site['hbase.rest.port']}!120!60"
            create_dependency 'HBase REST - Certificate', 'HBase REST - WebService', host
            services['HBase REST - WebUI'] ?= {}
            services['HBase REST - WebUI'].hosts ?= []
            services['HBase REST - WebUI'].hosts.push host
            services['HBase REST - WebUI'].servicegroups ?= ['hbase_rest']
            services['HBase REST - WebUI'].use ?= 'unit-service'
            services['HBase REST - WebUI'].check_command ?= "check_tcp!#{ryba.hbase.rest.site['hbase.rest.info.port']}"
          if 'ryba/hbase/thrift' in ctx.services
            w.modules.push 'hbase_thrift' if 'hbase_thrift' not in w.modules
            h.hostgroups.push 'hbase_thrift' if 'hbase_thrift' not in h.hostgroups
            services['HBase Thrift - TCP SSL'] ?= {}
            services['HBase Thrift - TCP SSL'].hosts ?= []
            services['HBase Thrift - TCP SSL'].hosts.push host
            services['HBase Thrift - TCP SSL'].servicegroups ?= ['hbase_thrift']
            services['HBase Thrift - TCP SSL'].use ?= 'process-service'
            services['HBase Thrift - TCP SSL']['_process_name'] ?= 'hbase-thrift'
            services['HBase Thrift - TCP SSL'].check_command ?= "check_tcp!#{ryba.hbase.thrift.site['hbase.thrift.port']}!-S"
            services['HBase Thrift - Certificate'] ?= {}
            services['HBase Thrift - Certificate'].hosts ?= []
            services['HBase Thrift - Certificate'].hosts.push host
            services['HBase Thrift - Certificate'].servicegroups ?= ['hbase_thrift']
            services['HBase Thrift - Certificate'].use ?= 'cert-service'
            services['HBase Thrift - Certificate'].check_command ?= "check_cert!#{ryba.hbase.thrift.site['hbase.thrift.port']}!120!60"
            create_dependency 'HBase Thrift - Certificate', 'HBase Thrift - TCP SSL', host
          if 'ryba/hive/hcatalog' in ctx.services
            w.modules.push 'hcatalog' if 'hcatalog' not in w.modules
            h.hostgroups.push 'hcatalog' if 'hcatalog' not in h.hostgroups
            services['HCatalog - TCP'] ?= {}
            services['HCatalog - TCP'].hosts ?= []
            services['HCatalog - TCP'].hosts.push host
            services['HCatalog - TCP'].servicegroups ?= ['hcatalog']
            services['HCatalog - TCP'].use ?= 'process-service' #'unit-service'
            #services['HCatalog - TCP']['_process_name'] ?= 'hive-hcatalog-server'
            services['HCatalog - TCP'].check_command ?= "check_tcp!#{ryba.hive.server2.site['hive.metastore.uris'].split(',')[0].split(':')[2]}"
          if 'ryba/hive/server2' in ctx.services
            w.modules.push 'hiveserver2' if 'hiveserver2' not in w.modules
            h.hostgroups.push 'hiveserver2' if 'hiveserver2' not in h.hostgroups
            services['Hiveserver2 - TCP SSL'] ?= {}
            services['Hiveserver2 - TCP SSL'].hosts ?= []
            services['Hiveserver2 - TCP SSL'].hosts.push host
            services['Hiveserver2 - TCP SSL'].servicegroups ?= ['hiveserver2']
            services['Hiveserver2 - TCP SSL'].use ?= 'unit-service' #'process-service'
            # services['Hiveserver2 - TCP SSL']['_process_name'] ?= 'hive-server2'
            services['Hiveserver2 - TCP SSL'].check_command ?= "check_tcp!#{ryba.hive.server2.site['hive.server2.thrift.port']}!-S"
            services['Hiveserver2 - Certificate'] ?= {}
            services['Hiveserver2 - Certificate'].hosts ?= []
            services['Hiveserver2 - Certificate'].hosts.push host
            services['Hiveserver2 - Certificate'].servicegroups ?= ['hiveserver2']
            services['Hiveserver2 - Certificate'].use ?= 'cert-service'
            services['Hiveserver2 - Certificate'].check_command ?= "check_cert!#{ryba.hive.server2.site['hive.server2.thrift.port']}!120!60"
            create_dependency 'Hiveserver2 - Certificate', 'Hiveserver2 - TCP SSL', host
          if 'ryba/hive/webhcat' in ctx.services
            w.modules.push 'webhcat' if 'webhcat' not in w.modules
            h.hostgroups.push 'webhcat' if 'webhcat' not in h.hostgroups
            services['WebHCat - WebService'] ?= {}
            services['WebHCat - WebService'].hosts ?= []
            services['WebHCat - WebService'].hosts.push host
            services['WebHCat - WebService'].servicegroups ?= ['webhcat']
            services['WebHCat - WebService'].use ?= 'process-service'
            services['WebHCat - WebService']['_process_name'] ?= 'hive-webhcat-server'
            services['WebHCat - WebService'].check_command ?= "check_tcp!#{ryba.webhcat.site['templeton.port']}"
            services['WebHCat - Status'] ?= {}
            services['WebHCat - Status'].hosts ?= []
            services['WebHCat - Status'].hosts.push host
            services['WebHCat - Status'].servicegroups ?= ['webhcat']
            services['WebHCat - Status'].use ?= 'unit-service'
            services['WebHCat - Status'].check_command ?= "check_webhcat_status!#{ryba.webhcat.site['templeton.port']}"
            create_dependency 'WebHCat - Status', 'WebHCat - WebService', host
            services['WebHCat - Database'] ?= {}
            services['WebHCat - Database'].hosts ?= []
            services['WebHCat - Database'].hosts.push host
            services['WebHCat - Database'].servicegroups ?= ['webhcat']
            services['WebHCat - Database'].use ?= 'unit-service'
            services['WebHCat - Database'].check_command ?= "check_webhcat_database!#{ryba.webhcat.site['templeton.port']}"
            create_dependency 'WebHCat - Database', 'WebHCat - WebService', host
          if 'ryba/oozie/server' in ctx.services
            w.modules.push 'oozie_server' if 'oozie_server' not in w.modules
            h.hostgroups.push 'oozie_server' if 'oozie_server' not in h.hostgroups
            services['Oozie Server - WebUI'] ?= {}
            services['Oozie Server - WebUI'].hosts ?= []
            services['Oozie Server - WebUI'].hosts.push host
            services['Oozie Server - WebUI'].servicegroups ?= ['oozie_server']
            services['Oozie Server - WebUI'].use ?= 'process-service'
            services['Oozie Server - WebUI']['_process_name'] ?= 'oozie'
            services['Oozie Server - WebUI'].check_command ?= "check_tcp!#{ryba.oozie.http_port}!-S"
            services['Oozie Server - Certificate'] ?= {}
            services['Oozie Server - Certificate'].hosts ?= []
            services['Oozie Server - Certificate'].hosts.push host
            services['Oozie Server - Certificate'].servicegroups ?= ['oozie_server']
            services['Oozie Server - Certificate'].use ?= 'cert-service'
            services['Oozie Server - Certificate'].check_command ?= "check_cert!#{ryba.oozie.http_port}!120!60"
            create_dependency 'Oozie Server - Certificate', 'Oozie Server - WebUI', host
          if 'ryba/kafka/broker' in ctx.services
            w.modules.push 'kafka_broker' if 'kafka_broker' not in w.modules
            h.hostgroups.push 'kafka_broker' if 'kafka_broker' not in h.hostgroups
            for protocol in ryba.kafka.broker.protocols
              services["Kafka Broker - TCP #{protocol}"] ?= {}
              services["Kafka Broker - TCP #{protocol}"].hosts ?= []
              services["Kafka Broker - TCP #{protocol}"].hosts.push host
              services["Kafka Broker - TCP #{protocol}"].servicegroups ?= ['kafka_broker']
              services["Kafka Broker - TCP #{protocol}"].use ?= 'unit-service'
              services["Kafka Broker - TCP #{protocol}"].check_command ?= "check_tcp!#{ryba.kafka.broker.ports[protocol]}"
            services['Kafka Broker - TCPs'] ?= {}
            services['Kafka Broker - TCPs'].hosts ?= []
            services['Kafka Broker - TCPs'].hosts.push host
            services['Kafka Broker - TCPs'].servicegroups ?= ['kafka_broker']
            services['Kafka Broker - TCPs'].use ?= 'process-service'
            services['Kafka Broker - TCPs']['_process_name'] ?= 'kafka-broker'
            services['Kafka Broker - TCPs'].check_command ?= "bp_rule!($HOSTNAME$,r:^Kafka Broker - TCP .*$)"
          if 'ryba/ranger/admin' in ctx.services
            w.modules.push 'ranger-admin' if 'ranger-admin' not in w.modules
            h.hostgroups.push 'ranger-admin' if 'ranger-admin' not in h.hostgroups
            services['Ranger - WebUI'] ?= {}
            services['Ranger - WebUI'].hosts ?= []
            services['Ranger - WebUI'].hosts.push host
            services['Ranger - WebUI'].servicegroups ?= ['ranger-admin']
            services['Ranger - WebUI'].use ?= 'process-service'
            services['Ranger - WebUI']['_process_name'] ?= 'ranger-admin'
            if ryba.ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
              services['Ranger - WebUI'].check_command ?= "check_tcp!#{ranger.admin.site['ranger.service.https.port']}!-S"
              services['Ranger - Certificate'] ?= {}
              services['Ranger - Certificate'].hosts ?= []
              services['Ranger - Certificate'].hosts.push host
              services['Ranger - Certificate'].servicegroups ?= ['ranger-admin']
              services['Ranger - Certificate'].use ?= 'cert-service'
              services['Ranger - Certificate'].check_command ?= "check_cert!#{ranger.admin.site['ranger.service.https.port']}!120!60"
              create_dependency 'Ranger - Certificate', 'Ranger - WebUI', host
            else
              services['Ranger - WebUI'].check_command ?= "check_tcp!#{ranger.admin.site['ranger.service.http.port']}"
          if 'ryba/opentsdb' in ctx.services
            w.modules.push 'opentsdb' if 'opentsdb' not in w.modules
            h.hostgroups.push 'opentsdb' if 'opentsdb' not in h.hostgroups
            services['OpenTSDB - WebService'] ?= {}
            services['OpenTSDB - WebService'].hosts ?= []
            services['OpenTSDB - WebService'].hosts.push host
            services['OpenTSDB - WebService'].servicegroups ?= ['opentsdb']
            services['OpenTSDB - WebService'].use ?= 'process-service'
            services['OpenTSDB - WebService']['_process_name'] ?= 'opentsdb'
            services['OpenTSDB - WebService'].check_command ?= "check_tcp!#{ryba.opentsdb.config['tsd.network.port']}"
          if 'ryba/elasticsearch' in ctx.services
            w.modules.push 'elasticsearch' if 'elasticsearch' not in w.modules
            h.hostgroups.push 'elasticsearch' if 'elasticsearch' not in h.hostgroups
            services['ElasticSearch - WebService'] ?= {}
            services['ElasticSearch - WebService'].hosts ?= []
            services['ElasticSearch - WebService'].hosts.push host
            services['ElasticSearch - WebService'].servicegroups ?= ['elasticsearch']
            services['ElasticSearch - WebService'].use ?= 'process-service'
            services['ElasticSearch - WebService']['_process_name'] ?= 'elasticsearch'
            services['ElasticSearch - WebService'].check_command ?= 'check_tcp!9200'
            services['ElasticSearch - TCP'] ?= {}
            services['ElasticSearch - TCP'].hosts ?= []
            services['ElasticSearch - TCP'].hosts.push host
            services['ElasticSearch - TCP'].servicegroups ?= ['elasticsearch']
            services['ElasticSearch - TCP'].use ?= 'unit-service'
            services['ElasticSearch - TCP'].check_command ?= 'check_tcp!9300'
          if 'ryba/rexster' in ctx.services
            w.modules.push 'rexster' if 'rexster' not in w.modules
            h.hostgroups.push 'rexster' if 'rexster' not in h.hostgroups
            services['Rexster - WebUI'] ?= {}
            services['Rexster - WebUI'].hosts ?= []
            services['Rexster - WebUI'].hosts.push host
            services['Rexster - WebUI'].servicegroups ?= ['rexster']
            services['Rexster - WebUI'].use ?= 'process-service'
            services['Rexster - WebUI']['_process_name'] ?= 'rexster'
            services['Rexster - WebUI'].check_command ?= "check_tcp!#{ryba.rexster.config.http['server-port']}"
          if 'ryba/huedocker' in ctx.services
            w.modules.push 'hue' if 'hue' not in w.modules
            h.hostgroups.push 'hue' if 'hue' not in h.hostgroups
            services['Hue - WebUI'] ?= {}
            services['Hue - WebUI'].hosts ?= []
            services['Hue - WebUI'].hosts.push host
            services['Hue - WebUI'].servicegroups ?= ['hue']
            services['Hue - WebUI'].use ?= 'process-service'
            services['Hue - WebUI']['_process_name'] ?= 'hue-server-docker'
            if ryba.hue_docker.ssl
              services['Hue - WebUI'].check_command ?= "check_tcp!#{ryba.hue_docker.ini.desktop.http_port}!-S"
              services['Hue - Certificate'] ?= {}
              services['Hue - Certificate'].hosts ?= []
              services['Hue - Certificate'].hosts.push host
              services['Hue - Certificate'].servicegroups ?= ['hue']
              services['Hue - Certificate'].use ?= 'cert-service'
              services['Hue - Certificate'].check_command ?= "check_cert!#{ryba.hue_docker.ini.desktop.http_port}!120!60"
            else
              services['Hue - WebUI'].check_command ?= "check_tcp!#{ryba.hue_docker.ini.desktop.http_port}"
            create_dependency 'Hue - Certificate', 'Hue - WebUI', host
          if 'ryba/knox' in ctx.services
            w.modules.push 'knox' if 'knox' not in w.modules
            h.hostgroups.push 'knox' if 'knox' not in h.hostgroups
            services['Knox - WebService'] ?= {}
            services['Knox - WebService'].hosts ?= []
            services['Knox - WebService'].hosts.push host
            services['Knox - WebService'].servicegroups ?= ['knox']
            services['Knox - WebService'].use ?= 'process-service'
            services['Knox - WebService']['_process_name'] ?= 'knox-server'
            services['Knox - WebService'].check_command ?= "check_tcp!#{ryba.knox.site['gateway.port']}!-S"
            services['Knox - Certificate'] ?= {}
            services['Knox - Certificate'].hosts ?= []
            services['Knox - Certificate'].hosts.push host
            services['Knox - Certificate'].servicegroups ?= ['knox']
            services['Knox - Certificate'].use ?= 'cert-service'
            services['Knox - Certificate'].check_command ?= "check_cert!#{ryba.knox.site['gateway.port']}!120!60"
            create_dependency 'Knox - Certificate', 'Knox - WebService', host
          if 'ryba/nifi' in ctx.services
            {properties} = ryba.nifi.config
            w.modules.push 'nifi' if 'nifi' not in w.modules
            h.hostgroups.push 'nifi' if 'nifi' not in h.hostgroups
            # get nifi port
            services['NiFi - WebUI'] ?= {}
            services['NiFi - WebUI'].hosts ?= []
            services['NiFi - WebUI'].hosts.push host
            services['NiFi - WebUI'].servicegroups ?= ['nifi']
            services['NiFi - WebUI'].use ?= 'process-service'
            services['NiFi - WebUI']['_process_name'] ?= 'nifi'
            if properties['nifi.cluster.protocol.is.secure'] is 'true'
              services['NiFi - WebUI'].check_command ?= "check_tcp!#{properties['nifi.web.https.port']}!-S"
              services['NiFi - Certificate'] ?= {}
              services['NiFi - Certificate'].hosts ?= []
              services['NiFi - Certificate'].hosts.push host
              services['NiFi - Certificate'].servicegroups ?= ['nifi']
              services['NiFi - Certificate'].use ?= 'cert-service'
              services['NiFi - Certificate'].check_command ?= "check_cert!#{properties['nifi.web.https.port']}!120!60"
              create_dependency 'NiFi - Certificate', 'NiFi - WebUI', host
            else
              services['NiFi - WebUI'].check_command ?= "check_tcp!#{properties['nifi.web.http.port']}"
            services['NiFi - TCP'] ?= {}
            services['NiFi - TCP'].hosts ?= []
            services['NiFi - TCP'].hosts.push host
            services['NiFi - TCP'].servicegroups ?= ['nifi']
            services['NiFi - TCP'].use ?= 'unit-service'
            services['NiFi - TCP'].check_command ?= "check_tcp!#{properties['nifi.cluster.node.protocol.port']}"
            create_dependency 'NiFi - TCP', 'NiFi - WebUI', host

### Watcher services

        if 'mysql_server' in w.modules
          services['MySQL - Available'] ?= {}
          services['MySQL - Available'].hosts ?= []
          services['MySQL - Available'].hosts.push clustername
          services['MySQL - Available'].servicegroups ?= ['hadoop']
          services['MySQL - Available'].use ?= 'bp-service'
          services['MySQL - Available'].check_command ?= bp_has_one 'MySQL - TCP', '$HOSTNAME$'
        if 'zookeeper_server' in w.modules
          services['Zookeeper Server - Available'] ?= {}
          services['Zookeeper Server - Available'].hosts ?= []
          services['Zookeeper Server - Available'].hosts.push clustername
          services['Zookeeper Server - Available'].servicegroups ?= ['zookeeper_server']
          services['Zookeeper Server - Available'].use ?= 'bp-service'
          services['Zookeeper Server - Available'].check_command ?= bp_has_quorum 'Zookeeper Server - TCP', '$HOSTNAME$'
        if 'hdfs_nn' in w.modules
          services['HDFS NN - Available'] ?= {}
          services['HDFS NN - Available'].hosts ?= []
          services['HDFS NN - Available'].hosts.push clustername
          services['HDFS NN - Available'].servicegroups ?= ['hdfs_nn']
          services['HDFS NN - Available'].use ?= 'bp-service'
          services['HDFS NN - Available'].check_command ?= bp_has_one 'HDFS NN - TCP', '$HOSTNAME$'
          services['HDFS NN - Active Node'] ?= {}
          services['HDFS NN - Active Node'].hosts ?= []
          services['HDFS NN - Active Node'].hosts.push clustername
          services['HDFS NN - Active Node'].servicegroups ?= ['hdfs_nn']
          services['HDFS NN - Active Node'].use ?= 'unit-service'
          services['HDFS NN - Active Node'].check_command ?= 'check_active_nn!50470!-S'
        if 'hdfs_zkfc' in w.modules
          services['ZKFC - Available'] ?= {}
          services['ZKFC - Available'].hosts ?= []
          services['ZKFC - Available'].hosts.push clustername
          services['ZKFC - Available'].servicegroups ?= ['hdfs_zkfc']
          services['ZKFC - Available'].use ?= 'bp-service'
          services['ZKFC - Available'].check_command ?= bp_has_all 'ZKFC - TCP', '$HOSTNAME$'
          create_dependency 'ZKFC - Available', 'Zookeeper Server - Available', name
        if 'hdfs_jn' in w.modules
          services['HDFS JN - Available'] ?= {}
          services['HDFS JN - Available'].hosts ?= []
          services['HDFS JN - Available'].hosts.push clustername
          services['HDFS JN - Available'].servicegroups ?= ['hdfs_jn']
          services['HDFS JN - Available'].use ?= 'bp-service'
          services['HDFS JN - Available'].check_command ?= bp_has_quorum 'HDFS JN - TCP SSL', '$HOSTNAME$'
        if 'hdfs_dn' in w.modules
          services['HDFS DN - Available'] ?= {}
          services['HDFS DN - Available'].hosts ?= []
          services['HDFS DN - Available'].hosts.push clustername
          services['HDFS DN - Available'].servicegroups ?= ['hdfs_dn']
          services['HDFS DN - Available'].use ?= 'bp-service'
          services['HDFS DN - Available'].check_command ?= bp_miss 3, 'HDFS DN - TCP SSL', '$HOSTNAME$'
          services['HDFS DN - Nodes w/ Free space'] ?= {}
          services['HDFS DN - Nodes w/ Free space'].hosts ?= []
          services['HDFS DN - Nodes w/ Free space'].hosts.push clustername
          services['HDFS DN - Nodes w/ Free space'].servicegroups ?= ['hdfs_dn']
          services['HDFS DN - Nodes w/ Free space'].use ?= 'bp-service'
          services['HDFS DN - Nodes w/ Free space'].check_command ?= bp_has_one 'HDFS DN - Free space', '$HOSTNAME$'
        if 'httpfs' in w.modules
          services['HttpFS - Available'] ?= {}
          services['HttpFS - Available'].hosts ?= []
          services['HttpFS - Available'].hosts.push clustername
          services['HttpFS - Available'].servicegroups ?= ['httpfs']
          services['HttpFS - Available'].use ?= 'bp-service'
          services['HttpFS - Available'].check_command ?= bp_has_one 'HttpFS - WebService', '$HOSTNAME$'
        if 'yarn_rm' in w.modules
          services['YARN RM - Available'] ?= {}
          services['YARN RM - Available'].hosts ?= []
          services['YARN RM - Available'].hosts.push clustername
          services['YARN RM - Available'].servicegroups ?= ['yarn_rm']
          services['YARN RM - Available'].use ?= 'bp-service'
          services['YARN RM - Available'].check_command ?= bp_has_one 'YARN RM - Admin TCP', '$HOSTNAME$'
          create_dependency 'YARN RM - Available', 'Zookeeper Server - Available', name
          services['YARN RM - Active Node'] ?= {}
          services['YARN RM - Active Node'].hosts ?= []
          services['YARN RM - Active Node'].hosts.push clustername
          services['YARN RM - Active Node'].servicegroups ?= ['hdfs_nn']
          services['YARN RM - Active Node'].use ?= 'unit-service'
          services['YARN RM - Active Node'].check_command ?= 'check_active_rm!8090!-S'
          create_dependency 'YARN RM - Active Node', 'YARN RM - Available', name
          services['YARN RM - TCP SSL'] ?= {}
          services['YARN RM - TCP SSL'].hosts ?= []
          services['YARN RM - TCP SSL'].hosts.push clustername
          services['YARN RM - TCP SSL'].servicegroups ?= ['yarn_rm']
          services['YARN RM - TCP SSL'].use ?= 'unit-service'
          services['YARN RM - TCP SSL'].check_command ?= "check_tcp_ha!'YARN RM - Active Node'!8050"
          create_dependency 'YARN RM - TCP SSL', 'YARN RM - Active Node', name
          services['YARN RM - Scheduler TCP'] ?= {}
          services['YARN RM - Scheduler TCP'].hosts ?= []
          services['YARN RM - Scheduler TCP'].hosts.push clustername
          services['YARN RM - Scheduler TCP'].servicegroups ?= ['yarn_rm']
          services['YARN RM - Scheduler TCP'].use ?= 'unit-service'
          services['YARN RM - Scheduler TCP'].check_command ?= "check_tcp_ha!'YARN RM - Active Node'!8030"
          create_dependency 'YARN RM - Scheduler TCP', 'YARN RM - Active Node', name
          services['YARN RM - Tracker TCP'] ?= {}
          services['YARN RM - Tracker TCP'].hosts ?= []
          services['YARN RM - Tracker TCP'].hosts.push clustername
          services['YARN RM - Tracker TCP'].servicegroups ?= ['yarn_rm']
          services['YARN RM - Tracker TCP'].use ?= 'unit-service'
          services['YARN RM - Tracker TCP'].check_command ?= "check_tcp_ha!'YARN RM - Active Node'!8025"
          create_dependency 'YARN RM - Tracker TCP', 'YARN RM - Active Node', name
          services['YARN RM - RPC latency'] ?= {}
          services['YARN RM - RPC latency'].hosts ?= []
          services['YARN RM - RPC latency'].hosts.push clustername
          services['YARN RM - RPC latency'].servicegroups ?= ['yarn_rm']
          services['YARN RM - RPC latency'].use ?= 'unit-service'
          services['YARN RM - RPC latency'].check_command ?= "check_rpc_latency_ha!'YARN RM - Active Node'!ResourceManager!8090!3000!5000!-S"
          create_dependency 'YARN RM - RPC latency', 'YARN RM - Active Node', name
        if 'yarn_nm' in w.modules
          services['YARN NM - Available'] ?= {}
          services['YARN NM - Available'].hosts ?= []
          services['YARN NM - Available'].hosts.push clustername
          services['YARN NM - Available'].servicegroups ?= ['yarn_nm']
          services['YARN NM - Available'].use ?= 'bp-service'
          services['YARN NM - Available'].check_command ?= bp_miss 3, 'YARN NM - TCP', '$HOSTNAME$'
        if 'hbase_master' in w.modules
          services['HBase Master - Available'] ?= {}
          services['HBase Master - Available'].hosts ?= []
          services['HBase Master - Available'].hosts.push clustername
          services['HBase Master - Available'].servicegroups ?= ['hbase_master']
          services['HBase Master - Available'].use ?= 'bp-service'
          services['HBase Master - Available'].check_command ?= bp_has_one 'HBase Master - TCP', '$HOSTNAME$'
          create_dependency 'HBase Master - Available', 'Zookeeper Server - Available', name
          create_dependency 'HBase Master - Available', 'HDFS - Available', name
          services['HBase - Replication logs'] ?= {}
          services['HBase - Replication logs'].hosts ?= []
          services['HBase - Replication logs'].hosts.push clustername
          services['HBase - Replication logs'].servicegroups ?= ['hbase']
          services['HBase - Replication logs'].use ?= 'functional-service'
          services['HBase - Replication logs'].check_command ?= "check_hdfs_content_summary!50470!/apps/hbase/data/oldWALs!spaceConsumed!824633720832!1099511627776!-S" # 768GiB | 1TiB
        if 'hbase_regionserver' in w.modules
          services['HBase RegionServer - Available'] ?= {}
          services['HBase RegionServer - Available'].hosts ?= []
          services['HBase RegionServer - Available'].hosts.push clustername
          services['HBase RegionServer - Available'].servicegroups ?= ['hbase_regionserver']
          services['HBase RegionServer - Available'].use ?= 'bp-service'
          services['HBase RegionServer - Available'].check_command ?= bp_miss '20%', 'HBase RegionServer - TCP', '$HOSTNAME$'
          create_dependency 'HBase RegionServer - Available', 'Zookeeper Server - Available', name
        if 'hbase_rest' in w.modules
          services['HBase REST - Available'] ?= {}
          services['HBase REST - Available'].hosts ?= []
          services['HBase REST - Available'].hosts.push clustername
          services['HBase REST - Available'].servicegroups ?= ['hbase_rest']
          services['HBase REST - Available'].use ?= 'bp-service'
          services['HBase REST - Available'].check_command ?= bp_has_one 'HBase REST - WebService', '$HOSTNAME$'
        if 'hbase_thrift' in w.modules
          services['HBase Thrift - Available'] ?= {}
          services['HBase Thrift - Available'].hosts ?= []
          services['HBase Thrift - Available'].hosts.push clustername
          services['HBase Thrift - Available'].servicegroups ?= ['hbase_thrift']
          services['HBase Thrift - Available'].use ?= 'bp-service'
          services['HBase Thrift - Available'].check_command ?= bp_has_one 'HBase Thrift - TCP SSL', '$HOSTNAME$'
        if 'hcatalog' in w.modules
          services['HCatalog - Available'] ?= {}
          services['HCatalog - Available'].hosts ?= []
          services['HCatalog - Available'].hosts.push clustername
          services['HCatalog - Available'].servicegroups ?= ['hcatalog']
          services['HCatalog - Available'].use ?= 'bp-service'
          services['HCatalog - Available'].check_command ?= bp_has_one 'HCatalog - TCP', '$HOSTNAME$'
          create_dependency 'Kafka Broker - Available', 'MySQL - Available', name
        if 'hiveserver2' in w.modules
          services['Hiveserver2 - Available'] ?= {}
          services['Hiveserver2 - Available'].hosts ?= []
          services['Hiveserver2 - Available'].hosts.push clustername
          services['Hiveserver2 - Available'].servicegroups ?= ['hiveserver2']
          services['Hiveserver2 - Available'].use ?= 'bp-service'
          services['Hiveserver2 - Available'].check_command ?= bp_has_one 'Hiveserver2 - TCP SSL', '$HOSTNAME$'
        if 'oozie_server' in w.modules
          services['Oozie Server - Available'] ?= {}
          services['Oozie Server - Available'].hosts ?= []
          services['Oozie Server - Available'].hosts.push clustername
          services['Oozie Server - Available'].servicegroups ?= ['oozie_server']
          services['Oozie Server - Available'].use ?= 'bp-service'
          services['Oozie Server - Available'].check_command ?= bp_has_one 'Oozie Server - WebUI', '$HOSTNAME$'
        if 'kafka_broker' in w.modules
          services['Kafka Broker - Available'] ?= {}
          services['Kafka Broker - Available'].hosts ?= []
          services['Kafka Broker - Available'].hosts.push clustername
          services['Kafka Broker - Available'].servicegroups ?= ['kafka_broker']
          services['Kafka Broker - Available'].use ?= 'bp-service'
          services['Kafka Broker - Available'].check_command ?= bp_miss 3, 'Kafka Broker - TCPs', '$HOSTNAME$'
          create_dependency 'Kafka Broker - Available', 'Zookeeper Server - Available', name
        if 'opentsdb' in w.modules
          services['OpenTSDB - Available'] ?= {}
          services['OpenTSDB - Available'].hosts ?= []
          services['OpenTSDB - Available'].hosts.push clustername
          services['OpenTSDB - Available'].servicegroups ?= ['opentsdb']
          services['OpenTSDB - Available'].use ?= 'bp-service'
          services['OpenTSDB - Available'].check_command ?= bp_has_one 'OpenTSDB - WebService', '$HOSTNAME$'
          create_dependency 'OpenTSDB - Available', 'HBase - Available', name
        if 'elasticsearch' in w.modules
          services['ElasticSearch - Available'] ?= {}
          services['ElasticSearch - Available'].hosts ?= []
          services['ElasticSearch - Available'].hosts.push clustername
          services['ElasticSearch - Available'].servicegroups ?= ['elasticsearch']
          services['ElasticSearch - Available'].use ?= 'bp-service'
          services['ElasticSearch - Available'].check_command ?= bp_has_quorum 'ElasticSearch - TCP', '$HOSTNAME$'
        if 'knox' in w.modules
          services['Knox - Available'] ?= {}
          services['Knox - Available'].hosts ?= []
          services['Knox - Available'].hosts.push clustername
          services['Knox - Available'].servicegroups ?= ['knox']
          services['Knox - Available'].use ?= 'bp-service'
          services['Knox - Available'].check_command ?= bp_has_quorum 'Knox - WebService', '$HOSTNAME$'
        if 'hue' in w.modules
          services['Hue - Available'] ?= {}
          services['Hue - Available'].hosts ?= []
          services['Hue - Available'].hosts.push clustername
          services['Hue - Available'].servicegroups ?= ['hue']
          services['Hue - Available'].use ?= 'bp-service'
          services['Hue - Available'].check_command ?= bp_has_quorum 'Hue - WebUI', '$HOSTNAME$'
        if 'nifi' in w.modules
          services['NiFi - Available'] ?= {}
          services['NiFi - Available'].hosts ?= []
          services['NiFi - Available'].hosts.push clustername
          services['NiFi - Available'].servicegroups ?= ['nifi']
          services['NiFi - Available'].use ?= 'bp-service'
          services['NiFi - Available'].check_command ?= bp_has_quorum 'NiFi - WebUI', '$HOSTNAME$'
        services['Hadoop - CORE'] ?= {}
        services['Hadoop - CORE'].hosts ?= []
        services['Hadoop - CORE'].hosts.push clustername
        services['Hadoop - CORE'].servicegroups ?= ['hadoop']
        services['Hadoop - CORE'].use ?= 'bp-service'
        services['Hadoop - CORE'].check_command ?= "bp_rule!(100%,1,1 of: $HOSTNAME$,YARN - Available & $HOSTNAME$,HDFS - Available & $HOSTNAME$,Zookeeper Server - Available)"
        services['HDFS - Available'] ?= {}
        services['HDFS - Available'].hosts ?= []
        services['HDFS - Available'].hosts.push clustername
        services['HDFS - Available'].servicegroups ?= ['hdfs']
        services['HDFS - Available'].use ?= 'bp-service'
        services['HDFS - Available'].check_command ?= "bp_rule!($HOSTNAME$,HDFS NN - Available & $HOSTNAME$,HDFS DN - Available & $HOSTNAME$,HDFS JN - Available)"
        services['YARN - Available'] ?= {}
        services['YARN - Available'].hosts ?= []
        services['YARN - Available'].hosts.push clustername
        services['YARN - Available'].servicegroups ?= ['yarn']
        services['YARN - Available'].use ?= 'bp-service'
        services['YARN - Available'].check_command ?= "bp_rule!($HOSTNAME$,YARN RM - Available & $HOSTNAME$,YARN NM - Available)"
        services['HBase - Available'] ?= {}
        services['HBase - Available'].hosts ?= []
        services['HBase - Available'].hosts.push clustername
        services['HBase - Available'].servicegroups ?= ['yarn']
        services['HBase - Available'].use ?= 'bp-service'
        services['HBase - Available'].check_command ?= "bp_rule!($HOSTNAME$,HBase Master - Available & $HOSTNAME$,HBase RegionServer - Available)"
        services['Cluster Availability'] ?= {}
        services['Cluster Availability'].hosts ?= []
        services['Cluster Availability'].hosts.push clustername
        services['Cluster Availability'].use ?= 'bp-service'
        services['Cluster Availability'].check_command ?= bp_has_all '.*Available', '$HOSTNAME$'

      if shinken.contexts_dirs?
        shinken.contexts_dirs = [shinken.contexts_dirs] unless Array.isArray shinken.contexts_dirs
        for ctx_dir in shinken.contexts_dirs
          from_contexts.call @, glob.sync("#{ctx_dir}/*").map((f) -> require f) 
      else
        from_contexts.call @, @contexts '**'

## Normalize

      # HostGroups
      for name, group of hostgroups
        group.alias ?= name
        group.members ?= []
        group.members = [group.members] unless Array.isArray group.members
        group.hostgroup_members ?= []
        group.hostgroup_members = [group.hostgroup_members] unless Array.isArray group.hostgroup_members
      # Disable host membership !
      hostgroups.by_roles.members = []
      # Hosts
      for name, host of hosts
        host.alias ?= name
        host.use ?= 'generic-host'
        host.hostgroups ?= []
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
        service.servicegroups = [service.servicegroups] if service.servicegroups? and not Array.isArray service.servicegroups
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

## Dependencies

    fs = require 'fs'
    glob = require 'glob'
    {merge} = require 'nikita/lib/misc'
    path = require 'path'
