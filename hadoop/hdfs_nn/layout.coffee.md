# HDFS Datanode Layout

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs'
    # module.exports.push require('../hdfs').configure
    module.exports.push 'ryba/hadoop/hdfs_dn/wait'
    module.exports.push 'ryba/hadoop/hdfs_nn/wait'

## HDFS layout

Set up the directories and permissions inside the HDFS filesytem. The layout is inspired by the
[Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)
on the official Apache website. The following folder are created:

```
drwxr-xr-x   - hdfs   hadoop      /
drwxr-xr-x   - hdfs   hadoop      /apps
drwxrwxrwt   - hdfs   hadoop      /tmp
drwxr-xr-x   - hdfs   hadoop      /user
drwxr-xr-x   - hdfs   hadoop      /user/hdfs
```

    module.exports.push header: 'HDFS NN # HDFS layout', timeout: -1, handler: ->
      {hdfs, hadoop_group} = @config.ryba
      @wait_execute
        cmd: mkcmd.hdfs @, "hdfs dfs -test -d /"
      @execute
        cmd: mkcmd.hdfs @, """
        hdfs dfs -chmod 755 /
        """
      @execute
        cmd: mkcmd.hdfs @, """
        if hdfs dfs -test -d /tmp; then exit 2; fi
        hdfs dfs -mkdir /tmp
        hdfs dfs -chown #{hdfs.user.name}:#{hadoop_group.name} /tmp
        hdfs dfs -chmod 1777 /tmp
        """
        code_skipped: 2
      , (err, executed, stdout) ->
        @log? 'Directory "/tmp" prepared' and modified = true if executed
      @execute
        cmd: mkcmd.hdfs @, """
        if hdfs dfs -test -d /user; then exit 2; fi
        hdfs dfs -mkdir /user
        hdfs dfs -chown #{hdfs.user.name}:#{hadoop_group.name} /user
        hdfs dfs -chmod 755 /user
        hdfs dfs -mkdir /user/#{hdfs.user.name}
        hdfs dfs -chown #{hdfs.user.name}:#{hadoop_group.name} /user/#{hdfs.user.name}
        hdfs dfs -chmod 755 /user/#{hdfs.user.name}
        """
        code_skipped: 2
      , (err, executed, stdout) ->
        @log? 'Directory "/user" prepared' and modified = true if executed
      @execute
        cmd: mkcmd.hdfs @, """
        if hdfs dfs -test -d /apps; then exit 2; fi
        hdfs dfs -mkdir /apps
        hdfs dfs -chown #{hdfs.user.name}:#{hadoop_group.name} /apps
        hdfs dfs -chmod 755 /apps
        """
        code_skipped: 2
      , (err, executed, stdout) ->
        @log? 'Directory "/apps" prepared' and modified = true if executed

## HDP Layout

    module.exports.push header: 'HDFS NN # HDP Layout', timeout: -1, handler: ->
      {hdfs, hadoop_group} = @config.ryba
      @execute
        cmd: mkcmd.hdfs @, """
        version=`readlink /usr/hdp/current/hadoop-client | sed 's/.*\\/\\(.*\\)\\/hadoop/\\1/'`
        hdfs dfs -mkdir -p /hdp/apps/$version
        hdfs dfs -chown -R  #{hdfs.user.name}:#{hadoop_group.name} /hdp
        hdfs dfs -chmod 555 /hdp
        hdfs dfs -chmod 555 /hdp/apps
        hdfs dfs -chmod -R 555 /hdp/apps/$version
        """
        trap_on_error: true
        unless_exec: mkcmd.hdfs @, """
        version=`readlink /usr/hdp/current/hadoop-client | sed 's/.*\\/\\(.*\\)\\/hadoop/\\1/'`
        hdfs dfs -test -d /hdp/apps/$version
        """

## Test User

Create a Unix and Kerberos test user, by default "test" and execute simple HDFS commands to ensure
the NameNode is properly working. Note, those commands are NameNode specific, meaning they only
afect HDFS metadata.

    module.exports.push header: 'HDFS NN # HDFS Layout User Test', timeout: -1, handler: ->
      {user,group} = @config.ryba
      @execute
        cmd: mkcmd.hdfs @, """
        if hdfs dfs -test -d /user/#{user.name}; then exit 2; fi
        hdfs dfs -mkdir /user/#{user.name}
        hdfs dfs -chown #{user.name}:#{group.name} /user/#{user.name}
        hdfs dfs -chmod 750 /user/#{user.name}
        """
        code_skipped: 2

## Dependencies

    mkcmd = require '../../lib/mkcmd'
