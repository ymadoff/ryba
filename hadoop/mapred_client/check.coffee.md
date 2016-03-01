
# MapReduce Client Check

    module.exports = header: 'MapReduce Client # Check', label_true: 'CHECKED', handler: ->
      {shortname} = @config
      {force_check} = @config.ryba
    
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
        trap_on_error: true

      @execute
        header: 'Uploaded files'
        # Referenced by "mapred_site['mapreduce.application.classpath']"
        cmd: '[ -f /usr/hdp/current/share/lzo/0.6.0/lib/hadoop-lzo-0.6.0.jar ]'

## Dependencies

    mkcmd = require '../../lib/mkcmd'
