
# Hue Install

Install  dockerized hue 3.8 container. The container can be build by ./bin/prepare
script or directly downloaded (from local computer only for now,
no images available on dockerhub).

Run `ryba prepare` to create the Docker container.

    module.exports = header: 'Hue Docker Install', handler: ->
      {hue_docker, db_admin, realm, ssl} = @config.ryba
      {hadoop_group, hdfs, hive, hbase} = @config.ryba
      hadoop_conf_dir = hue_docker.ini['hadoop']['hdfs_clusters']['default']['hadoop_conf_dir']
      hive_conf_dir = hue_docker.ini['beeswax']['hive_conf_dir'] 
      hbase_conf_dir = hue_docker.ini['hbase']['hbase_conf_dir']
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      machine = @config.mecano.machine

## Register

      @register 'hconfigure', 'ryba/lib/hconfigure'

## Wait

      @call once: true, 'ryba/hadoop/yarn_rm/wait'
      @call once: true, 'ryba/hadoop/hdfs_nn/wait'
      @call once: true, 'ryba/hbase/thrift/wait'
      @call once: true, 'ryba/oozie/server/wait'
      @call once: true, 'ryba/hive/server2/wait'
      @call once: true, 'ryba/hive/hcatalog/wait'

## Users & Groups

By default, the "hue" package create the following entries:

```bash
cat /etc/passwd | grep hue
hue:x:494:494:Hue:/var/lib/hue:/sbin/nologin
cat /etc/group | grep hue
hue:x:494:
```

      @group hue_docker.group
      @user hue_docker.user

## IPTables

| Service    | Port  | Proto | Parameter          |
|------------|-------|-------|--------------------|
| Hue Web UI | 8888  | http  | desktop.http_port  |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hue_docker.ini.desktop.http_port, protocol: 'tcp', state: 'NEW', comment: "Hue Web UI" }
        ]
        if: @config.iptables.action is 'start'

## Hive

Update the "hive-site.xml" with the hive/server2 kerberos principal.

      @call header: 'Hive Site', handler: ->
        [hive_ctx] = @contexts 'ryba/hive/server2'
        if hive_ctx?
          {hive} = hive_ctx.config.ryba
          @hconfigure
            destination: "#{hive.conf_dir}/hive-site.xml"
            properties: {
              'hive.server2.authentication.kerberos.principal': "#{hive.site['hive.server2.authentication.kerberos.principal']}"
              'hive.server2.authentication': "#{hive.site['hive.server2.authentication']}"
              # Properties in client which are not synced
              'hive.server2.transport.mode': "#{hive.site['hive.server2.transport.mode']}"
              'hive.server2.use.SSL' : "#{hive.site['hive.server2.use.SSL']}"
              'hive.server2.thrift.sasl.qop' : "#{hive.site['hive.server2.thrift.sasl.qop']}"
              'hive.server2.thrift.http.port' : "#{hive.site['hive.server2.thrift.http.port']}"
              'hive.server2.thrift.port' : "#{hive.site['hive.server2.thrift.port']}"
            }
            merge: true
            backup: true

## HBase

Update the "hbase-site.xml" with the hbase/thrift kerberos principal.

      @call header: 'HBase Site', handler: ->
        [hbase_ctx] = @contexts 'ryba/hbase/thrift'
        if hbase_ctx?
          {hbase} = hbase_ctx.config.ryba
          # props = {}
          # props['hbase.security.authentication'] = hbase.site['hbase.security.authentication']
          # props['hbase.security.authorization'] = hbase.site['hbase.security.authorization']
          # for k, v of hbase.site
          #   props[k] = v if  k.indexOf('thrift') isnt  -1
          @hconfigure
            destination: "#{hbase.conf_dir}/hbase-site.xml"
            properties: {
              'hbase.thrift.port': "#{hbase.thrift.site['hbase.thrift.port']}"
              'hbase.thrift.info.port': "#{hbase.thrift.site['hbase.thrift.info.port']}"
              'hbase.thrift.support.proxyuser': "#{hbase.thrift.site['hbase.thrift.support.proxyuser']}"
              'hbase.thrift.security.qop': "#{hbase.site['hbase.thrift.thrift.security.qop']}"
              'hbase.thrift.authentication.type': "#{hbase.thrift.site['hbase.thrift.authentication.type']}"
              'hbase.thrift.kerberos.principal': "#{hbase.thrift.site['hbase.thrift.kerberos.principal']}"
              'hbase.thrift.ssl.enabled': "#{hbase.thrift.site['hbase.thrift.ssl.enabled']}"
            }
            backup: true
            merge: true

