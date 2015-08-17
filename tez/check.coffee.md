
# Tez Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Check HDFS

    module.exports.push name: 'Tez # Check HDFS', timeout: -1, label_true: 'CHECKED', handler: (ctx, next) ->
      {force_check, user} = ctx.config.ryba
      local_text = "#{user.home}/check-#{ctx.config.shortname}-tez-hdfs"
      remote_dir = "check-#{ctx.config.shortname}-tez-hdfs"
      ctx.execute
        cmd: mkcmd.test ctx, """
        echo -e 'foo\\nbar\\nfoo\\nbar\\nfoo' > #{local_text}
        hdfs dfs -rm -r -skipTrash #{remote_dir} 2>/dev/null
        hdfs dfs -mkdir #{remote_dir}
        hadoop fs -put #{local_text} #{remote_dir}/test.txt
        hadoop jar /usr/hdp/current/tez-client/tez-examples-*.jar orderedwordcount #{remote_dir}/test.txt #{remote_dir}/output
        hadoop fs -cat #{remote_dir}/output/*
        """
        not_if_exec: unless force_check then mkcmd.test ctx, "hdfs dfs -test -d #{remote_dir}/output"
      , (err, executed, stdout) ->
        throw Error "Invalid output" if executed and stdout?.trim().split('\n').slice(-2).join('\n') isnt 'bar\t2\nfoo\t3'
      .then next

## Dependencies

    mkcmd = require '../lib/mkcmd'
      

