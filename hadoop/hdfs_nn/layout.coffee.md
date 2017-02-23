# HDFS Datanode Layout

    module.exports = header: 'HDFS NN layout', timeout: -1, handler: (options) ->
      {user, group, hdfs, hadoop_group} = @config.ryba

## Wait

Wait for the DataNodes and NameNodes to be started.

      @call once: true, 'ryba/hadoop/hdfs_dn/wait'
      @call once: true, 'ryba/hadoop/hdfs_nn/wait'

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

      @call header: 'HDFS layout', timeout: -1, handler: (opts)->
        @wait_execute
          cmd: mkcmd.hdfs @, "hdfs --config '#{hdfs.nn.conf_dir}' dfs -test -d /"
        @system.execute
          cmd: mkcmd.hdfs @, """
          hdfs --config '#{hdfs.nn.conf_dir}' dfs -chmod 755 /
          """
        @system.execute
          cmd: mkcmd.hdfs @, """
          if hdfs --config '#{hdfs.nn.conf_dir}' dfs -test -d /tmp; then exit 2; fi
          hdfs --config '#{hdfs.nn.conf_dir}' dfs -mkdir /tmp
          hdfs --config '#{hdfs.nn.conf_dir}' dfs -chown #{hdfs.user.name}:#{hadoop_group.name} /tmp
          hdfs --config '#{hdfs.nn.conf_dir}' dfs -chmod 1777 /tmp
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          options.log? 'Directory "/tmp" prepared' if executed
        @system.execute
          cmd: mkcmd.hdfs @, """
          if hdfs --config '#{hdfs.nn.conf_dir}' dfs -test -d /user; then exit 2; fi
          hdfs --config '#{hdfs.nn.conf_dir}' dfs -mkdir /user
          hdfs --config '#{hdfs.nn.conf_dir}' dfs -chown #{hdfs.user.name}:#{hadoop_group.name} /user
          hdfs --config '#{hdfs.nn.conf_dir}' dfs -chmod 755 /user
          hdfs --config '#{hdfs.nn.conf_dir}' dfs -mkdir /user/#{hdfs.user.name}
          hdfs --config '#{hdfs.nn.conf_dir}' dfs -chown #{hdfs.user.name}:#{hadoop_group.name} /user/#{hdfs.user.name}
          hdfs --config '#{hdfs.nn.conf_dir}' dfs -chmod 755 /user/#{hdfs.user.name}
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          options.log? 'Directory "/user" prepared' if executed
        @system.execute
          cmd: mkcmd.hdfs @, """
          if hdfs --config '#{hdfs.nn.conf_dir}' dfs -test -d /apps; then exit 2; fi
          hdfs --config '#{hdfs.nn.conf_dir}' dfs -mkdir /apps
          hdfs --config '#{hdfs.nn.conf_dir}' dfs -chown #{hdfs.user.name}:#{hadoop_group.name} /apps
          hdfs --config '#{hdfs.nn.conf_dir}' dfs -chmod 755 /apps
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          options.log? 'Directory "/apps" prepared' if executed

## HDP Layout

      @system.execute
        header: 'HDP Layout'
        timeout: -1
        cmd: mkcmd.hdfs @, """
        version=`readlink /usr/hdp/current/hadoop-client | sed 's/.*\\/\\(.*\\)\\/hadoop/\\1/'`
        hdfs --config '#{hdfs.nn.conf_dir}' dfs -mkdir -p /hdp/apps/$version
        hdfs --config '#{hdfs.nn.conf_dir}' dfs -chown -R  #{hdfs.user.name}:#{hadoop_group.name} /hdp
        hdfs --config '#{hdfs.nn.conf_dir}' dfs -chmod 555 /hdp
        hdfs --config '#{hdfs.nn.conf_dir}' dfs -chmod 555 /hdp/apps
        hdfs --config '#{hdfs.nn.conf_dir}' dfs -chmod -R 555 /hdp/apps/$version
        """
        trap: true
        unless_exec: mkcmd.hdfs @, """
        version=`readlink /usr/hdp/current/hadoop-client | sed 's/.*\\/\\(.*\\)\\/hadoop/\\1/'`
        hdfs --config '#{hdfs.nn.conf_dir}' dfs -test -d /hdp/apps/$version
        """

## Test User

Create a Unix and Kerberos test user, by default "test" and execute simple HDFS commands to ensure
the NameNode is properly working. Note, those commands are NameNode specific, meaning they only
afect HDFS metadata.

      @system.execute
        header: 'User Test'
        cmd: mkcmd.hdfs @, """
        if hdfs --config '#{hdfs.nn.conf_dir}' dfs -test -d /user/#{user.name}; then exit 2; fi
        hdfs --config '#{hdfs.nn.conf_dir}' dfs -mkdir /user/#{user.name}
        hdfs --config '#{hdfs.nn.conf_dir}' dfs -chown #{user.name}:#{group.name} /user/#{user.name}
        hdfs --config '#{hdfs.nn.conf_dir}' dfs -chmod 750 /user/#{user.name}
        """
        code_skipped: 2

## Dependencies

    mkcmd = require '../../lib/mkcmd'
