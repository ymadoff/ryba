
# Rexster Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/titan'
    module.exports.push require '../lib/write_jaas'
    
    module.exports.push require('./').configure
    

    module.exports.push name: 'Rexster # Users & Groups', handler: (ctx, next) ->
      {rexster} = ctx.config.ryba
      ctx.group rexster.group, (err, gmodified) ->
        return next err if err
        ctx.user rexster.user, (err, umodified) ->
          next err, gmodified or umodified

    module.exports.push name: 'Rexster # Env', handler: (ctx, next) ->
      {titan, rexster, hadoop_conf_dir} = ctx.config.ryba
      modified=false
      ctx.chown
        destination: rexster.user.home
        uid: rexster.user.name
        gid: rexster.group.name
      , (err, changed) ->
        return next err if err
        modified ||= changed
        write = [
          match: /^(.*)#RYBA CONF hadoop-env, DON'T OVERWRITE/m
          replace: "\tCP=\"$CP:#{hadoop_conf_dir}\" #RYBA CONF hadoop-env, DON'T OVERWRITE"
          append: /^(.*)CP="\$CP:(.*)/m
        ,
          match: /LOG_DIR=.*$/m
          replace: "LOG_DIR=\"#{rexster.log_dir}\" # RYBA CONF \"ryba.rexster.log_dir\", DON'T OVERWRITE"
        ,
          match: /\n(.*)-Dcom.sun.management.jmxremote.port=(.*)\\\n/m
          replace: "\n"
        ,
          match: /^(.*)# RYBA CONF LOG, DON'T OVERWRITE/m
          replace: "JAVA_OPTIONS=\"$JAVA_OPTIONS -Dlog4j.configuration=file:#{path.join rexster.user.home, 'log4j.properties'}\" # RYBA CONF LOG, DON'T OVERWRITE"
          before: /^(.*)com.tinkerpop.rexster.Application.*/m
        ,
          match: /^(.*)-Djava.security.auth.login.config=.*/m
          replace: "JAVA_OPTIONS=\"$JAVA_OPTIONS -Djava.security.auth.login.config=#{path.join rexster.user.home, 'rexster.jaas'}\" # RYBA CONF jaas, DON'T OVERWRITE"
          before: /^(.*)com.tinkerpop.rexster.Application.*/m
        ,
          match: /^(.*)-Djava.library.path.*/m
          replace: "JAVA_OPTIONS=\"$JAVA_OPTIONS -Djava.library.path=${HADOOP_HOME}/lib/native\" # RYBA CONF hadoop native libs, DON'T OVERWRITE"
          before: /^(.*)com.tinkerpop.rexster.Application.*/m
        ]
        if titan.config['storage.backend'] is 'hbase'
          require('../hbase/client').configure ctx
          write.unshift
            match: /^(.*)# RYBA CONF hbase-env, DON'T OVERWRITE/m
            replace: "\tCP=\"$CP:#{ctx.config.ryba.hbase.conf_dir}\" # RYBA CONF hbase-env, DON'T OVERWRITE"
            append: /^(.*)CP="\$CP:(.*)/m
        ctx.write
          destination: path.join titan.home, 'bin', 'rexster.sh'
          write: write
        , (err, written) ->
          return next err if err
          modified ||= written
          logfile = path.join rexster.log_dir, 'rexstitan.log'
          ctx.fs.exists logfile, (err, exists) ->
            return err if err
            if exists then return next err, modified
            else ctx.touch
              destination: logfile
              uid: rexster.user.name
              gid: rexster.group.name
            , (err, created) ->
              modified||=created
              return next err, modified

    module.exports.push name: 'Rexster # Tuning', handler: (ctx, next) ->
      next null, 'TODO'

## Kerberos JAAS for ZooKeeper

    module.exports.push name: 'Rexster # Kerberos', handler: (ctx, next) ->
      {rexster, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: "rexster/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: path.join rexster.user.home, "rexster.service.keytab"
        uid: rexster.user.name
        gid: rexster.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

## Kerberos JAAS for ZooKeeper

Zookeeper use JAAS for authentication. We configure JAAS to make SASL authentication using Kerberos module.

    module.exports.push name: 'Rexster # Kerberos JAAS', handler: (ctx, next) ->
      {rexster, realm} = ctx.config.ryba
      ctx.write_jaas
        destination: path.join rexster.user.home, "rexster.jaas"
        content: 
          Client:
            keyTab: path.join rexster.user.home, "rexster.service.keytab"
            principal: "rexster/#{ctx.config.host}@#{realm}"
          Server:
            keyTab: path.join rexster.user.home, "rexster.service.keytab"
            principal: "rexster/#{ctx.config.host}@#{realm}"
        uid: rexster.user.name
        gid: rexster.group.name
      , next

    module.exports.push name: 'Rexster # Configure Titan Server', handler: (ctx, next) ->
      {titan, rexster} = ctx.config.ryba
      ctx.write
        content: xml 'rexster': rexster.config
        destination: path.join rexster.user.home, 'titan-server.xml'
        uid:rexster.user.name
        gid:rexster.group.name
      , next

## HBase Namespace Permissions

    module.exports.push name: 'Rexster # Grant HBase Perms', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.titan.config['storage.backend'] is 'hbase'
      require('../hbase/master').configure ctx
      {hbase} = ctx.config.ryba
      ctx.execute
        cmd: """
        echo #{hbase.admin.password} | kinit #{hbase.admin.principal} >/dev/null && {
        hbase shell 2>/dev/null <<< "grant 'rexster', 'RWXCA', '@titan'"
        }
        """
        code_skipped: 3
      , next

## Module Dependencies

    path = require 'path'
    xml = require('jstoxml').toXML
