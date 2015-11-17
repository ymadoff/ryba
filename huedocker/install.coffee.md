
# Hue Install

Install  dockerized hue 3.8 container. The container can be build by ./bin/prepare
script or directly downloaded (from local computer only for now,
no images available on dockerhub).



    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    # Install the mysql connector
    module.exports.push 'masson/commons/mysql_client'
    # Install kerberos clients to create/test new Hive principal
    module.exports.push 'masson/core/krb5_client'
    # Needs docker to run container
    module.exports.push 'masson/commons/docker'
    # Set java_home in "hadoop-env.sh"
    module.exports.push 'ryba/oozie/client/install'
    module.exports.push 'ryba/hadoop/hdfs_client/install'
    module.exports.push 'ryba/hadoop/yarn_client/install'
    module.exports.push 'ryba/hadoop/mapred_client/install'
    module.exports.push 'ryba/hbase/client/install'
    module.exports.push 'ryba/hive/client/install' # Hue reference hive conf dir
    module.exports.push 'ryba/pig/install'
    module.exports.push 'ryba/lib/hconfigure'
    # module.exports.push require('./index').configure

To import container after bin prepare...


## Users & Groups

By default, the "hue" package create the following entries:

```bash
cat /etc/passwd | grep hue
hue:x:494:494:Hue:/var/lib/hue:/sbin/nologin
cat /etc/group | grep hue
hue:x:494:
```

    module.exports.push name: 'Hue # Users & Groups', handler: ->
      {hue_docker} = @config.ryba
      @group hue_docker.group
      @user hue_docker.user

## IPTables

| Service    | Port  | Proto | Parameter          |
|------------|-------|-------|--------------------|
| Hue Web UI | 8888  | http  | desktop.http_port  |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'Hue Docker # IPTables', handler: ->
      {hue_docker} = @config.ryba
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hue_docker.ini.desktop.http_port, protocol: 'tcp', state: 'NEW', comment: "Hue Web UI" }
        ]
        if: @config.iptables.action is 'start'

## Hive

Update the "hive-site.xml" with the hive/server2 kerberos principal.

    module.exports.push name: 'Hue Docker # Hive',  handler: ->
      [hive_ctx] = @contexts 'ryba/hive/server2'
      if hive_ctx?
        {hive} = hive_ctx.config.ryba
        @hconfigure
          destination: "#{hive.conf_dir}/hive-site.xml"
          properties: 'hive.server2.authentication.kerberos.principal': "#{hive.site['hive.server2.authentication.kerberos.principal']}"
          merge: true
          backup: true

## HBase

Update the "hbase-site.xml" with the hbase/thrift kerberos principal.

    module.exports.push name: 'Hue Docker # Hbase',  handler: ->
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
          properties: hbase.site
          # 'hbase.thrift.kerberos.principal': "#{hbase.site['hbase.thrift.kerberos.principal']}"
          backup: true

## Configure

