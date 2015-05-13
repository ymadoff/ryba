
# Hue Install

Here's how to uninstall Hue: `rpm -qa | grep hue | xargs sudo rpm -e`. This
article from december 2014 describe how to 
[install the latest version of hue on HDP](http://gethue.com/how-to-deploy-hue-on-hdp/).

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    # Install the mysql connector
    module.exports.push 'masson/commons/mysql_client'
    # Install kerberos clients to create/test new Hive principal
    module.exports.push 'masson/core/krb5_client'
    # Set java_home in "hadoop-env.sh"
    module.exports.push 'ryba/hadoop/hdfs_client'
    module.exports.push 'ryba/hadoop/yarn_client'
    module.exports.push 'ryba/hadoop/mapred_client'
    module.exports.push 'ryba/hive/client' # Hue reference hive conf dir
    module.exports.push 'ryba/tools/pig'
    module.exports.push require '../lib/hconfigure'
    module.exports.push require('./index').configure

## Users & Groups

By default, the "hue" package create the following entries:

```bash
cat /etc/passwd | grep hue
hue:x:494:494:Hue:/var/lib/hue:/sbin/nologin
cat /etc/group | grep hue
hue:x:494:
```

    module.exports.push name: 'Hue # Users & Groups', handler: (ctx, next) ->
      {hue} = ctx.config.ryba
      ctx.group hue.group, (err, gmodified) ->
        return next err if err
        ctx.user hue.user, (err, umodified) ->
          next err, gmodified or umodified

## IPTables

| Service    | Port  | Proto | Parameter          |
|------------|-------|-------|--------------------|
| Hue Web UI | 8888  | http  | desktop.http_port  |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'Hue # IPTables', handler: (ctx, next) ->
      {hue} = ctx.config.ryba
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hue.ini.desktop.http['port'], protocol: 'tcp', state: 'NEW', comment: "Hue Web UI" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Packages

The packages "extjs-2.2-1" and "hue" are installed.

    module.exports.push name: 'Hue # Packages', timeout: -1, handler: (ctx, next) ->
      ctx.service [
        # {name: 'extjs-2.2-1'}
        {name: 'hue'}
        # {name: 'hue-hcatalog'}
        # {name: 'hue-oozie'}
        # {name: 'hue-pig'}
        {name: 'hue-plugins'}
        # {name: 'hue-server'}
        # {name: 'hue-common'}
        # {name: 'hue-shell'}
      ], next

# ## Core

# Update the "core-site.xml" to allow impersonnation through the "hue" and "hcat" 
# users.

# Todo: We are currently only modifying the "core-site.xml" locally while it should 
# be deployed on all the master and worker nodes. This is currently achieved through
# the configuration picked up by the "ryba/hadoop/core" module.

#     module.exports.push name: 'Hue # Core', handler: (ctx, next) ->
#       {hadoop_conf_dir} = ctx.config.ryba
#       properties = 
#         'hadoop.proxyuser.hue.hosts': '*'
#         'hadoop.proxyuser.hue.groups': '*'
#         'hadoop.proxyuser.hcat.groups': '*'
#         'hadoop.proxyuser.hcat.hosts': '*'
#       ctx
#       .hconfigure
#         destination: "#{hadoop_conf_dir}/core-site.xml"
#         properties: properties
#         merge: true
#       .then next

## WebHCat


Update the "webhcat-site.xml" on the server running the "webhcat" service 
to allow impersonnation through the "hue" user.

TODO: only work if WebHCat is running on the same server as Hue

    module.exports.push name: 'Hue # WebHCat', handler: (ctx, next) ->
      {webhcat} = ctx.config.ryba
      webhcat_server = ctx.host_with_module 'ryba/hive/webhcat'
      return next Error "WebHCat shall be on the same server as Hue" unless webhcat_server isnt ctx.config.host
      ctx
      .hconfigure
        destination: "#{webhcat.conf_dir}/webhcat-site.xml"
        properties: 
          'webhcat.proxyuser.hue.hosts': '*'
          'webhcat.proxyuser.hue.groups': '*'
        merge: true
      .then next

## Oozie


Update the "oozie-site.xml" on the server running the "oozie" service 
to allow impersonnation through the "hue" user.

TODO: only work if Oozie is running on the same server as Hue

    module.exports.push name: 'Hue # Oozie', handler: (ctx, next) ->
      {oozie} = ctx.config.ryba
      oozie_server = ctx.host_with_module 'ryba/oozie/server'
      return next Error "Oozie shall be on the same server as Hue" unless oozie_server isnt ctx.config.host
      ctx.hconfigure
        destination: "#{oozie.conf_dir}/oozie-site.xml"
        properties: 
          'oozie.service.ProxyUserService.proxyuser.hue.hosts': '*'
          'oozie.service.ProxyUserService.proxyuser.hue.groups': '*'
        merge: true
      .then next

## Configure

Configure the "/etc/hue/conf" file following the [HortonWorks](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.8.0/bk_installing_manually_book/content/rpm-chap-hue-5-2.html) 
recommandations. Merge the configuration object from "hdp.hue.ini" with the properties of the destination file. 

    module.exports.push name: 'Hue # Configure', handler: (ctx, next) ->
      {hue} = ctx.config.ryba
      ctx.ini
        destination: "#{hue.conf_dir}/hue.ini"
        content: hue.ini
        merge: true
        parse: misc.ini.parse_multi_brackets 
        stringify: misc.ini.stringify_multi_brackets
        separator: '='
        comment: '#'
      , next

## Database

Setup the database hosting the Hue data. Currently two database providers are
implemented but Hue supports MySQL, PostgreSQL, and Oracle. Note, sqlite is 
the default database while mysql is the recommanded choice.

    module.exports.push name: 'Hue # Database', handler: (ctx, next) ->
      {hue, db_admin} = ctx.config.ryba
      engines = 
        mysql: ->
          {host, port, user, password, name} = hue.ini.desktop.database
          escape = (text) -> text.replace(/[\\"]/g, "\\$&")
          mysql_exec = "#{db_admin.path} -u#{db_admin.username} -p#{db_admin.password} -h#{db_admin.host} -P#{db_admin.port} -e "
          ctx.execute [
            cmd: """
            #{mysql_exec} "
            create database #{name};
            grant all privileges on #{name}.* to '#{user}'@'localhost' identified by '#{password}';
            grant all privileges on #{name}.* to '#{user}'@'%' identified by '#{password}';
            flush privileges;
            "
            """
            not_if_exec: "#{mysql_exec} 'use #{name}'"
          ,
            # TODO: handle updates
            cmd: """
            su -l #{hue.user.name} -c "/usr/lib/hue/build/env/bin/hue syncdb --noinput"
            """
            not_if_exec: "#{mysql_exec} 'show tables from #{name};' | grep auth"
          ], (err, executed) ->
              next err, executed
        sqlite: ->
          next null, false
      engine = hue.ini.desktop.database.engine
      return next new Error 'Hue database engine not supported' unless engines[engine]
      engines[engine]()

## Kerberos

The principal for the Hue service is created and named after "hue/{host}@{realm}". inside
the "/etc/hue/conf/hue.ini" configuration file, all the composants myst be tagged with
the "security_enabled" property set to "true".

    module.exports.push name: 'Hue # Kerberos', handler: (ctx, next) ->
      {hue, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc 
        principal: hue.ini.desktop.kerberos.hue_principal
        randkey: true
        keytab: "/etc/hue/conf/hue.service.keytab"
        uid: hue.user.name
        gid: hue.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

## SSL Client

    module.exports.push name: 'Hue # SSL Client', handler: (ctx, next) ->
      {hue} = ctx.config.ryba
      hue.ca_bundle = '' unless hue.ssl.client_ca
      ctx.write [
        destination: "#{hue.ca_bundle}"
        source: "#{hue.ssl.client_ca}"
        local_source: true
        if: !!hue.ssl.client_ca
      ,
        destination: '/etc/init.d/hue'
        match: /^DAEMON="export REQUESTS_CA_BUNDLE='.*';\$DAEMON"$/m
        replace: "DAEMON=\"export REQUESTS_CA_BUNDLE='#{hue.ca_bundle}';$DAEMON\""
        append: /^DAEMON=.*$/m
      ], next

## SSL Server

Upload and register the SSL certificate and private key respectively defined
by the "hdp.hue.ssl.certificate" and "hdp.hue.ssl.private_key" 
configuration properties. It follows the [official Hue Web Server 
Configuration][web]. The "hue" service is restarted if there was any 
changes.

    module.exports.push name: 'Hue # SSL Server', handler: (ctx, next) ->
      {hue} = ctx.config.ryba
      ctx
      .upload
        source: hue.ssl.certificate
        destination: "#{hue.conf_dir}/cert.pem"
        uid: hue.user.name
        gid: hue.group.name
      .upload
        source: hue.ssl.private_key
        destination: "#{hue.conf_dir}/key.pem"
        uid: hue.user.name
        gid: hue.group.name
      .ini
        destination: "#{hue.conf_dir}/hue.ini"
        content: desktop:
          ssl_certificate: "#{hue.conf_dir}/cert.pem"
          ssl_private_key: "#{hue.conf_dir}/key.pem"
        merge: true
        parse: misc.ini.parse_multi_brackets 
        stringify: misc.ini.stringify_multi_brackets
        separator: '='
        comment: '#'
      .then (err, modified) ->
        return next err, false if err or not modified
        ctx.service
          name: 'hue'
          action: 'restart'
        , next

## Fix Banner

In the current version "2.5.1", the HTML of the banner is escaped.

    module.exports.push name: 'Hue # Fix Banner', handler: (ctx, next) ->
      {hue} = ctx.config.ryba
      ctx
      .write
        destination: '/usr/lib/hue/desktop/core/src/desktop/templates/login.mako'
        match: '${conf.CUSTOM.BANNER_TOP_HTML.get()}'
        replace: '${ conf.CUSTOM.BANNER_TOP_HTML.get() | n,unicode }'
        bck: true
      .write
        destination: '/usr/lib/hue/desktop/core/src/desktop/templates/common_header.mako'
        write: [
          match: '${conf.CUSTOM.BANNER_TOP_HTML.get()}'
          replace: '${ conf.CUSTOM.BANNER_TOP_HTML.get() | n,unicode }'
          bck: true
          ,
          match: /\.banner \{([\s\S]*?)\}/
          replace: ".banner {#{hue.banner_style}}"
          bck: true
          if: hue.banner_style
        ]
      .then next

## Start

Use the "ryba/hue/start" module to start the Hue server.

    module.exports.push "ryba/hue/start"

## Dependencies

    misc = require 'mecano/lib/misc'
    lifecycle = require '../lib/lifecycle'

## Resources:   

*   [Official Hue website](http://gethue.com)
*   [Hortonworks instructions](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.8.0/bk_installing_manually_book/content/rpm-chap-hue.html)

## Notes

Compilation requirements: ant asciidoc cyrus-sasl-devel cyrus-sasl-gssapi gcc gcc-c++ krb5-devel libtidy libxml2-devel libxslt-devel mvn mysql mysql-devel openldap-devel python-devel python-simplejson sqlite-devel

[web]: http://gethue.com/docs-3.5.0/manual.html#_web_server_configuration