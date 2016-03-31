
# Spark History Server

    module.exports = handler: ->
      {realm, core_site} = @config.ryba
      spark = @config.ryba.spark ?= {}
      # Layout
      spark.pid_dir ?= '/var/run/spark'
      spark.conf_dir ?= '/etc/spark/conf'
      spark.log_dir ?= '/var/log/spark'
      
      # https://spark.apache.org/docs/latest/monitoring.html
      spark.conf ?= {}
      spark.conf['spark.history.provider'] ?= 'org.apache.spark.deploy.history.FsHistoryProvider'
      spark.conf['spark.history.fs.update.interval'] ?= '10s'
      spark.conf['spark.history.retainedApplications'] ?= '50'
      spark.conf['spark.history.ui.port'] ?= '18080'
      spark.conf['spark.history.kerberos.enabled'] ?= if core_site['hadoop.http.authentication.type'] is 'kerberos' then 'true' else 'false'
      spark.conf['spark.history.kerberos.principal'] ?= "spark/#{@config.host}@#{realm}"
      spark.conf['spark.history.kerberos.keytab'] ?= '/etc/security/keytabs/spark.keytab'
      spark.conf['spark.history.ui.acls.enable'] ?= ''
      spark.conf['spark.history.fs.cleaner.enabled'] ?= 'false'
