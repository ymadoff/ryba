
# Livy Configure

Configure Spark Livy Server and integrates it with the other components deployed by Ryba.

    module.exports = ->
      {hadoop_conf_dir, core_site,realm} = @config.ryba
      {spark} = @config.ryba ?= {}
      # User
      spark.user ?= {}
      spark.user = name: spark.user if typeof spark.user is 'string'
      spark.user.name ?= 'spark'
      spark.user.system ?= true
      spark.user.comment ?= 'Spark User'
      spark.user.home ?= '/var/lib/spark'
      spark.user.groups ?= 'hadoop'
      # Group
      spark.group ?= {}
      spark.group = name: spark.group if typeof spark.group is 'string'
      spark.group.name ?= 'spark'
      spark.group.system ?= true
      spark.user.gid ?= spark.group.name

## General

      livy = @config.ryba.spark.livy ?= {}
      # Layout
      livy.conf_dir ?= '/etc/spark-livy/conf'
      livy.log_dir ?= '/var/log/spark'
      livy.pid_dir ?= '/var/run/spark'
      # Production container image name
      livy.version ?= '0.2'
      livy.image ?= 'ryba/livy'
      livy.container ?= 'spark_livy_server'
      # Huedocker service name has to match nagios hue_docker_check_status.sh file in ryba/nagios/resources/plugins
      livy.service ?= 'spark-livy-server'
      livy.build ?= {}
      livy.build.source ?= 'https://github.com/cloudera/livy.git'
      livy.build.name ?= 'ryba/livy'
      livy.build.version ?= 'latest'
      livy.build.dockerfile ?= "#{__dirname}/../resources/Dockerfile"
      livy.build.directory ?= "#{@config.nikita.cache_dir}/spark_livy_server/cache/build" # was '/tmp/ryba/hue-build'
      livy.build.tar ?= 'spark_livy_server.tar'
      livy.image_dir ?= '/tmp'

## SSL 

      livy.ssl_enabled ?= true
      livy.port ?= if livy.ssl_enabled then '8890' else '8889'
      livy.keystore ?= "#{livy.conf_dir}/keystore"
      livy.keystorePassword ?= 'livy123'

## Configuration
      
      livy.conf ?= {}
      livy.conf['livy.server.host'] ?= @config.host  
      livy.conf['livy.server.port'] ?= livy.port
      livy.conf['livy.keystore'] ?= livy.keystore
      livy.conf['livy.keystore.password'] ?= livy.keystorePassword
      # Time in milliseconds on how long Livy will wait before timing out an idle session.
      livy.conf['livy.server.session.timeout'] ?= '1h'
      # If livy should impersonate the requesting users when creating a new session.
      livy.conf['livy.impersonation.enabled'] ?= 'true'

## Kerberos && ACLs

      if @config.ryba.security is 'kerberos'
        livy.conf['livy.server.auth.type'] ?= 'kerberos'
        livy.conf['livy.server.auth.kerberos.principal'] ?= "#{spark.user.name}/#{@config.host}@#{realm}"
        livy.conf['livy.server.auth.kerberos.keytab'] ?= '/etc/security/keytabs/spark.service.keytab'
        livy.conf['livy.server.auth.kerberos.name_rules'] ?= "#{core_site['hadoop.security.auth_to_local']}"
        # Acl
        livy.conf['livy.server.access_control.enabled'] ?= 'true'

## Environment
      
      # Available properties
      # - JAVA_HOME       Java runtime to use. By default use "java" from PATH.
      # - HADOOP_CONF_DIR Directory containing the Hadoop / YARN configuration to use.
      # - SPARK_HOME      Spark which you would like to use in Livy.
      # - SPARK_CONF_DIR  Optional directory where the Spark configuration lives.
      # - LIVY_LOG_DIR    Where log files are stored. (Default: ${LIVY_HOME}/logs)
      # - LIVY_PID_DIR    Where the pid file is stored
      # - LIVY_SERVER_JAVA_OPTS  Java Opts for running livy server 
      # - LIVY_IDENT_STRING A name that identifies the Livy server instance, used to generate log file
      # - LIVY_MAX_LOG_FILES Max number of log file to keep in the log directory. (Default: 5.)
      # - LIVY_NICENESS   Niceness of the Livy server process when running in the background. (Default: 0.)
      livy.env ?= {}
      livy.env['HADOOP_CONF_DIR'] ?= "#{hadoop_conf_dir}"
      livy.env['SPARK_HOME'] ?= '/usr/hdp/current/spark-client'
      livy.env['SPARK_CONF_DIR'] ?= '/etc/spark/conf'
      livy.env['LIVY_IDENT_STRING'] ?= "#{livy.service}-docker"
      livy.env['LIVY_LOG_DIR'] ?= "#{spark.livy.log_dir}"
      livy.env['LIVY_PID_DIR'] ?= "#{spark.livy.pid_dir}"
