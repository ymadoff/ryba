---
title: 
layout: module
---

# MapRed JobHistoryServer

    lifecycle = require './lib/lifecycle'
    mkcmd = require './lib/mkcmd'
    module.exports = []
    module.exports.push 'phyla/bootstrap'
    module.exports.push 'phyla/hadoop/mapred'

    module.exports.push (ctx) ->
      require('./mapred').configure ctx

    module.exports.push name: 'HDP MapRed JHS # Kerberos', callback: (ctx, next) ->
      {hadoop_conf_dir, static_host, realm} = ctx.config.hdp
      mapred = {}
      mapred['mapreduce.jobhistory.keytab'] ?= "/etc/security/keytabs/jhs.service.keytab"
      mapred['mapreduce.jobhistory.principal'] ?= "jhs/#{static_host}@#{realm}"
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/mapred-site.xml"
        properties: mapred
        merge: true
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

Layout is inspired by [Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)

    module.exports.push name: 'HDP MapRed JHS # HDFS layout', callback: (ctx, next) ->
      {hadoop_group, yarn_user, mapred_user} = ctx.config.hdp
      # Carefull, this is a duplicate of "HDP MapRed # HDFS layout"
      ok = false
      do_jobhistory_server = ->
        ctx.execute
          cmd: mkcmd.hdfs ctx, """
          if hdfs dfs -test -d /mr-history; then exit 1; fi
          hdfs dfs -mkdir -p /mr-history/tmp
          hdfs dfs -chmod -R 1777 /mr-history/tmp
          hdfs dfs -mkdir -p /mr-history/done
          hdfs dfs -chmod -R 1777 /mr-history/done
          hdfs dfs -chown -R #{mapred_user}:#{hadoop_group} /mr-history
          hdfs dfs -mkdir -p /app-logs
          hdfs dfs -chmod -R 1777 /app-logs 
          hdfs dfs -chown #{yarn_user} /app-logs 
          """
          code_skipped: 1
        , (err, executed, stdout) ->
          return next err if err
          ok = true if executed
          do_end()
      do_end = ->
        next null, if ok then ctx.OK else ctx.PASS
      do_jobhistory_server()

    module.exports.push name: 'HDP MapRed JHS # Kerberos', callback: (ctx, next) ->
      {mapred_user, realm} = ctx.config.hdp
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc 
        principal: "jhs/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/jhs.service.keytab"
        uid: mapred_user
        gid: 'hadoop'
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , (err, created) ->
        return next err if err
        next null, if created then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP MapRed JHS # Start', callback: (ctx, next) ->
      lifecycle.jhs_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS



