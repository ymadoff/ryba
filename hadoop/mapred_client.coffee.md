
# Hadoop MapRed Client

    module.exports = []

    module.exports.configure = (ctx) ->
      return if ctx.mapred_configured
      ctx.mapred_configured = true
      require('./hdfs').configure ctx
      require('./yarn').configure ctx
      {static_host, realm, mapred} = ctx.config.ryba
      # Layout
      mapred.pid_dir ?= '/var/run/hadoop-mapreduce'  # /etc/hadoop/conf/hadoop-env.sh#94
      # Configuration
      mapred.site['mapreduce.job.counters.max'] ?= 120
      mapred.site['mapreduce.reduce.shuffle.parallelcopies'] ?= '50' #  Higher number of parallel copies run by reduces to fetch outputs from very large number of maps.
      # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.6.0/bk_installing_manually_book/content/rpm_chap3.html
      # Optional: Configure MapReduce to use Snappy Compression
      # Complement core-site.xml configuration
      mapred.site['mapreduce.admin.map.child.java.opts'] ?= "-server -XX:NewRatio=8 -Djava.library.path=/usr/lib/hadoop/lib/native/ -Djava.net.preferIPv4Stack=true"
      mapred.site['mapreduce.admin.reduce.child.java.opts'] ?= "-server -XX:NewRatio=8 -Djava.library.path=/usr/lib/hadoop/lib/native/ -Djava.net.preferIPv4Stack=true"
      # [Configurations for MapReduce JobHistory Server](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Configuring_the_Hadoop_Daemons_in_Non-Secure_Mode)
      [jhs_context] = ctx.contexts 'ryba/hadoop/mapred_jhs', require('./mapred_jhs').configure
      if jhs_context
        mapred.site['mapreduce.jobhistory.address'] ?= jhs_context.config.ryba.mapred.site['mapreduce.jobhistory.address']
        mapred.site['mapreduce.jobhistory.webapp.address'] ?= jhs_context.config.ryba.mapred.site['mapreduce.jobhistory.webapp.address']
        mapred.site['mapreduce.jobhistory.webapp.https.address'] ?= jhs_context.config.ryba.mapred.site['mapreduce.jobhistory.webapp.https.address']
        mapred.site['mapreduce.jobhistory.done-dir'] ?= jhs_context.config.ryba.mapred.site['mapreduce.jobhistory.done-dir']
        mapred.site['mapreduce.jobhistory.intermediate-done-dir'] ?= jhs_context.config.ryba.mapred.site['mapreduce.jobhistory.intermediate-done-dir']
        # Important, JHS principal must be deployed on all mapreduce workers
        mapred.site['mapreduce.jobhistory.principal'] ?= "jhs/#{jhs_context.config.host}@#{realm}"
      # The value is set by the client app and the iptables are enforced on the worker nodes
      mapred.site['yarn.app.mapreduce.am.job.client.port-range'] ?= '59100-59200'
      mapred.site['mapreduce.framework.name'] ?= 'yarn' # Execution framework set to Hadoop YARN.
      # Deprecated properties
      mapred.site['mapreduce.cluster.local.dir'] = null # Now "yarn.nodemanager.local-dirs"
      mapred.site['mapreduce.jobtracker.system.dir'] = null # JobTracker no longer used

    module.exports.push commands: 'check', modules: 'ryba/hadoop/mapred_client_check'

    module.exports.push commands: 'info', modules: 'ryba/hadoop/mapred_client_info'

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/mapred_client_install'
      'ryba/hadoop/mapred_client_check'
    ]




