
# Oozie Server Install

Oozie source code and examples are located in "/usr/share/doc/oozie-$version".

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/mysql_client'
    module.exports.push 'ryba/hadoop/core'
    module.exports.push 'ryba/hadoop/hdfs' # SPNEGO need access to the principal HTTP/$HOST@$REALM's keytab
    module.exports.push 'ryba/hadoop/hdfs_dn_wait' # Create directories inside HDFS
    module.exports.push require('./server').configure

## Users & Groups

By default, the "oozie" package create the following entries:

```bash
cat /etc/passwd | grep oozie
oozie:x:493:493:Oozie User:/var/lib/oozie:/bin/bash
cat /etc/group | grep oozie
oozie:x:493:
```

    module.exports.push name: 'Oozie Server # Users & Groups', callback: (ctx, next) ->
      {oozie} = ctx.config.ryba
      ctx.group oozie.group, (err, gmodified) ->
        return next err if err
        ctx.user oozie.user, (err, umodified) ->
          next err, gmodified or umodified

## IPTables

| Service | Port  | Proto | Info              |
|---------|-------|-------|-------------------|
| oozie   | 11000 | http  | Oozie HTTP server |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'Oozie Server # IPTables', callback: (ctx, next) ->
      {oozie} = ctx.config.ryba
      port = url.parse(oozie.site['oozie.base.url']).port
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'tcp', state: 'NEW', comment: "Oozie HTTP Server" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

    module.exports.push name: 'Oozie Server # Install', timeout: -1, callback: (ctx, next) ->
      # Upgrading oozie failed, tested versions are hdp 2.1.2 -> 2.1.5 -> 2.1.7
      ctx.execute
        cmd: "rm -rf /usr/lib/oozie && yum remove -y oozie oozie-client"
        if: ctx.retry > 0
      , (err) ->
        return next err if err
        ctx.service [
          name: 'oozie' # Also install oozie-client and bigtop-tomcat
        ,
          name: 'unzip' # Required by the "prepare-war" command
        ,
          name: 'zip' # Required by the "prepare-war" command
        ,
          name: 'extjs-2.2-1'
        ], (err, serviced) ->
          ctx.config.ryba.force_war = true if serviced
          next err, serviced

    module.exports.push name: 'Oozie Server # Directories', callback: (ctx, next) ->
      {oozie} = ctx.config.ryba
      ctx.mkdir [
        destination: oozie.data
        uid: oozie.user.name
        gid: oozie.group.name
        mode: 0o0755
      ,
        destination: oozie.log_dir
        uid: oozie.user.name
        gid: oozie.group.name
        mode: 0o0755
      ,
        destination: oozie.pid_dir
        uid: oozie.user.name
        gid: oozie.group.name
        mode: 0o0755
      ,
        destination: oozie.tmp_dir
        uid: oozie.user.name
        gid: oozie.group.name
        mode: 0o0755
      ,
        destination: "#{oozie.conf_dir}/action-conf"
        uid: oozie.user.name
        gid: oozie.group.name
        mode: 0o0755
      ], (err, copied) ->
        return next err if err
        # Waiting for recursivity in ctx.mkdir
        ctx.execute
          cmd: """
          chown -R #{oozie.user.name}:#{oozie.group.name} /usr/lib/oozie
          chown -R #{oozie.user.name}:#{oozie.group.name} #{oozie.data}
          chown -R #{oozie.user.name}:#{oozie.group.name} #{oozie.conf_dir}/..
          chmod -R 755 #{oozie.conf_dir}/..
          """
        , (err, executed) ->
          next err, copied

    module.exports.push name: 'Oozie Server # Environment', callback: (ctx, next) ->
      {java_home} = ctx.config.java
      {oozie} = ctx.config.ryba
      ctx.write
        source: "#{__dirname}/../resources/oozie/oozie-env.sh"
        destination: "#{oozie.conf_dir}/oozie-env.sh"
        local_source: true
        write: [
          match: /^export JAVA_HOME=.*$/mg
          replace: "export JAVA_HOME=#{java_home}"
          append: true
        ,
          match: /^export JRE_HOME=.*$/mg
          replace: "export JRE_HOME=${JAVA_HOME}" # Not in HDP 2.0.6 but mentioned in [HDP 2.1 doc](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.1-latest/bk_installing_manually_book/content/rpm-chap8-3.html)
          append: true
        ,
          match: /^export OOZIE_CONFIG=.*$/mg
          replace: "export OOZIE_CONFIG=${OOZIE_CONFIG:-/etc/oozie/conf}"
          append: true
        ,
          match: /^export CATALINA_BASE=.*$/mg
          replace: "export CATALINA_BASE=${CATALINA_BASE:-/var/lib/oozie/tomcat-deployment}"
          append: true
        ,
          match: /^export CATALINA_TMPDIR=.*$/mg
          replace: "export CATALINA_TMPDIR=${CATALINA_TMPDIR:-/var/tmp/oozie}"
          append: true
        ,
          match: /^export OOZIE_CATALINA_HOME=.*$/mg
          replace: "export OOZIE_CATALINA_HOME=/usr/lib/bigtop-tomcat"
          append: true
        ,
          match: /^export OOZIE_DATA=.*$/mg
          replace: "export OOZIE_DATA=#{oozie.data}"
          append: true
        ]
        uid: oozie.user.name
        gid: oozie.group.name
        mode: 0o0755
      , next

    module.exports.push name: 'Oozie Server # ExtJS', callback: (ctx, next) ->
      ctx.copy
        source: '/usr/share/HDP-oozie/ext-2.2.zip'
        destination: '/usr/lib/oozie/libext/'
      , (err, copied) ->
        ctx.config.ryba.force_war = true if copied
        return next err, copied

    module.exports.push name: 'Oozie Server # LZO', callback: (ctx, next) ->
      ctx.execute
        cmd: 'ls /usr/lib/hadoop/lib/hadoop-lzo-*.jar'
      , (err, _, stdout) ->
        return next err if err
        lzo_jar = stdout.trim()
        ctx.execute
          cmd: """
          # Remove any previously installed version
          rm /usr/lib/oozie/libext/hadoop-lzo-*.jar
          # Copy lzo
          cp #{lzo_jar} /usr/lib/oozie/libext/
          """
          not_if_exists: "/usr/lib/oozie/libext/#{path.basename lzo_jar}"
        , next

    module.exports.push name: 'Oozie Server # Mysql Driver', callback: (ctx, next) ->
      ctx.link
        source: '/usr/share/java/mysql-connector-java.jar'
        destination: '/usr/lib/oozie/libext/mysql-connector-java.jar'
      , (err, linked) ->
        ctx.config.ryba.force_war = true if linked
        return next err, linked

    module.exports.push name: 'Oozie Server # Configuration', callback: (ctx, next) ->
      { hadoop_conf_dir, yarn, oozie } = ctx.config.ryba
      modified = false
      do_oozie_site = ->
        ctx.log 'Configure oozie-site.xml'
        ctx.hconfigure
          destination: "#{oozie.conf_dir}/oozie-site.xml"
          default: "#{__dirname}/../resources/oozie/oozie-site.xml"
          local_default: true
          properties: oozie.site
          uid: oozie.user.name
          gid: oozie.group.name
          mode: 0o0755
          merge: true
          backup: true
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_hadoop_config()
      do_hadoop_config = ->
        ctx.log 'Configure hadoop-config.xml'
        ctx.hconfigure
          destination: "#{oozie.conf_dir}/hadoop-conf/core-site.xml"
          local_default: true
          properties: oozie.hadoop_config
          uid: oozie.user.name
          gid: oozie.group.name
          mode: 0o0755
          backup: true
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_end()
      do_end = ->
        next null, modified
      do_oozie_site()

    module.exports.push name: 'Oozie Server # War', callback: (ctx, next) ->
      {oozie} = ctx.config.ryba
      falcon_cts = ctx.contexts 'ryba/falcon', require('../falcon').configure
      do_falcon = ->
        return do_prepare_war() unless falcon_cts.length
        ctx.service
          name: 'falcon'
        , (err, serviced) ->
          return next err if err
          # return do_prepare_war() unless serviced
          ctx.mkdir
            destination: '/tmp/falcon-oozie-jars'
          , (err, created) ->
            return next err if err
            # Note, the documentation mentions using "-d" option but it doesnt
            # seem to work. Instead, we deploy the jar where "-d" default.
            ctx.execute
              # cmd: """
              # rm -rf /tmp/falcon-oozie-jars/*
              # cp  /usr/lib/falcon/oozie/ext/falcon-oozie-el-extension-*.jar \
              #   /tmp/falcon-oozie-jars
              # """, (err) ->
              cmd: """
              rm -rf /tmp/falcon-oozie-jars/*
              cp  /usr/lib/falcon/oozie/ext/falcon-oozie-el-extension-*.jar \
                /usr/lib/oozie/libext
              """, (err) ->
                return next err if err
                ctx.service
                  srv_name: 'oozie'
                  action: 'stop'
                , (err) ->
                  return next err if err
                  do_prepare_war()
      do_prepare_war = ->
        # The script `ooziedb.sh` must be done as the oozie Unix user, otherwise 
        # Oozie may fail to start or work properly because of incorrect file permissions.
        # There is already a "oozie.war" file inside /var/lib/oozie/oozie-server/webapps/.
        # The "prepare-war" command generate the file "/var/lib/oozie/oozie-server/webapps/oozie.war".
        # The directory being served by the web server is "prepare-war".
        # See note 20 lines above about "-d" option
        # falcon_opts = if falcon_cts.length then " –d /tmp/falcon-oozie-jars" else ''
        falcon_opts = ''
        ctx.execute
          cmd: "su -l #{oozie.user.name} -c '/usr/lib/oozie/bin/oozie-setup.sh prepare-war #{falcon_opts}'"
          # not_if: not ctx.config.ryba.force_war
          code_skipped: 255 # Oozie already started, war is expected to be installed
        , next
      do_falcon()

    module.exports.push name: 'Oozie Server # Kerberos', callback: (ctx, next) ->
      {oozie, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: oozie.site['oozie.service.HadoopAccessorService.kerberos.principal'] #.replace '_HOST', ctx.config.host
        randkey: true
        keytab: oozie.site['oozie.service.HadoopAccessorService.keytab.file']
        uid: oozie.user.name
        gid: oozie.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

    module.exports.push name: 'Oozie Server # SPNEGO', callback: (ctx, next) ->
      {oozie} = ctx.config.ryba
      ctx.copy
        source: '/etc/security/keytabs/spnego.service.keytab'
        destination: "#{oozie.site['oozie.authentication.kerberos.keytab']}"
        uid: oozie.user.name
        gid: oozie.group.name
        mode: 0o0600
      , next

    module.exports.push name: 'Oozie Server # MySQL', callback: (ctx, next) ->
      {db_admin, oozie} = ctx.config.ryba
      username = oozie.site['oozie.service.JPAService.jdbc.username']
      password = oozie.site['oozie.service.JPAService.jdbc.password']
      {engine, db} = parse_jdbc oozie.site['oozie.service.JPAService.jdbc.url']
      engines = 
        mysql: ->
          escape = (text) -> text.replace(/[\\"]/g, "\\$&")
          cmd = "#{db_admin.path} -u#{db_admin.username} -p#{db_admin.password} -h#{db_admin.host} -P#{db_admin.port} -e "
          ctx.execute
            cmd: """
            if #{cmd} "use #{db}"; then exit 2; fi
            #{cmd} "
            create database #{db};
            grant all privileges on #{db}.* to '#{username}'@'localhost' identified by '#{password}';
            grant all privileges on #{db}.* to '#{username}'@'%' identified by '#{password}';
            flush privileges;
            "
            """
            code_skipped: 2
          , next
      return next new Error 'Database engine not supported' unless engines[engine]
      engines[engine]()

    module.exports.push name: 'Oozie Server # Database', callback: (ctx, next) ->
      {oozie} = ctx.config.ryba
      ctx.execute
        cmd: """
        su -l #{oozie.user.name} -c '/usr/lib/oozie/bin/ooziedb.sh create -sqlfile oozie.sql -run Validate DB Connection'
        """
      , (err, executed, stdout, stderr) ->
        err = null if err and /DB schema exists/.test stderr
        next err, executed

    module.exports.push name: 'Oozie Server # Share lib', timeout: 600000, callback: (ctx, next) ->
      {oozie} = ctx.config.ryba
      version_local = 'ls /usr/lib/oozie/lib | grep oozie-client | sed \'s/^oozie-client-\\(.*\\)\\.jar$/\\1/g\''
      version_remote = 'hdfs dfs -cat /user/oozie/share/lib/sharelib.properties | grep build.version | sed \'s/^build.version=\\(.*\\)$/\\1/g\''
      ctx.execute 
        cmd: mkcmd.hdfs ctx, """
        mkdir /tmp/ooziesharelib
        cd /tmp/ooziesharelib
        tar xzf /usr/lib/oozie/oozie-sharelib.tar.gz
        hdfs dfs -rm -r /user/#{oozie.user.name}/share || true
        hdfs dfs -mkdir /user/#{oozie.user.name}
        hdfs dfs -put share /user/#{oozie.user.name}
        hdfs dfs -chown #{oozie.user.name}:#{oozie.group.name} /user/#{oozie.user.name}
        hdfs dfs -chmod -R 755 /user/#{oozie.user.name}
        rm -rf /tmp/ooziesharelib
        """
        trap_on_error: true
        not_if_exec: mkcmd.hdfs ctx, "[[ `#{version_local}` == `#{version_remote}` ]]"
      , next

    module.exports.push 'ryba/oozie/server_start'

    module.exports.push 'ryba/oozie/client'

## Module Dependencies

    url = require 'url'
    path = require 'path'
    lifecycle = require '../lib/lifecycle'
    mkcmd = require '../lib/mkcmd'
    parse_jdbc = require '../lib/parse_jdbc'
  

## Upgrade error

Run `yum remove -y oozie oozie-client` before `ryba install` if you see this
error:

```
Running Transaction
  Updating   : oozie-4.0.0.2.1.5.0-695.el6.noarch                                                                                                                                                   1/2 
Error unpacking rpm package oozie-4.0.0.2.1.5.0-695.el6.noarch
error: unpacking of archive failed on file /usr/lib/oozie/webapps/oozie/WEB-INF: cpio: rename
  Verifying  : oozie-4.0.0.2.1.5.0-695.el6.noarch                                                                                                                                                   1/2 
oozie-4.0.0.2.1.2.0-402.el6.noarch was supposed to be removed but is not!
  Verifying  : oozie-4.0.0.2.1.2.0-402.el6.noarch
```




