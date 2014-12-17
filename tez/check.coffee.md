
# Tez Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Check HDFS

    module.exports.push name: 'Tez # Check HDFS', timeout: -1, label_true: 'CHECKED', label_false: 'SKIPPED', callback: (ctx, next) ->
      {force_check, test_user} = ctx.config.ryba
      local_text = "#{test_user.home}/check-#{ctx.config.shortname}-tez-hdfs/test.txt"
      remote_dir = "check-#{ctx.config.shortname}-tez-hdfs"
      ctx.write
        destination: "#{local_text}"
        content: "foo\nbar\nfoo\nbar\nfoo"
      , (err, written) ->
        ctx.execute
          cmd: mkcmd.test ctx, """
          hdfs dfs -rm -r -skipTrash #{remote_dir} 2>/dev/null
          hdfs dfs -mkdir #{remote_dir}
          hadoop fs -put #{local_text} #{remote_dir}/test.txt
          hadoop jar /usr/lib/tez/tez-mapreduce-examples-*.jar orderedwordcount #{remote_dir}/test.txt #{remote_dir}/output
          hadoop fs -cat #{remote_dir}/output/*
          """
          not_if_exec: unless force_check then mkcmd.test ctx, "hdfs dfs -test -d #{remote_dir}"
        , (err, executed, stdout) ->
          next err, stdout?.trim().split('\n').slice(-2).join('\n') is 'bar\t2\nfoo\t3'

## Dependencies

    mkcmd = require '../lib/mkcmd'
      

