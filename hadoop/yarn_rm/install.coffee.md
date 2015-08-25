
# Hadoop YARN ResourceManager Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/yarn_client/install'
    module.exports.push require '../../lib/hconfigure'
    # module.exports.push require '../../lib/hdp_service'
    module.exports.push require '../../lib/hdp_select'
    module.exports.push require '../../lib/write_jaas'
    module.exports.push require('./index').configure
      
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

    module.exports.push name: 'YARN RM # IPTables', handler: (ctx, next) ->
      {yarn} = ctx.config.ryba
      shortname = if ctx.hosts_with_module('ryba/hadoop/yarn_rm').length is 1 then '' else ".#{ctx.config.shortname}"
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
      ctx.iptables
        rules: rules
        if: ctx.config.iptables.action is 'start'
      .then next

## Kerberos

    module.exports.push name: 'YARN RM # Kerberos', handler: (ctx, next) ->
      {yarn, hadoop_group, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: yarn.site['yarn.resourcemanager.principal'].replace '_HOST', ctx.config.host
        randkey: true
        keytab: yarn.site['yarn.resourcemanager.keytab']
        uid: yarn.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      .then next

## Kerberos JAAS

The JAAS file is used by the ResourceManager to initiate a secure connection 
with Zookeeper.

    module.exports.push name: 'YARN RM # Kerberos JAAS', handler: (ctx, next) ->
      {yarn, hadoop_conf_dir, hadoop_group, core_site, realm} = ctx.config.ryba
      ctx.write_jaas
        destination: "#{hadoop_conf_dir}/yarn-rm.jaas"
        content: Client:
          principal: yarn.site['yarn.resourcemanager.principal'].replace '_HOST', ctx.config.host
          keyTab: yarn.site['yarn.resourcemanager.keytab']
        uid: yarn.user.name
        gid: hadoop_group.name
      .then next


## Service

Install the "hadoop-yarn-resourcemanager" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

    module.exports.push name: 'YARN RM # Service', handler: (ctx, next) ->
      {yarn} = ctx.config.ryba
      ctx
      .service
        name: 'hadoop-yarn-resourcemanager'
      .hdp_select
        name: 'hadoop-yarn-client' # Not checked
        name: 'hadoop-yarn-resourcemanager'
      .write
        source: "#{__dirname}/../resources/hadoop-yarn-resourcemanager"
        local_source: true
        destination: '/etc/init.d/hadoop-yarn-resourcemanager'
        mode: 0o0755
        unlink: true
      .execute
        cmd: "service hadoop-yarn-resourcemanager restart"
        if: -> @status -3
      .then next

## Environment

    module.exports.push name: 'YARN RM # Env', handler: (ctx, next) ->
      {java_home} = ctx.config.java
      {yarn, hadoop_group, hadoop_conf_dir} = ctx.config.ryba
      rm_opts = "-Djava.security.auth.login.config=#{hadoop_conf_dir}/yarn-rm.jaas #{yarn.rm_opts}"
      ctx.write
        destination: "#{hadoop_conf_dir}/yarn-env.sh"
        match: /^.*# RYBA CONF "ryba.yarn.rm_opts", DONT OVERWRITE/mg
        replace: "YARN_RESOURCEMANAGER_OPTS=\"${YARN_RESOURCEMANAGER_OPTS} #{rm_opts}\" # RYBA CONF \"ryba.yarn.rm_opts\", DONT OVERWRITE"
        append: true
        backup: true
      .then next

## Configuration

    module.exports.push name: 'YARN RM # Configuration', handler: (ctx, next) ->
      {hadoop_conf_dir, yarn, mapred} = ctx.config.ryba
      ctx
      .hconfigure
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/yarn-site.xml"
        local_default: true
        properties: yarn.site
        merge: true
        backup: true
      .hconfigure # Ideally placed inside a mapred_jhs_client module
        destination: "#{hadoop_conf_dir}/mapred-site.xml"
        properties: mapred.site
        merge: true
        backup: true
      .touch
        destination: "#{hadoop_conf_dir}/yarn.exclude"
      .then next

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

    module.exports.push name: 'YARN RM # Capacity Scheduler', handler: (ctx, next) ->
      {yarn, hadoop_conf_dir, capacity_scheduler} = ctx.config.ryba
      return next() unless yarn.site['yarn.resourcemanager.scheduler.class'] is 'org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler'
      ctx
      .hconfigure
        destination: "#{hadoop_conf_dir}/capacity-scheduler.xml"
        default: "#{__dirname}/../../resources/core_hadoop/capacity-scheduler.xml"
        local_default: true
        properties: capacity_scheduler
        merge: false
        backup: true
      .execute
        cmd: mkcmd.hdfs ctx, 'service hadoop-yarn-resourcemanager status && yarn rmadmin -refreshQueues || exit'
        if: -> @status -1
      .then next

## Dependencies

    mkcmd = require '../../lib/mkcmd'

## Todo: WebAppProxy.

It semms like it is run as part of rm by default and could also be started
separately on an edge node.

*   yarn.web-proxy.address    WebAppProxy                                   host:port for proxy to AM web apps. host:port if this is the same as yarn.resourcemanager.webapp.address or it is not defined then the ResourceManager will run the proxy otherwise a standalone proxy server will need to be launched.
*   yarn.web-proxy.keytab     /etc/security/keytabs/web-app.service.keytab  Kerberos keytab file for the WebAppProxy.
*   yarn.web-proxy.principal  wap/_HOST@REALM.TLD                           Kerberos principal name for the WebAppProxy.


[capacity]: http://hadoop.apache.org/docs/r2.5.0/hadoop-yarn/hadoop-yarn-site/CapacityScheduler.html
