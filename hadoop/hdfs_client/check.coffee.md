
# Hadoop HDFS Client Check

Check the access to the HDFS cluster.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_dn/wait'
    module.exports.push require('./index').configure

    module.exports.push name: 'HDFS Client # Check', timeout: -1, label_true: 'CHECKED', handler: (ctx, next) ->
      {hadoop_conf_dir, hdfs, user} = ctx.config.ryba
      ctx.waitForExecution mkcmd.test(ctx, "hdfs dfs -test -d /user/#{user.name}"), (err) ->
        return next err if err
        ctx.execute
          cmd: mkcmd.test ctx, """
          if hdfs dfs -test -f /user/#{user.name}/#{ctx.config.host}-hdfs; then exit 2; fi
          hdfs dfs -touchz /user/#{user.name}/#{ctx.config.host}-hdfs
          """
          code_skipped: 2
        , next

## Module Dependencies

    mkcmd = require '../../lib/mkcmd'