Configure the "/etc/hue/conf" file following the [HortonWorks](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.8.0/bk_installing_manually_book/content/rpm-chap-hue-5-2.html)
recommandations. Merge the configuration object from "pseudo-distributed.ini" with the properties of the destination file.

    module.exports.push name: 'Hue Docker # Configure', handler: ->
      {hue_docker} = @config.ryba
      @ini
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

    module.exports.push name: 'Hue Docker # Database', handler: ->
      {hue_docker, db_admin} = @config.ryba
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

    module.exports.push name: 'Hue Docker # Kerberos', handler: ->
      {hue_docker, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: hue_docker.ini.desktop.kerberos.hue_principal
        randkey: true
        keytab: "/etc/hue/conf/hue_docker.service.keytab"
        uid: hue_docker.user.name
        gid: hue_docker.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

## SSL Client

Write trustore into /etc/hue/conf folder for hue to be able to connect as a
client over ssl. Then the REQUESTS_CA_BUNDLE environment variable is set to the
path  during docker run.

    module.exports.push name: 'Hue Docker # SSL Client', handler: ->
      {hue_docker} = @config.ryba
      hue_docker.ca_bundle = '' unless hue_docker.ssl.client_ca
      @write
        destination: "#{hue_docker.ca_bundle}"
        source: "#{hue_docker.ssl.client_ca}"
        local_source: true
        if: !!hue_docker.ssl.client_ca

## SSL Server

Upload and register the SSL certificate and private key respectively defined
by the "hdp.hue_docker.ssl.certificate" and "hdp.hue_docker.ssl.private_key"
configuration properties. It follows the [official Hue Web Server
Configuration][web]. The "hue" service is restarted if there was any
changes.

    module.exports.push name: 'Hue Docker # SSL Server', handler: ->
      {hue_docker} = @config.ryba
      @upload
        source: hue_docker.ssl.certificate
        destination: "#{hue_docker.conf_dir}/cert.pem"
        uid: hue_docker.user.name
        gid: hue_docker.group.name
      @upload
        source: hue_docker.ssl.private_key
        destination: "#{hue_docker.conf_dir}/key.pem"
        uid: hue_docker.user.name
        gid: hue_docker.group.name
      @ini
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
        container: hue_docker.container
        if_exec:"""
        if docker ps | grep #{hue_docker.container};
        then  exit 0 ; else exit 1; fi
        """

## Install Hue  container

 Load Hue Container from local host

    module.exports.push
      name: 'Hue Docker # Container', timeout: -1, handler:  ->
        {hue_docker} = @config.ryba
        tmp = '/user/hue_docker.tar'
        @download
          source: "#{__dirname}/resources/hue.tar"
          destination: tmp
          unless_exec: "docker images | grep #{hue_docker.image}| grep #{hue_docker.version}"
        @docker_load
          source: tmp
          unless_exec: "docker images | grep #{hue_docker.image} | grep #{hue_docker.version}"
        # @docker_rm
        #   force: true
        #   container: hue_docker.container
        #   unless_exec: "docker ps -a | grep #{hue_docker.image} | grep #{hue_docker.version}"
        @remove
          destination: tmp
          # unless_exec: """
          # hue_version=`docker images | grep #{hue_docker.image}:#{hue_docker.version} | awk '{ print $2 }'`
          # hue_target=#{hue_docker.version}
          # if [ "$hue_version" == "$hue_target" ];then  exit 0 ; else exit 1; fi
          # """

## Run Hue Server Container

Runs the hue docker container after configuration and installation

```
docker run --name hue_server --net host -d -v /etc/hadoop/conf:/etc/hadoop/conf
-v /etc/hadoop-httpfs/conf:/etc/hadoop-httpfs/conf -v /etc/hive/conf:/etc/hive/conf
-v /etc/hue/conf:/etc/hue/conf -v /var/log/hue:/var/log/hue -v /etc/krb5.conf:/etc/krb5.conf
-v /etc/security/keytabs:/etc/security/keytabs -v /etc/usr/hdp:/usr/hdp
-v /etc/hue/conf/hue_docker.ini:/var/lib/hue/desktop/conf/pseudo-distributed.ini
-e REQUESTS_CA_BUNDLE=/etc/hue/conf/trust.pem -e KRB5CCNAME=:/tmp/krb5cc_2410
ryba/hue:3.8

```

    module.exports.push name: 'Hue Docker # Run', label_true: 'RUNNED', handler:  ->
      {hadoop_group,hadoop_conf_dir, hdfs, hue_docker, hive, hbase} = @config.ryba
      @docker_run
        image: "#{hue_docker.image}:#{hue_docker.version}"
        volume: [
          "#{hadoop_conf_dir}:#{hadoop_conf_dir}"
          "#{hive.conf_dir}:#{hive.conf_dir}"
          "#{hue_docker.conf_dir}:#{hue_docker.conf_dir}"
          "#{hbase.conf_dir}:#{hbase.conf_dir}"
          "#{hue_docker.log_dir}:/var/lib/hue/logs"
          '/etc/krb5.conf:/etc/krb5.conf'
          '/etc/security/keytabs:/etc/security/keytabs'
          '/etc/usr/hdp:/usr/hdp'
          "#{hue_docker.conf_dir}/hue_docker.ini:/var/lib/hue/desktop/conf/pseudo-distributed.ini"
        ]
        # Fix SSL Communication for hue as client by setting the ca bundle path as global env variable
        env: [
          "REQUESTS_CA_BUNDLE=#{hue_docker.ca_bundle}"
          "KRB5CCNAME=:/tmp/krb5cc_2410"
        ]
        net: 'host'
        service: true
        container: hue_docker.container
        unless_exec:"""
        if docker ps -a | grep #{hue_docker.image};
        then  exit 0 ; else exit 1; fi
        """


## Dependencies

    misc = require 'mecano/lib/misc'

## Resources:

*   [Official Hue website](http://gethue_docker.com)
*   [Hortonworks instructions](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_installing_manually_book/content/configure_hdp_hue_docker.html)
*   [Cloudera instructions](https://github.com/cloudera/hue#development-prerequisites)

## Notes

Compilation requirements: ant asciidoc cyrus-sasl-devel cyrus-sasl-gssapi gcc gcc-c++ krb5-devel libtidy libxml2-devel libxslt-devel mvn mysql mysql-devel openldap-devel python-devel python-simplejson sqlite-devel

[web]: http://gethue_docker.com/docs-3.5.0/manual.html#_web_server_configuration