---
title: 
layout: module
---

# Hue

[Hue][home] features a File Browser for HDFS, a Job Browser for MapReduce/YARN, an HBase Browser, query editors for Hive, Pig, Cloudera Impala and Sqoop2.
It also ships with an Oozie Application for creating and monitoring workflows, a Zookeeper Browser and a SDK. 

    misc = require 'mecano/lib/misc'
    lifecycle = require '../hadoop/lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    # Install the mysql connector
    module.exports.push 'masson/commons/mysql_client'
    # Install kerberos clients to create/test new Hive principal
    module.exports.push 'masson/core/krb5_client'
    # Set java_home in "hadoop-env.sh"
    module.exports.push 'ryba/hadoop/core'
    module.exports.push 'ryba/hadoop/mapred_client'
    module.exports.push 'ryba/hadoop/yarn_client'
    module.exports.push 'ryba/hadoop/pig'

## Configure

*   `hdp.hue_db_admin_username` (string)   
    Database admin username used to create the Hue database user.  
*   `hdp.hue_db_admin_password` (string)   
    Database admin password used to create the Hue database user.   
*   `hue.hue_ini`
    Configuration merged with default values and written to "/etc/hue/conf/hue.ini" file.   
*   `hue_user` (object|string)   
    The Unix Hue login name or a user object (see Mecano User documentation).   
*   `hue_group` (object|string)   
    The Unix Hue group name or a group object (see Mecano Group documentation).   

Example:

