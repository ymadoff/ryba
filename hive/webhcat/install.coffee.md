
# WebHCat

    module.exports =  header: 'WebHCat Install', handler: ->
      {webhcat, hive, hadoop_group} = @config.ryba
      port = webhcat.site['templeton.port']

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register 'hdfs_upload', 'ryba/lib/hdfs_upload'

## Wait

      @call once: true, 'ryba/zookeeper/server/wait'
      @call once: true, 'ryba/hadoop/hdfs_nn/wait'
      @call once: true, 'ryba/hive/hcatalog/wait'
      @call once: true, 'masson/core/krb5_client/wait'

## IPTables

| Service | Port  | Proto | Info                |
|---------|-------|-------|---------------------|
| webhcat | 50111 | http  | WebHCat HTTP server |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'tcp', state: 'NEW', comment: "WebHCat HTTP Server" }
        ]
        if: @config.iptables.action is 'start'

## Users & Groups

By default, the "hive" and "hive-hcatalog" packages create the following
entries:

```bash
cat /etc/passwd | grep hive
hive:x:493:493:Hive:/var/lib/hive:/sbin/nologin
cat /etc/group | grep hive
hive:x:493:
```

      @group hive.group
      @user hive.user


## Startup

Install the "hadoop-yarn-resourcemanager" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

      @call header: 'Service', handler: (options) ->
        @service 'hive-webhcat-server'
        @service 'pig'   # Upload .tar.gz
        @service 'sqoop' # Upload .tar.gz
        @hdp_select
          name: 'hive-webhcat'
        @service.init
          header: 'Init Script'
          source: "#{__dirname}/../resources/hive-webhcat-server.j2"
          local: true
          target: '/etc/init.d/hive-webhcat-server'
          mode: 0o0755
          context: @config.ryba
        @system.tmpfs
          if: -> (options.store['mecano:system:type'] in ['redhat','centos']) and (options.store['mecano:system:release'][0] is '7')
          mount: webhcat.pid_dir
          uid: hive.user.name
          gid: hadoop_group.name
          perm: '0750'
        @execute
          cmd: "service hive-webhcat-server restart"
          if: -> @status -3

## Directories

Create file system directories for log and pid.

      @call header: 'Layout', handler: ->
        @mkdir
          target: webhcat.log_dir
          uid: hive.user.name
          gid: hadoop_group.name
          mode: 0o755
        @mkdir
          target: webhcat.pid_dir
          uid: hive.user.name
          gid: hadoop_group.name
          mode: 0o755

## Configuration

Upload configuration inside '/etc/hive-webhcat/conf/webhcat-site.xml'.

      @hconfigure
        header: 'Webhcat Site'
        target: "#{webhcat.conf_dir}/webhcat-site.xml"
        source: "#{__dirname}/../../resources/hive-webhcat/webhcat-site.xml"
        local_source: true
        properties: webhcat.site
        uid: hive.user.name
        gid: hadoop_group.name
        mode: 0o0755
        merge: true

## Env

Update environnmental variables inside '/etc/hive-webhcat/conf/webhcat-env.sh'.

      @call header: 'Webhcat Env', handler: ->
        webhcat.java_opts = ''
        webhcat.java_opts += " -D#{k}=#{v}" for k, v of webhcat.opts
        @render
          source: "#{__dirname}/../../resources/hive-webhcat/webhcat-env.sh"
          local: true
          target: "#{webhcat.conf_dir}/webhcat-env.sh"
          uid: hive.user.name
          gid: hadoop_group.name
          mode: 0o0755
          write: [
            match: RegExp "export HADOOP_OPTS=.*", 'm'
            replace: "export HADOOP_OPTS=\"${HADOOP_OPTS} #{webhcat.java_opts}\" # RYBA, DONT OVERWRITE"
            append: true
          ]

## HDFS Tarballs

Upload the Pig, Hive and Sqoop tarballs inside the "/hdp/apps/$version"
HDFS directory. Note, the parent directories are created by the
"ryba/hadoop/hdfs_dn/layout" module.

      @call header: 'HDFS Tarballs', timeout: -1, handler: ->
        @hdfs_upload (
          for lib in ['pig', 'hive', 'sqoop']
            source: "/usr/hdp/current/#{lib}-client/#{lib}.tar.gz"
            target: "/hdp/apps/$version/#{lib}/#{lib}.tar.gz"
            lock: "/tmp/ryba-#{lib}.lock"
        )

        # Avoid HTTP response
        # Permission denied: user=ryba, access=EXECUTE, inode=\"/tmp/hadoop-hcat\":HTTP:hadoop:drwxr-x---

      @execute
        header: 'Fix HDFS tmp'
        cmd: mkcmd.hdfs @, """
        if hdfs dfs -test -d /tmp/hadoop-hcat; then exit 2; fi
        hdfs dfs -mkdir -p /tmp/hadoop-hcat
        hdfs dfs -chown HTTP:#{hadoop_group.name} /tmp/hadoop-hcat
        hdfs dfs -chmod -R 1777 /tmp/hadoop-hcat
        """
        code_skipped: 2

## SPNEGO

Copy the spnego keytab with restricitive permissions

      @copy
        header: 'SPNEGO'
        source: '/etc/security/keytabs/spnego.service.keytab'
        target: webhcat.site['templeton.kerberos.keytab']
        uid: hive.user.name
        gid: hadoop_group.name
        mode: 0o0660

## Log4j Properties

      @file
        header: 'Log4j'
        target: "#{webhcat.conf_dir}/webhcat-log4j.properties"
        source: "#{__dirname}/../resources/webhcat-log4j.properties"
        local_source: true
        write: for k, v of webhcat.log4j
          match: RegExp "#{k}=.*", 'm'
          replace: "#{k}=#{v}"
          append: true

## Dependencies

    mkcmd = require '../../lib/mkcmd'

## TODO: Check Hive

```
hdfs dfs -mkdir -p front1-webhcat/mytable
echo -e 'a,1\nb,2\nc,3' | hdfs dfs -put - front1-webhcat/mytable/data
hive
  create database testhcat location '/user/ryba/front1-webhcat';
  create table testhcat.mytable(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
curl --negotiate -u : -d execute="use+testhcat;select+*+from+mytable;" -d statusdir="testhcat1" http://front1.hadoop:50111/templeton/v1/hive
hdfs dfs -cat testhcat1/stderr
hdfs dfs -cat testhcat1/stdout
```
