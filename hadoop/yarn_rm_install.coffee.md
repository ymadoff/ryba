---
title: 
layout: module
---

# YARN ResourceManager Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hadoop/yarn'

    module.exports.push require('./yarn_rm').configure

## IPTables

| Service    | Port | Proto  | Parameter                  |
|------------|------|--------|----------------------------|
| resourcemanager | 8025  | tcp    | yarn.resourcemanager.resource-tracker.address | x
| resourcemanager | 8050  | tcp    | yarn.resourcemanager.address                  | x
| scheduler       | 8030  | tcp    | yarn.resourcemanager.scheduler.address        | x
| resourcemanager | 8088  | http   | yarn.resourcemanager.webapp.address           | x
| resourcemanager | 8090  | https  | yarn.resourcemanager.webapp.https.address     | 
| resourcemanager | 8141  | tcp    | yarn.resourcemanager.admin.address            | x

| Service    | Port | Proto  | Parameter                  |
|------------|------|--------|----------------------------|
| timeline | 10200 | tcp    | yarn.timeline-service.address                 | 
| timeline | 8188  | tcp    | yarn.timeline-service.webapp.address          | x
| timeline | 8190  | tcp    | yarn.timeline-service.webapp.https.address    | x

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'Hadoop YARN RM # IPTables', callback: (ctx, next) ->
      {yarn_site} = ctx.config.ryba
      http = yarn_site['yarn.resourcemanager.webapp.address'].split(':')[1]
      https = yarn_site['yarn.resourcemanager.webapp.https.address'].split(':')[1]
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8025, protocol: 'tcp', state: 'NEW', comment: "YARN RM Application Submissions" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8050, protocol: 'tcp', state: 'NEW', comment: "YARN RM Application Submissions" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8030, protocol: 'tcp', state: 'NEW', comment: "YARN Scheduler" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: http, protocol: 'tcp', state: 'NEW', comment: "YARN RM Web UI" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: https, protocol: 'tcp', state: 'NEW', comment: "YARN RM Web Secured UI" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8141, protocol: 'tcp', state: 'NEW', comment: "YARN RM Scheduler" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

    module.exports.push name: 'Hadoop YARN RM # Kerberos', callback: (ctx, next) ->
      {yarn_user, hadoop_group, realm, yarn_site} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc 
        principal: yarn_site['yarn.resourcemanager.principal'].replace '_HOST', ctx.config.host
        randkey: true
        keytab: yarn_site['yarn.resourcemanager.keytab']
        uid: yarn_user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

## Startup

Install and configure the startup script in 
"/etc/init.d/hadoop-yarn-resourcemanager".

    module.exports.push name: 'Hadoop YARN RM # Startup', callback: (ctx, next) ->
      {yarn_pid_dir} = ctx.config.ryba
      modified = false
      do_install = ->
        ctx.service
          name: 'hadoop-yarn-resourcemanager'
          startup: true
        , (err, serviced) ->
          return next err if err
          modified = true if serviced
          do_fix()
      do_fix = ->
        ctx.write
          destination: '/etc/init.d/hadoop-yarn-resourcemanager'
          write: [
            match: /^PIDFILE=".*"$/m
            replace: "PIDFILE=\"#{yarn_pid_dir}/$SVC_USER/yarn-yarn-resourcemanager.pid\""
          ,
            match: /^(\s+start_daemon)\s+(\$EXEC_PATH.*)$/m
            replace: "$1 -u $SVC_USER $2"
          ]
        , (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, modified
      do_install()

## Configuration


    module.exports.push name: 'Hadoop YARN # Configuration', callback: (ctx, next) ->
      {yarn_site, hadoop_conf_dir} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        default: "#{__dirname}/../resources/core_hadoop/yarn-site.xml"
        local_default: true
        properties: yarn_site
        merge: true
      , next

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

    module.exports.push name: 'Hadoop YARN RM # Capacity Scheduler', callback: (ctx, next) ->
      {yarn_site, hadoop_conf_dir, capacity_scheduler} = ctx.config.ryba
      return next() unless yarn_site['yarn.resourcemanager.scheduler.class'] is 'org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler'
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/capacity-scheduler.xml"
        default: "#{__dirname}/../resources/core_hadoop/capacity-scheduler.xml"
        local_default: true
        properties: capacity_scheduler
        merge: true
      , (err, configured) ->
        return next err, false if err or not configured
        ctx.execute
          cmd: mkcmd.hdfs ctx, 'service hadoop-yarn-resourcemanager status && yarn rmadmin -refreshQueues'
          code_skipped: 3
        , (err) ->
          next err, true

## Wait JHS

Yarn use the the MapReduce Job History Server (JHS) to send logs. The address of
the server is defined by the propery "yarn.log.server.url" in "yarn-site.xml".
The default port is "19888".

    # url = require 'url'
    # module.exports.push name: 'Hadoop YARN RM # Wait JHS', timeout: -1, callback: (ctx, next) ->
    #   {hostname, port} = url.parse ctx.config.ryba.yarn_site['yarn.log.server.url']
    #   ctx.waitIsOpen hostname, port, (err) ->
    #     return next err if err

## Start RM

Execute the "ryba/hadoop/yarn_rm_start" module to start the Resource Manager.

    module.exports.push 'ryba/hadoop/yarn_rm_start'

## Module Dependencies

    mkcmd = require '../lib/mkcmd'

## Todo: WebAppProxy.   

It semms like it is run as part of rm by default and could also be started
separately on an edge node.   

*   yarn.web-proxy.address    WebAppProxy                                   host:port for proxy to AM web apps. host:port if this is the same as yarn.resourcemanager.webapp.address or it is not defined then the ResourceManager will run the proxy otherwise a standalone proxy server will need to be launched.
*   yarn.web-proxy.keytab     /etc/security/keytabs/web-app.service.keytab  Kerberos keytab file for the WebAppProxy.
*   yarn.web-proxy.principal  wap/_HOST@REALM.TLD                           Kerberos principal name for the WebAppProxy.


[capacity]: http://hadoop.apache.org/docs/r2.5.0/hadoop-yarn/hadoop-yarn-site/CapacityScheduler.html