```json
{
  "hue": {
    "hue_user": {
      "name": "hue", "system": true, "gid": "hue",
      "comment": "Hue User", "home": "/usr/lib/hue"
    }
    "hue_group": {
      "name": "Hue", "system": true
    }
    "hue_ini": {
      "desktop": {
        "database":
          "engine": "mysql"
          "password": "hue123"
      }
    }
  }
}
```

    module.exports.push module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      # Allow proxy user inside "webhcat-site.xml"
      require('../hive/webhcat').configure ctx
      # Allow proxy user inside "oozie-site.xml"
      require('../oozie/server').configure ctx
      # Allow proxy user inside "core-site.xml"
      require('../hadoop/core').configure ctx
      {nameservice, active_nn_host, hadoop_conf_dir, webhcat_site, hue_ini, db_admin} = ctx.config.hdp
      hue_ini ?= ctx.config.hdp.hue_ini = {}
      webhcat_port = webhcat_site['templeton.port']
      webhcat_server = ctx.host_with_module 'ryba/hive/webhcat'
      # todo, this might not work as expected after ha migration
      resourcemanager = ctx.host_with_module 'ryba/hadoop/yarn_rm'
      nodemanagers = ctx.hosts_with_module 'ryba/hadoop/yarn_nm'
      # Webhdfs should be active on the NameNode, Secondary NameNode, and all the DataNodes
      # throw new Error 'WebHDFS not active' if ctx.config.hdp.hdfs_site['dfs.webhdfs.enabled'] isnt 'true'
      ctx.config.hdp.hue_conf_dir ?= '/etc/hue/conf'
      # User
      ctx.config.hdp.hue_user = name: ctx.config.hdp.hue_user if typeof ctx.config.hdp.hue_user is 'string'
      ctx.config.hdp.hue_user ?= {}
      ctx.config.hdp.hue_user.name ?= 'hue'
      ctx.config.hdp.hue_user.system ?= true
      ctx.config.hdp.hue_user.gid = 'hue'
      ctx.config.hdp.hue_user.comment ?= 'Hue User'
      ctx.config.hdp.hue_user.home = '/usr/lib/hue'
      # Group
      ctx.config.hdp.hue_group = name: ctx.config.hdp.hue_group if typeof ctx.config.hdp.hue_group is 'string'
      ctx.config.hdp.hue_group ?= {}
      ctx.config.hdp.hue_group.name ?= 'hue'
      ctx.config.hdp.hue_group.system ?= true
      # Configure HDFS Cluster
      hue_ini['hadoop'] ?= {}
      hue_ini['hadoop']['hdfs_clusters'] ?= {}
      hue_ini['hadoop']['hdfs_clusters']['default'] ?= {}
      # Using nameservice doesnt yet seem to work
      #hue_ini['hadoop']['hdfs_clusters']['default']['fs_defaultfs'] ?= "hdfs://#{nameservice}:8020"
      #hue_ini['hadoop']['hdfs_clusters']['default']['webhdfs_url'] ?= "http://#{nameservice}:50070/webhdfs/v1"
      hue_ini['hadoop']['hdfs_clusters']['default']['fs_defaultfs'] ?= "hdfs://#{active_nn_host}:8020"
      hue_ini['hadoop']['hdfs_clusters']['default']['webhdfs_url'] ?= "http://#{active_nn_host}:50070/webhdfs/v1"
      # hue_ini['hadoop']['hdfs_clusters']['default']['webhdfs_url'] ?= "http://#{namenode}:50070/webhdfs/v1"
      hue_ini['hadoop']['hdfs_clusters']['default']['hadoop_hdfs_home'] ?= '/usr/lib/hadoop'
      hue_ini['hadoop']['hdfs_clusters']['default']['hadoop_bin'] ?= '/usr/bin/hadoop'
      hue_ini['hadoop']['hdfs_clusters']['default']['hadoop_conf_dir'] ?= hadoop_conf_dir
      # Configure YARN (MR2) Cluster
      hue_ini['hadoop']['yarn_clusters'] ?= {}
      hue_ini['hadoop']['yarn_clusters']['default'] ?= {}
      hue_ini['hadoop']['yarn_clusters']['default']['resourcemanager_host'] ?= "#{resourcemanager}"
      hue_ini['hadoop']['yarn_clusters']['default']['resourcemanager_port'] ?= "8050"
      hue_ini['hadoop']['yarn_clusters']['default']['submit_to'] ?= "true"
      hue_ini['hadoop']['yarn_clusters']['default']['resourcemanager_api_url'] ?= "http://#{resourcemanager}:8088"
      hue_ini['hadoop']['yarn_clusters']['default']['proxy_api_url'] ?= "http://#{resourcemanager}:8088" # NOT very sure
      hue_ini['hadoop']['yarn_clusters']['default']['history_server_api_url'] ?= "http://#{resourcemanager}:19888"
      hue_ini['hadoop']['yarn_clusters']['default']['node_manager_api_url'] ?= "http://#{nodemanagers[0]}:8042"
      hue_ini['hadoop']['yarn_clusters']['default']['hadoop_mapred_home'] ?= "/usr/lib/hadoop-mapreduce"
      hue_ini['hadoop']['yarn_clusters']['default']['hadoop_bin'] ?= "/usr/bin/hadoop"
      hue_ini['hadoop']['yarn_clusters']['default']['hadoop_conf_dir'] ?= hadoop_conf_dir
      # Configure components
      hue_ini['liboozie'] ?= {}
      hue_ini['liboozie']['oozie_url'] ?= ctx.config.hdp.oozie_site['oozie.base.url']
      hue_ini['hcatalog'] ?= {}
      hue_ini['hcatalog']['templeton_url'] ?= "http://#{webhcat_server}:#{webhcat_port}/templeton/v1/"
      hue_ini['beeswax'] ?= {}
      hue_ini['beeswax']['beeswax_server_host'] ?= "#{ctx.config.host}"
      # Desktop
      hue_ini['desktop'] ?= {}
      hue_ini['desktop']['http_host'] ?= '0.0.0.0'
      hue_ini['desktop']['http_port'] ?= '8888'
      hue_ini['desktop']['secret_key'] ?= 'jFE93j;2[290-eiwMYSECRTEKEYy#e=+Iei*@Mn<qW5o'
      hue_ini['desktop']['smtp'] ?= {}
      ctx.log "WARING: property 'hdp.hue_ini.desktop.smtp.host' isnt set" unless hue_ini['desktop']['smtp']['host']
      # Desktop database
      hue_ini['desktop']['database'] ?= {}
      hue_ini['desktop']['database']['engine'] ?= db_admin.engine
      hue_ini['desktop']['database']['host'] ?= db_admin.host
      hue_ini['desktop']['database']['port'] ?= db_admin.port
      hue_ini['desktop']['database']['user'] ?= 'hue'
      hue_ini['desktop']['database']['password'] ?= 'hue123'
      hue_ini['desktop']['database']['name'] ?= 'hue'