## Configure

Configure the "/etc/hue/conf" file following the [HortonWorks](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.8.0/bk_installing_manually_book/content/rpm-chap-hue-5-2.html)
recommandations. Merge the configuration object from "pseudo-distributed.ini" with the properties of the destination file.

      @write_ini
        header: 'hue ini'
        destination: "#{hue_docker.conf_dir}/hue_docker.ini"
        content: hue_docker.ini
        backup: true
        parse: misc.ini.parse_multi_brackets
        stringify: misc.ini.stringify_multi_brackets
        separator: '='
        comment: '#'
        uid: hue_docker.user.name
        gid: hue_docker.group.name
        mode: 0o0750

## Database

Setup the database hosting the Hue data. Currently two database providers are
implemented but Hue supports MySQL, PostgreSQL, and Oracle. Note, sqlite is
the default database while mysql is the recommanded choice.

      @call header: 'Hue Docker # Database', handler: ->
        switch hue_docker.ini.desktop.database.engine
          when 'mysql'
            {user, password, name} = hue_docker.ini.desktop.database
            escape = (text) -> text.replace(/[\\"]/g, "\\$&")
            mysql_exec = "#{db_admin.path} -u#{db_admin.username} -p#{db_admin.password} -h#{db_admin.host} -P#{db_admin.port} -e "
            @execute
              cmd: """
              #{mysql_exec} "
              create database #{name};
              grant all privileges on #{name}.* to '#{user}'@'localhost' identified by '#{password}';
              grant all privileges on #{name}.* to '#{user}'@'%' identified by '#{password}';
              flush privileges;
              "
              """
              unless_exec: "#{mysql_exec} 'use #{name}'"
          else throw Error 'Hue database engine not supported'

## Kerberos

The principal for the Hue service is created and named after "hue/{host}@{realm}". inside
the "/etc/hue/conf/hue_docker.ini" configuration file, all the composants myst be tagged with
the "security_enabled" property set to "true".

      @krb5_addprinc krb5,
        header: 'Kerberos'
        principal: hue_docker.ini.desktop.kerberos.hue_principal
        randkey: true
        keytab: hue_docker.ini.desktop.kerberos.hue_keytab
        uid: hue_docker.user.name
        gid: hue_docker.group.name

## SSL Client

Write trustore into /etc/hue/conf folder for hue to be able to connect as a
client over ssl. Then the REQUESTS_CA_BUNDLE environment variable is set to the
path  during docker run.

      # hue_docker.ca_bundle = '' unless hue_docker.ssl.client_ca
      @write
        header: 'SSL Client'
        destination: "#{hue_docker.ca_bundle}"
        source: "#{hue_docker.ssl.client_ca}"
        local_source: true
        if: !!hue_docker.ssl.client_ca
        backup: true

## SSL Server

Upload and register the SSL certificate and private key respectively defined
by the "hdp.hue_docker.ssl.certificate" and "hdp.hue_docker.ssl.private_key"
configuration properties. It follows the [official Hue Web Server
Configuration][web]. The "hue" service is restarted if there was any
changes.

      @call header: 'SSL Server', handler: ->
        return unless hue_docker.ssl
        @download
          source: ssl.cert
          destination: "#{hue_docker.conf_dir}/cert.pem"
          uid: hue_docker.user.name
          gid: hue_docker.group.name
        @download
          source: ssl.key
          destination: "#{hue_docker.conf_dir}/key.pem"
          uid: hue_docker.user.name
          gid: hue_docker.group.name
        @write_ini
          destination: "#{hue_docker.conf_dir}/hue_docker.ini"
          content: desktop:
            ssl_certificate: "#{hue_docker.conf_dir}/cert.pem"
            ssl_private_key: "#{hue_docker.conf_dir}/key.pem"
          merge: true
          parse: misc.ini.parse_multi_brackets
          stringify: misc.ini.stringify_multi_brackets
          separator: '='
          comment: '#'
          backup: true
        @docker_stop
          machine: machine
          if: -> @status -1
          container: hue_docker.container

## Layout log Hue

      @call header: 'Layout', timeout: -1, handler:  ->
        @mkdir
          destination: hue_docker.log_dir
          uid: hue_docker.user.name
          gid: hue_docker.group.name
          mode: 0o755
          parent: true
        @mkdir
          destination: '/tmp/hue_docker'
          uid: hue_docker.user.name
          gid: hue_docker.group.name
          mode: 0o755

## Install Hue container

Install Hue server docker container.
It uses local checksum if provided to upload or not.

      @call header: 'Upload Container', timeout: -1, retry:3, handler: (options)  ->
        tmp = hue_docker.image_dir
        md5 = hue_docker.md5 ?= true
        @download
          source: "#{hue_docker.prod.directory}/#{hue_docker.prod.tar}"
          destination: "#{tmp}/#{hue_docker.prod.tar}"
          binary: true
          md5: md5
        @docker_load
          input: "#{tmp}/#{hue_docker.prod.tar}"

## Run Hue Server Container

Runs the hue docker container after configuration and installation
```
docker run --name hue_server --net host -d -v /etc/hadoop/conf:/etc/hadoop/conf
-v /etc/hadoop-httpfs/conf:/etc/hadoop-httpfs/conf -v /etc/hive/conf:/etc/hive/conf
-v /etc/hue/conf:/etc/hue/conf -v /var/log/hue:/var/log/hue -v /etc/krb5.conf:/etc/krb5.conf
-v /etc/security/keytabs:/etc/security/keytabs -v /etc/usr/hdp:/usr/hdp
-v /etc/hue/conf/hue_docker.ini:/var/lib/hue/desktop/conf/pseudo-distributed.ini
-e REQUESTS_CA_BUNDLE=/etc/hue/conf/trust.pem -e KRB5CCNAME=:/tmp/krb5cc_2410
ryba/hue:3.9

```

      @docker_service
        machine: machine
        header: 'Hue Docker # Run'
        label_true: 'RUNNED'
        force: -> @status -1
        image: "#{hue_docker.image}:#{hue_docker.version}"
        volume: [
          "#{hue_docker.conf_dir}/hue_docker.ini:/var/lib/hue/desktop/conf/pseudo-distributed.ini"
          "#{hadoop_conf_dir}:#{hadoop_conf_dir}"
          "#{hive_conf_dir}:#{hive_conf_dir}"
          "#{hue_docker.conf_dir}:#{hue_docker.conf_dir}"
          "#{hbase_conf_dir}:#{hbase_conf_dir}"
          "#{hue_docker.log_dir}:/var/lib/hue/logs"
          '/etc/krb5.conf:/etc/krb5.conf'
          '/etc/security/keytabs:/etc/security/keytabs'
          '/etc/usr/hdp:/usr/hdp'
          '/tmp/hue_docker:/tmp'
        ]
        # Fix SSL Communication between hue as client and hadoop components
        # by setting the ca bundle path as global env variable
        env: [
          "REQUESTS_CA_BUNDLE=#{hue_docker.ca_bundle}"
          "KRB5CCNAME=FILE:/tmp/krb5cc_#{hue_docker.user.uid}"
          "DESKTOP_LOG_DIR=/var/lib/hue/logs"
        ]
        net: 'host'
        service: true
        name: hue_docker.container

## Startup Script

Write startup script to /etc/init.d/service-hue-docker

      @call header: 'Startup Script', handler:  ->
        @render
          source: "#{__dirname}/resources/#{hue_docker.service}"
          local_source: true
          destination: "/etc/init.d/#{hue_docker.service}"
          context: hue_docker
        @chmod
          destination: "/etc/init.d/#{hue_docker.service}"
          mode: 0o755

## Dependencies

    misc = require 'mecano/lib/misc'
    fs = require 'fs'

## Resources:

*   [Official Hue website](http://gethue_docker.com)
*   [Hortonworks instructions](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_installing_manually_book/content/configure_hdp_hue_docker.html)
*   [Cloudera instructions](https://github.com/cloudera/hue#development-prerequisites)

## Notes

Compilation requirements: ant asciidoc cyrus-sasl-devel cyrus-sasl-gssapi gcc gcc-c++ krb5-devel libtidy libxml2-devel libxslt-devel mvn mysql mysql-devel openldap-devel python-devel python-simplejson sqlite-devel

[web]: http://gethue_docker.com/docs-3.5.0/manual.html#_web_server_configuration
