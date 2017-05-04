
# MapReduce Client Check

    module.exports = header: 'MapReduce Client Check', label_true: 'CHECKED', handler: ->
      {shortname} = @config
      {force_check, user} = @config.ryba

## Wait

Wait for the MapReduce History Server as well as all YARN services to be 
started.

      @call once: true, 'ryba/hadoop/mapred_jhs/wait'
      @call once: true, 'ryba/hadoop/yarn_ts/wait'
      @call once: true, 'ryba/hadoop/yarn_nm/wait'
      @call once: true, 'ryba/hadoop/yarn_rm/wait'

## Check Distributed Shell

The distributed shell is a yarn client application which submit a command or a
Shell script to be executed inside one or multiple YARN containers.

      # Note: should be moved to mapred since it requires mapred-site with memory settings
      @call header: 'Distributed Shell', timeout: -1, label_true: 'CHECKED', handler: ->
        appname = "ryba_check_#{shortname}_distributed_cache_#{Date.now()}"
        scriptpath = "#{user.home}/check_distributed_shell.sh"
        @file
          target: "#{scriptpath}"
          content: """
          #!/usr/bin/env bash
          echo Ryba Ryba NM hostname: `hostname`
          """
          mode: 0o0640
        @system.execute
          cmd: mkcmd.test @, """
          yarn org.apache.hadoop.yarn.applications.distributedshell.Client \
            -jar /usr/hdp/current/hadoop-yarn-client/hadoop-yarn-applications-distributedshell.jar \
            -shell_script #{scriptpath} \
            -appname #{appname} \
            -num_containers 1
          # Valid states: ALL, NEW, NEW_SAVING, SUBMITTED, ACCEPTED, RUNNING, FINISHED, FAILED, KILLED 
          # Wait for application to run
          done_cmd="yarn application -list -appStates ALL | grep #{appname} | egrep 'FINISHED|FAILED|KILLED'"
          i=0; while [[ $i -lt 1000 ]] && [[ ! `$done_cmd` ]]; do ((i++)); sleep 1; done
          # Get application id
          application=`yarn application -list -appStates ALL | grep #{appname} | sed -e 's/^\\(application_[0-9_]\\+\\).*/\\1/'`
          if [ ! "$application" ]; then exit 1; fi
          rm=`yarn logs -applicationId $application 2>/dev/null | grep 'Ryba NM hostname' | sed 's/Ryba NM hostname: \\(.*\\)/\\1/'`
          [ "$rm" ]
          """
          unless_exists: unless force_check then scriptpath

## Check

Run the "teragen" and "terasort" hadoop examples. Will only
be executed if the directory "/user/test/10gsort" generated
by this action is not present on HDFS. Delete this directory
to re-execute the check.

      # 100 records = 1Ko
      # 10 000 000 000 = 100 Go
      @system.execute
        header: 'Teragen & Terasort'
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
