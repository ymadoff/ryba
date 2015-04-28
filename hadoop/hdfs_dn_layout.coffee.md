

## HDFS layout

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs'
    module.exports.push require('./hdfs').configure
    module.exports.push 'ryba/hadoop/hdfs_dn_wait'
    module.exports.push 'ryba/hadoop/hdfs_nn_wait'

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

    module.exports.push name: 'HDFS DN # HDFS layout', timeout: -1, handler: (ctx, next) ->
      {hdfs, hadoop_group} = ctx.config.ryba
      modified = false
      do_wait = ->
        ctx.waitForExecution mkcmd.hdfs(ctx, "hdfs dfs -test -d /"), (err) ->
          return next err if err
          do_root()
      do_root = ->
        ctx.execute
          cmd: mkcmd.hdfs ctx, """
          hdfs dfs -chmod 755 /
          """
        , (err, executed, stdout) ->
          return next err if err
          do_tmp()
      do_tmp = ->
        ctx.execute
          cmd: mkcmd.hdfs ctx, """
          if hdfs dfs -test -d /tmp; then exit 2; fi
          hdfs dfs -mkdir /tmp
          hdfs dfs -chown #{hdfs.user.name}:#{hadoop_group.name} /tmp
          hdfs dfs -chmod 1777 /tmp
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          return next err if err
          ctx.log 'Directory "/tmp" prepared' and modified = true if executed
          do_user()
      do_user = ->
        ctx.execute
          cmd: mkcmd.hdfs ctx, """
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
          return next err if err
          ctx.log 'Directory "/user" prepared' and modified = true if executed
          do_apps()
      do_apps = ->
        ctx.execute
          cmd: mkcmd.hdfs ctx, """
          if hdfs dfs -test -d /apps; then exit 2; fi
          hdfs dfs -mkdir /apps
          hdfs dfs -chown #{hdfs.user.name}:#{hadoop_group.name} /apps
          hdfs dfs -chmod 755 /apps
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          return next err if err
          ctx.log 'Directory "/apps" prepared' and modified = true if executed
          do_end()
      do_end = ->
        next null, modified
      do_wait()

## HDP Layout

    module.exports.push name: 'MapRed Client # HDP Layout', timeout: -1, handler: (ctx, next) ->
      {hdfs, hadoop_group} = ctx.config.ryba
      ctx.execute
        cmd: mkcmd.hdfs ctx, """
        version=`readlink /usr/hdp/current/hadoop-client | sed 's/.*\\/\\(.*\\)\\/hadoop/\\1/'`
        hdfs dfs -mkdir -p /hdp/apps/$version
        hdfs dfs -chown -R  #{hdfs.user.name}:#{hadoop_group.name} /hdp
        hdfs dfs -chmod 555 /hdp
        hdfs dfs -chmod 555 /hdp/apps
        hdfs dfs -chmod -R 555 /hdp/apps/$version
        """
        trap_on_error: true
        not_if_exec: mkcmd.hdfs ctx, """
        version=`readlink /usr/hdp/current/hadoop-client | sed 's/.*\\/\\(.*\\)\\/hadoop/\\1/'`
        hdfs dfs -test -d /hdp/apps/$version
        """
      , next

## Test User

Create a Unix and Kerberos test user, by default "test" and execute simple HDFS commands to ensure
the NameNode is properly working. Note, those commands are NameNode specific, meaning they only
afect HDFS metadata.

    module.exports.push name: 'HDFS DN # HDFS Layout User Test', timeout: -1, handler: (ctx, next) ->
      {user,group} = ctx.config.ryba
      ctx.execute
        cmd: mkcmd.hdfs ctx, """
        if hdfs dfs -test -d /user/#{user.name}; then exit 2; fi
        hdfs dfs -mkdir /user/#{user.name}
        hdfs dfs -chown #{user.name}:#{group.name} /user/#{user.name}
        hdfs dfs -chmod 750 /user/#{user.name}
        """
        code_skipped: 2
      , next

## Module dependencies

    mkcmd = require '../lib/mkcmd'
