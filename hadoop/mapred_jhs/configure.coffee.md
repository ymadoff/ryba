
# MapReduce JobHistoryServer (JHS) Configure

    module.exports = ->
      # rm_ctxs = @contexts modules: 'ryba/hadoop/yarn_rm', require('../yarn_rm/configure').handler
      {ryba} = @config
      ryba.mapred ?= {}
      ryba.mapred.jhs ?= {}
      ryba.mapred.jhs.conf_dir ?= '/etc/hadoop-mapreduce-historyserver/conf'
      ryba.mapred.heapsize ?= '900'
      ryba.mapred.pid_dir ?= '/var/run/hadoop-mapreduce'  # /etc/hadoop/conf/hadoop-env.sh#94
      ryba.mapred.log_dir ?= '/var/log/hadoop-mapreduce' # required by hadoop-env.sh
      ryba.mapred.site ?= {}
      ryba.mapred.site['mapreduce.jobhistory.keytab'] ?= "/etc/security/keytabs/jhs.service.keytab"
      ryba.mapred.site['mapreduce.jobhistory.principal'] ?= "jhs/#{@config.host}@#{ryba.realm}"
      # Fix: src in "[DFSConfigKeys.java][keys]" and [HDP port list] mention 13562 while companion files mentions 8081
      ryba.mapred.site['mapreduce.shuffle.port'] ?= '13562'
      ryba.mapred.site['mapreduce.jobhistory.address'] ?= "#{@config.host}:10020"
      ryba.mapred.site['mapreduce.jobhistory.webapp.address'] ?= "#{@config.host}:19888"
      ryba.mapred.site['mapreduce.jobhistory.webapp.https.address'] ?= "#{@config.host}:19889"
      ryba.mapred.site['mapreduce.jobhistory.admin.address'] ?= "#{@config.host}:10033"

Note: As of version "2.4.0", the property "mapreduce.jobhistory.http.policy"
isn't honored. Instead, the property "yarn.http.policy" is used.

      # ryba.yarn.site['yarn.http.policy'] ?= rm_ctxs[0].config.ryba.yarn.site['yarn.http.policy']
      # ryba.mapred.site['mapreduce.jobhistory.http.policy'] ?= rm_ctxs[0].config.ryba.yarn.rm.site['yarn.http.policy']
      ryba.mapred.site['mapreduce.jobhistory.http.policy'] ?= 'HTTPS_ONLY'
      # See './hadoop-mapreduce-project/hadoop-mapreduce-client/hadoop-mapreduce-client-common/src/main/java/org/apache/hadoop/mapreduce/v2/jobhistory/JHAdminConfig.java#158'
      # yarn.site['mapreduce.jobhistory.webapp.spnego-principal']
      # yarn.site['mapreduce.jobhistory.webapp.spnego-keytab-file']

## Configuration for Staging Directories

The property "yarn.app.mapreduce.am.staging-dir" is an alternative to "done-dir"
and "intermediate-done-dir". According to Cloudera](): Configure 
mapreduce.jobhistory.intermediate-done-dir and mapreduce.jobhistory.done-dir in
mapred-site.xml. Create these two directories. Set permissions on
mapreduce.jobhistory.intermediate-done-dir to 1777. Set permissions on
mapreduce.jobhistory.done-dir to 750.

If "yarn.app.mapreduce.am.staging-dir" is active (if the other two are unset),
a folder history must be created and own by the mapreduce user. On startup, JHS
will create two folders:

```bash
hdfs dfs -ls /user/history
Found 2 items
drwxrwx---   - mapred hadoop          0 2015-08-04 23:21 /user/history/done
drwxrwxrwt   - mapred hadoop          0 2015-08-04 23:21 /user/history/done_intermediate
```

      ryba.mapred.site['yarn.app.mapreduce.am.staging-dir'] = "/user" # default to "/tmp/hadoop-yarn/staging"
      # ryba.mapred.site['mapreduce.jobhistory.done-dir'] ?= '/mr-history/done' # Directory where history files are managed by the MR JobHistory Server.
      # ryba.mapred.site['mapreduce.jobhistory.intermediate-done-dir'] ?= '/mr-history/tmp' # Directory where history files are written by MapReduce jobs.
      ryba.mapred.site['mapreduce.jobhistory.done-dir'] = null
      ryba.mapred.site['mapreduce.jobhistory.intermediate-done-dir'] = null


## Job Recovery

The following properties provides persistent state to the Job history server.
They are referenced by [the druid hadoop configuration][druid] and
[the Ambari 2.3 stack][amb-mr-site]. Job Recovery is activated by default.   

      ryba.mapred.site['mapreduce.jobhistory.recovery.enable'] ?= 'true'
      ryba.mapred.site['mapreduce.jobhistory.recovery.store.class'] ?= 'org.apache.hadoop.mapreduce.v2.hs.HistoryServerLeveldbStateStoreService'
      ryba.mapred.site['mapreduce.jobhistory.recovery.store.leveldb.path'] ?= '/var/mapred/jhs'
