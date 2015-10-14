
# WebHCat

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs' # Install SPNEGO keytab
    module.exports.push 'ryba/hive/client'
    module.exports.push 'ryba/pig'
    module.exports.push 'ryba/tools/sqoop'
    # module.exports.push require('./index').configure
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/hdfs_upload'
    module.exports.push require '../../lib/hdp_select'

## IPTables

| Service | Port  | Proto | Info                |
|---------|-------|-------|---------------------|
| webhcat | 50111 | http  | WebHCat HTTP server |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'WebHCat # IPTables', handler: ->
      {webhcat} = @config.ryba
      port = webhcat.site['templeton.port']
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'tcp', state: 'NEW', comment: "WebHCat HTTP Server" }
        ]
        if: @config.iptables.action is 'start'

## Startup

Install the "hadoop-yarn-resourcemanager" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

    module.exports.push name: 'WebHCat # Service', handler: ->
      @service
        name: 'hive-webhcat-server'
      @hdp_select
        name: 'hive-webhcat'
      @write
        source: "#{__dirname}/../resources/hive-webhcat-server"
        local_source: true
        destination: '/etc/init.d/hive-webhcat-server'
        mode: 0o0755
        unlink: true
      @execute
        cmd: "service hive-webhcat-server restart"
        if: -> @status -3

## Directories

Create file system directories for log and pid. 

    module.exports.push name: 'WebHCat # Directories', handler: ->
      {webhcat, hive, hadoop_group} = @config.ryba
      @mkdir
        destination: webhcat.log_dir
        uid: hive.user.name
        gid: hadoop_group.name
        mode: 0o755
      @mkdir
        destination: webhcat.pid_dir
        uid: hive.user.name
        gid: hadoop_group.name
        mode: 0o755

## Configuration

Upload configuration inside '/etc/hive-webhcat/conf/webhcat-site.xml'.

    module.exports.push name: 'WebHCat # Configuration', handler: ->
      {webhcat, hive, hadoop_group} = @config.ryba
      @hconfigure
        destination: "#{webhcat.conf_dir}/webhcat-site.xml"
        default: "#{__dirname}/../../resources/hive-webhcat/webhcat-site.xml"
        local_default: true
        properties: webhcat.site
        uid: hive.user.name
        gid: hadoop_group.name
        mode: 0o0755
        merge: true

## Env

Update environnmental variables inside '/etc/hive-webhcat/conf/webhcat-env.sh'.

    module.exports.push name: 'WebHCat # Env', handler: ->
      {webhcat, hive, hadoop_group} = @config.ryba
      @upload
        source: "#{__dirname}/../../resources/hive-webhcat/webhcat-env.sh"
        destination: "#{webhcat.conf_dir}/webhcat-env.sh"
        uid: hive.user.name
        gid: hadoop_group.name
        mode: 0o0755

## HDFS Tarballs

Upload the Pig, Hive and Sqoop tarballs inside the "/hdp/apps/$version"
HDFS directory. Note, the parent directories are created by the
"ryba/hadoop/hdfs_dn/layout" module.

    module.exports.push name: 'WebHCat # HDFS Tarballs', timeout: -1, handler: ->
      @hdfs_upload (
        for lib in ['pig', 'hive', 'sqoop']
          source: "/usr/hdp/current/#{lib}-client/#{lib}.tar.gz"
          target: "/hdp/apps/$version/#{lib}/#{lib}.tar.gz"
          lock: "/tmp/ryba-#{lib}.lock"
      )

    module.exports.push name: 'WebHCat # Fix HDFS tmp', handler: ->
      # Avoid HTTP response
      # Permission denied: user=ryba, access=EXECUTE, inode=\"/tmp/hadoop-hcat\":HTTP:hadoop:drwxr-x---
      {hive, hadoop_group} = @config.ryba
      modified = false
      @execute
        cmd: mkcmd.hdfs @, """
        if hdfs dfs -test -d /tmp/hadoop-hcat; then exit 2; fi
        hdfs dfs -mkdir -p /tmp/hadoop-hcat
        hdfs dfs -chown HTTP:#{hadoop_group.name} /tmp/hadoop-hcat
        hdfs dfs -chmod -R 1777 /tmp/hadoop-hcat
        """
        code_skipped: 2

## SPNEGO

Copy the spnego keytab with restricitive permissions

    module.exports.push name: 'WebHCat # SPNEGO', handler: ->
      {webhcat, hive, hadoop_group} = @config.ryba
      @copy
        source: '/etc/security/keytabs/spnego.service.keytab'
        destination: webhcat.site['templeton.kerberos.keytab']
        uid: hive.user.name
        gid: hadoop_group.name
        mode: 0o0660

## Dependencies

    mkcmd = require '../../lib/mkcmd'

## TODO: Check Hive

hdfs dfs -mkdir -p front1-webhcat/mytable
echo -e 'a,1\nb,2\nc,3' | hdfs dfs -put - front1-webhcat/mytable/data
hive
  create database testhcat location '/user/ryba/front1-webhcat';
  create table testhcat.mytable(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
curl --negotiate -u : -d execute="use+testhcat;select+*+from+mytable;" -d statusdir="testhcat1" http://front1.hadoop:50111/templeton/v1/hive
hdfs dfs -cat testhcat1/stderr
hdfs dfs -cat testhcat1/stdout
