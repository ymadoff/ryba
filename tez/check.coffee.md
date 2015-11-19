
# Tez Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Check HDFS

    module.exports.push header: 'Tez # Check HDFS', timeout: -1, label_true: 'CHECKED', handler: ->
      {force_check, user} = @config.ryba
      remote_dir = "check-#{@config.shortname}-tez-hdfs"
      @execute
        cmd: mkcmd.test @, """
        hdfs dfs -rm -r -skipTrash #{remote_dir} 2>/dev/null
        hdfs dfs -mkdir #{remote_dir}
        echo -e 'foo\\nbar\\nfoo\\nbar\\nfoo' | hadoop fs -put - #{remote_dir}/test.txt
        hadoop jar /usr/hdp/current/tez-client/tez-examples-*.jar orderedwordcount #{remote_dir}/test.txt #{remote_dir}/output
        hadoop fs -cat #{remote_dir}/output/*
        """
        unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -d #{remote_dir}/output"
      , (err, executed, stdout) ->
        throw Error "Invalid output" if executed and stdout?.trim().split('\n').slice(-2).join('\n') isnt 'bar\t2\nfoo\t3'

## Dependencies

    mkcmd = require '../lib/mkcmd'
      
