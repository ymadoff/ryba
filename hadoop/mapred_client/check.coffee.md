
# MapReduce Client Check

    module.exports = header: 'MapReduce Client # Check', label_true: 'CHECKED', handler: ->
      {shortname} = @config
      {force_check} = @config.ryba

## Wait

Wait for the MapReduce History Server as well as all YARN services to be 
started.

      @call once: true, 'ryba/hadoop/mapred_jhs/wait'
      @call once: true, 'ryba/hadoop/yarn_ts/wait'
      @call once: true, 'ryba/hadoop/yarn_nm/wait'
      @call once: true, 'ryba/hadoop/yarn_rm/wait'

## Check

Run the "teragen" and "terasort" hadoop examples. Will only
be executed if the directory "/user/test/10gsort" generated
by this action is not present on HDFS. Delete this directory
to re-execute the check.

      # 100 records = 1Ko
      # 10 000 000 000 = 100 Go
      @execute
        header: 'Check'
        cmd: mkcmd.test @, """
        hdfs dfs -rm -r check-#{shortname}-mapred || true
        hdfs dfs -mkdir -p check-#{shortname}-mapred
        hadoop jar /usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-examples-2*.jar teragen 100 check-#{shortname}-mapred/input
        hadoop jar /usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-examples-2*.jar terasort check-#{shortname}-mapred/input check-#{shortname}-mapred/output
        """
        unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -d check-#{shortname}-mapred/output"
        trap: true

## Dependencies

    mkcmd = require '../../lib/mkcmd'