## Users & Groups

By default, the "hue" package create the following entries:

```bash
cat /etc/passwd | grep hue
hue:x:494:494:Hue:/var/lib/hue:/sbin/nologin
cat /etc/group | grep hue
hue:x:494:
```

    module.exports.push name: 'HDP Hue # Users & Groups', callback: (ctx, next) ->
      {hue_group, hue_user} = ctx.config.hdp
      ctx.group hue_group, (err, gmodified) ->
        return next err if err
        ctx.user hue_user, (err, umodified) ->
          next err, if gmodified or umodified then ctx.OK else ctx.PASS

## IPTables

| Service    | Port  | Proto | Parameter          |
|------------|-------|-------|--------------------|
| Hue Web UI | 8888  | http  | desktop.http_port  |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'HDP Hue # IPTables', callback: (ctx, next) ->
      {hue_ini} = ctx.config.hdp
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hue_ini['desktop']['http_port'], protocol: 'tcp', state: 'NEW', comment: "Hue Web UI" }
        ]
        if: ctx.config.iptables.action is 'start'
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

## Packages

The packages "extjs-2.2-1" and "hue" are installed.

    module.exports.push name: 'HDP Hue # Packages', timeout: -1, callback: (ctx, next) ->
      ctx.service [
        name: 'extjs-2.2-1'
      ,
        name: 'hue'
      ], (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

## Core

Update the "core-site.xml" to allow impersonnation through the "hue" and "hcat" 
users.

Todo: We are currently only modifying the "core-site.xml" locally while it should 
be deployed on all the master and worker nodes. This is currently achieved through
the configuration picked up by the "ryba/hadoop/core" module.

    module.exports.push name: 'HDP Hue # Core', callback: (ctx, next) ->
      {hadoop_conf_dir} = ctx.config.hdp
      properties = 
        'hadoop.proxyuser.hue.hosts': '*'
        'hadoop.proxyuser.hue.groups': '*'
        'hadoop.proxyuser.hcat.groups': '*'
        'hadoop.proxyuser.hcat.hosts': '*'
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/core-site.xml"
        properties: properties
        merge: true
      , (err, configured) ->
        return next err if err
        next err, if configured then ctx.OK else ctx.PASS

## WebHCat


Update the "webhcat-site.xml" on the server running the "webhcat" service 
to allow impersonnation through the "hue" user.


    module.exports.push name: 'HDP Hue # WebHCat', callback: (ctx, next) ->
      {webhcat_conf_dir} = ctx.config.hdp
      webhcat_server = ctx.host_with_module 'ryba/hive/webhcat'
      hconfigure = (ssh) ->
        properties = 
          'webhcat.proxyuser.hue.hosts': '*'
          'webhcat.proxyuser.hue.groups': '*'
        ctx.hconfigure
          destination: "#{webhcat_conf_dir}/webhcat-site.xml"
          properties: properties
          merge: true
        , (err, configured) ->
          return next err if err
          next err, if configured then ctx.OK else ctx.PASS
      if ctx.config.host is webhcat_server
        hconfigure ctx.ssh
      else
        ctx.connect webhcat_server, (err, ssh) ->
          return next err if err
          hconfigure ssh

## Oozie


Update the "oozie-site.xml" on the server running the "oozie" service 
to allow impersonnation through the "hue" user.

    module.exports.push name: 'HDP Hue # Oozie', callback: (ctx, next) ->
      {oozie_conf_dir} = ctx.config.hdp
      oozie_server = ctx.host_with_module 'ryba/oozie/server'
      hconfigure = (ssh) ->
        properties = 
          'oozie.service.ProxyUserService.proxyuser.hue.hosts': '*'
          'oozie.service.ProxyUserService.proxyuser.hue.groups': '*'
        ctx.hconfigure
          ssh: ssh
          destination: "#{oozie_conf_dir}/oozie-site.xml"
          properties: properties
          merge: true
        , (err, configured) ->
          return next err if err
          next err, if configured then ctx.OK else ctx.PASS
      if ctx.config.host is oozie_server
        hconfigure ctx.ssh
      else
        ctx.connect oozie_server, (err, ssh) ->
          return next err if err
          hconfigure ssh

## Configure

Configure the "/etc/hue/conf" file following the [HortonWorks](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.8.0/bk_installing_manually_book/content/rpm-chap-hue-5-2.html) 
recommandations. Merge the configuration object from "hdp.hue_ini" with the properties of the destination file. 

    module.exports.push name: 'HDP Hue # Configure', callback: (ctx, next) ->
      {hue_conf_dir, hue_ini} = ctx.config.hdp
      ctx.ini
        destination: "#{hue_conf_dir}/hue.ini"
        content: hue_ini
        merge: true
        parse: misc.ini.parse_multi_brackets 
        stringify: misc.ini.stringify_multi_brackets
        separator: '='
        comment: '#'
      , (err, written) ->
        next err, if written then ctx.OK else ctx.PASS

## Database

Setup the database hosting the Hue data. Currently two database providers are
implemented but Hue supports MySQL, PostgreSQL, and Oracle. Note, sqlite is 
the default database while mysql is the recommanded choice.

    module.exports.push name: 'HDP Hue # Database', callback: (ctx, next) ->
      {hue_ini, hue_user, db_admin} = ctx.config.hdp
      engines = 
        mysql: ->
          {host, port, user, password, name} = hue_ini['desktop']['database']
          escape = (text) -> text.replace(/[\\"]/g, "\\$&")
          cmd = "#{db_admin.path} -u#{db_admin.username} -p#{db_admin.password} -h#{db_admin.host} -P#{db_admin.port} -e "
          ctx.execute
            cmd: """
            if #{cmd} "use #{name}"; then exit 2; fi
            #{cmd} "
            create database #{name};
            grant all privileges on #{name}.* to '#{user}'@'localhost' identified by '#{password}';
            grant all privileges on #{name}.* to '#{user}'@'%' identified by '#{password}';
            flush privileges;
            "
            """
            code_skipped: 2
          , (err, created, stdout, stderr) ->
            return next err, ctx.PASS if err or not created
            ctx.execute
              cmd: """
              su -l #{hue_user.name} -c "/usr/lib/hue/build/env/bin/hue syncdb --noinput"
              """
            , (err, executed) ->
              next err, ctx.OK
        sqlite: ->
          next null, ctx.PASS
      engine = hue_ini['desktop']['database']['engine']
      return next new Error 'Hue database engine not supported' unless engines[engine]
      engines[engine]()

## Kerberos

The principal for the Hue service is created and named after "hue/{host}@{realm}". inside
the "/etc/hue/conf/hue.ini" configuration file, all the composants myst be tagged with
the "security_enabled" property set to "true".

    module.exports.push name: 'HDP Hue # Kerberos', callback: (ctx, next) ->
      {hue_user, hue_group, hue_conf_dir, realm} = ctx.config.hdp
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      principal = "hue/#{ctx.config.host}@#{realm}"
      modified = false
      do_addprinc = ->
        ctx.krb5_addprinc 
          principal: principal
          randkey: true
          keytab: "/etc/hue/conf/hue.service.keytab"
          uid: hue_user.name
          gid: hue_group.name
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server
        , (err, created) ->
          return next err if err
          modified = true if created
          do_config()
      do_config = ->
        hue_ini = {}
        hue_ini['desktop'] ?= {}
        hue_ini['desktop']['kerberos'] ?= {}
        hue_ini['desktop']['kerberos']['hue_keytab'] ?= '/etc/hue/conf/hue.service.keytab'
        hue_ini['desktop']['kerberos']['hue_principal'] ?= principal
        # Path to kinit
        # For RHEL/CentOS 5.x, kinit_path is /usr/kerberos/bin/kinit
        # For RHEL/CentOS 6.x, kinit_path is /usr/bin/kinit 
        hue_ini['desktop']['kerberos']['kinit_path'] ?= '/usr/bin/kinit'
        # Uncomment all security_enabled settings and set them to true
        hue_ini['hadoop'] ?= {}
        hue_ini['hadoop']['hdfs_clusters'] ?= {}
        hue_ini['hadoop']['hdfs_clusters']['default'] ?= {}
        hue_ini['hadoop']['hdfs_clusters']['default']['security_enabled'] = 'true'
        hue_ini['hadoop'] ?= {}
        hue_ini['hadoop']['mapred_clusters'] ?= {}
        hue_ini['hadoop']['mapred_clusters']['default'] ?= {}
        hue_ini['hadoop']['mapred_clusters']['default']['security_enabled'] = 'true'
        hue_ini['hadoop'] ?= {}
        hue_ini['hadoop']['yarn_clusters'] ?= {}
        hue_ini['hadoop']['yarn_clusters']['default'] ?= {}
        hue_ini['hadoop']['yarn_clusters']['default']['security_enabled'] = 'true'
        hue_ini['liboozie'] ?= {}
        hue_ini['liboozie']['security_enabled'] = 'true'
        hue_ini['hcatalog'] ?= {}
        hue_ini['hcatalog']['security_enabled'] = 'true'
        ctx.ini
          destination: "#{hue_conf_dir}/hue.ini"
          content: hue_ini
          merge: true
          parse: misc.ini.parse_multi_brackets 
          stringify: misc.ini.stringify_multi_brackets
          separator: '='
          comment: '#'
        , (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, if modified then ctx.OK else ctx.PASS
      do_addprinc()

## Start

Use the "ryba/hue/start" module to start the Hue server.

    module.exports.push "ryba/hue/start"

## SSL

Upload and register the SSL certificate and private key respectively defined
by the "hdp.hue\_ssl\_certificate" and "hdp.hue\_ssl\_private_key" 
configuration properties. It follows the [official Hue Web Server 
Configuration][web]. The "hue" service is restarted if there was any 
changes.

    module.exports.push name: 'HDP Hue # SSL', callback: (ctx, next) ->
      {hue_user, hue_group, hue_conf_dir, hue_ssl_certificate, hue_ssl_private_key} = ctx.config.hdp
      modified = true
      do_upload = ->
        ctx.upload [
          source: hue_ssl_certificate
          destination: "#{hue_conf_dir}/cert.pem"
          uid: hue_user.name
          gid: hue_group.name
        ,
          source: hue_ssl_private_key
          destination: "#{hue_conf_dir}/key.pem"
          uid: hue_user.name
          gid: hue_group.name
        ], (err, uploaded) ->
          return next err if err
          modified = true if uploaded
          do_ini()
      do_ini = ->
        ctx.ini
          destination: "#{hue_conf_dir}/hue.ini"
          content: desktop:
            ssl_certificate: "#{hue_conf_dir}/cert.pem"
            ssl_private_key: "#{hue_conf_dir}/key.pem"
          merge: true
          parse: misc.ini.parse_multi_brackets 
          stringify: misc.ini.stringify_multi_brackets
          separator: '='
          comment: '#'
        , (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        return next null, ctx.PASS unless modified
        ctx.service
          name: 'hue'
          action: 'restart'
        , (err) ->
          next err, ctx.OK
      do_upload()

## Resources:   

*   [Official Hue website](http://gethue.com)
*   [Hortonworks instruction](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.8.0/bk_installing_manually_book/content/rpm-chap-hue.html)

## Notes

Compilation requirements: ant asciidoc cyrus-sasl-devel cyrus-sasl-gssapi gcc gcc-c++ krb5-devel libtidy libxml2-devel libxslt-devel mvn mysql mysql-devel openldap-devel python-devel python-simplejson sqlite-devel

[home]: http://gethue.com
[web]: http://gethue.com/docs-3.5.0/manual.html#_web_server_configuration








