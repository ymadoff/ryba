
# HDFS Client Check

Check the access to the HDFS cluster.

    mkcmd = require './lib/mkcmd'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./hdfs_client').configure ctx

    module.exports.push name: 'HDP HDFS Client # Check', timeout: -1, callback: (ctx, next) ->
      {hadoop_conf_dir, hdfs_site, test_user} = ctx.config.hdp
      ctx.waitForExecution mkcmd.test(ctx, "hdfs dfs -test -d /user/#{test_user.name}"), (err) ->
        return next err if err
        ctx.execute
          cmd: mkcmd.test ctx, """
          if hdfs dfs -test -f /user/#{test_user.name}/#{ctx.config.host}-hdfs; then exit 2; fi
          hdfs dfs -touchz /user/#{test_user.name}/#{ctx.config.host}-hdfs
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          next err, if executed then ctx.OK else ctx.PASS