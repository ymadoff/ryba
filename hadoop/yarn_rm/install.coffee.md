
# Hadoop YARN ResourceManager Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/yarn_client/install'
    module.exports.push 'ryba/lib/hconfigure'
    # module.exports.push require '../../lib/hdp_service'
    module.exports.push 'ryba/lib/hdp_select'
    module.exports.push 'ryba/lib/write_jaas'
    # module.exports.push require('./index').configure
      
## IPTables

| Service         | Port  | Proto  | Parameter                                     |
|-----------------|-------|--------|-----------------------------------------------|
| resourcemanager | 8025  | tcp    | yarn.resourcemanager.resource-tracker.address | x
| resourcemanager | 8050  | tcp    | yarn.resourcemanager.address                  | x
| scheduler       | 8030  | tcp    | yarn.resourcemanager.scheduler.address        | x
| resourcemanager | 8088  | http   | yarn.resourcemanager.webapp.address           | x
| resourcemanager | 8090  | https  | yarn.resourcemanager.webapp.https.address     |
| resourcemanager | 8141  | tcp    | yarn.resourcemanager.admin.address            | x

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'YARN RM # IPTables', handler: ->
      {yarn} = @config.ryba
      shortname = if @hosts_with_module('ryba/hadoop/yarn_rm').length is 1 then '' else ".#{@config.shortname}"
      rules = []
      # Application
      rpc_port = yarn.site["yarn.resourcemanager.address#{shortname}"].split(':')[1]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: rpc_port, protocol: 'tcp', state: 'NEW', comment: "YARN RM Application Submissions" }
      # Scheduler
      s_port = yarn.site["yarn.resourcemanager.scheduler.address#{shortname}"].split(':')[1]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: s_port, protocol: 'tcp', state: 'NEW', comment: "YARN Scheduler" }
      # RM Scheduler
      admin_port = yarn.site["yarn.resourcemanager.admin.address#{shortname}"].split(':')[1]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: admin_port, protocol: 'tcp', state: 'NEW', comment: "YARN RM Scheduler" }
      # HTTP
      if yarn.site['yarn.http.policy'] in ['HTTP_ONLY', 'HTTP_AND_HTTPS']
        http_port = yarn.site["yarn.resourcemanager.webapp.address#{shortname}"].split(':')[1]
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: http_port, protocol: 'tcp', state: 'NEW', comment: "YARN RM Web UI" }
      # HTTPS
      if yarn.site['yarn.http.policy'] in ['HTTPS_ONLY', 'HTTP_AND_HTTPS']
        https_port = yarn.site["yarn.resourcemanager.webapp.https.address#{shortname}"].split(':')[1]
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: https_port, protocol: 'tcp', state: 'NEW', comment: "YARN RM Web UI" }
      # Resource Tracker
      rt_port = yarn.site["yarn.resourcemanager.resource-tracker.address#{shortname}"].split(':')[1]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: rt_port, protocol: 'tcp', state: 'NEW', comment: "YARN RM Application Submissions" }
      @iptables
        rules: rules
        if: @config.iptables.action is 'start'

## Kerberos

    module.exports.push name: 'YARN RM # Kerberos', handler: ->
      {yarn, hadoop_group, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: yarn.site['yarn.resourcemanager.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: yarn.site['yarn.resourcemanager.keytab']
        uid: yarn.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

## Kerberos JAAS

The JAAS file is used by the ResourceManager to initiate a secure connection 
with Zookeeper.

    module.exports.push name: 'YARN RM # Kerberos JAAS', handler: ->
      {yarn, hadoop_conf_dir, hadoop_group, core_site, realm} = @config.ryba
      @write_jaas
        destination: "#{hadoop_conf_dir}/yarn-rm.jaas"
        content: Client:
          principal: yarn.site['yarn.resourcemanager.principal'].replace '_HOST', @config.host
          keyTab: yarn.site['yarn.resourcemanager.keytab']
        uid: yarn.user.name
        gid: hadoop_group.name

## Service

Install the "hadoop-yarn-resourcemanager" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

    module.exports.push name: 'YARN RM # Service', handler: ->
      {yarn} = @config.ryba
      @service
        name: 'hadoop-yarn-resourcemanager'
      @hdp_select
        name: 'hadoop-yarn-client' # Not checked
        name: 'hadoop-yarn-resourcemanager'
      @write
        source: "#{__dirname}/../resources/hadoop-yarn-resourcemanager"
        local_source: true
        destination: '/etc/init.d/hadoop-yarn-resourcemanager'
        mode: 0o0755
        unlink: true
      @execute
        cmd: "service hadoop-yarn-resourcemanager restart"
        if: -> @status -3

## Configuration

    module.exports.push name: 'YARN RM # Configuration', handler: ->
      {hadoop_conf_dir, yarn, mapred} = @config.ryba
      @hconfigure
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/yarn-site.xml"
        local_default: true
        properties: yarn.site
        merge: true
        backup: true
      @hconfigure # Ideally placed inside a mapred_jhs_client module
        destination: "#{hadoop_conf_dir}/mapred-site.xml"
        properties: mapred.site
        merge: true
        backup: true
      @touch
        destination: "#{hadoop_conf_dir}/yarn.exclude"

## Capacity Scheduler

the [CapacityScheduler][capacity], a pluggable scheduler for Hadoop which allows for
multiple-tenants to securely share a large cluster such that their applications
are allocated resources in a timely manner under constraints of allocated
capacities

Note about the property "yarn.scheduler.capacity.resource-calculator": The
default i.e. "org.apache.hadoop.yarn.util.resource.DefaultResourseCalculator"
only uses Memory while DominantResourceCalculator uses Dominant-resource to
compare multi-dimensional resources such as Memory, CPU etc. A Java
ResourceCalculator class name is expected.

    module.exports.push name: 'YARN RM # Capacity Scheduler', handler: ->
      {yarn, hadoop_conf_dir, capacity_scheduler} = @config.ryba
      return next() unless yarn.site['yarn.resourcemanager.scheduler.class'] is 'org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler'
      @hconfigure
        destination: "#{hadoop_conf_dir}/capacity-scheduler.xml"
        default: "#{__dirname}/../../resources/core_hadoop/capacity-scheduler.xml"
        local_default: true
        properties: capacity_scheduler
        merge: false
        backup: true
      @execute
        cmd: mkcmd.hdfs @, 'service hadoop-yarn-resourcemanager status && yarn rmadmin -refreshQueues || exit'
        if: -> @status -1

## Dependencies

    mkcmd = require '../../lib/mkcmd'

## Todo: WebAppProxy.

It semms like it is run as part of rm by default and could also be started
separately on an edge node.

*   yarn.web-proxy.address    WebAppProxy                                   host:port for proxy to AM web apps. host:port if this is the same as yarn.resourcemanager.webapp.address or it is not defined then the ResourceManager will run the proxy otherwise a standalone proxy server will need to be launched.
*   yarn.web-proxy.keytab     /etc/security/keytabs/web-app.service.keytab  Kerberos keytab file for the WebAppProxy.
*   yarn.web-proxy.principal  wap/_HOST@REALM.TLD                           Kerberos principal name for the WebAppProxy.


[capacity]: http://hadoop.apache.org/docs/r2.5.0/hadoop-yarn/hadoop-yarn-site/CapacityScheduler.html
