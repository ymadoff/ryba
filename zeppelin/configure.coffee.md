
# Zeppelin Configure

    module.exports = ->
      zeppelin = @config.ryba.zeppelin ?= {}
      zeppelin.repository = 'https://github.com/apache/incubator-zeppelin.git'
      zeppelin.source = "#{__dirname}/../resources/zeppelin-build.tar.gz"
      zeppelin.conf_dir = '/var/lib/zeppelin/conf'
      zeppelin.log_dir = '/var/log/zeppelin'
      zeppelin.build ?= {}
      zeppelin.build.cwd ?= "#{__dirname}/resources/build"
      zeppelin.build.tag ?= 'ryba/zeppelin-build'
      zeppelin.prod ?= {}
      zeppelin.prod.cwd ?= "#{__dirname}/resources/prod"
      zeppelin.prod.tag ?= 'ryba/zeppelin:0.1'
      zeppelin.site ?= {}
      zeppelin.site['zeppelin.server.addr'] ?= '0.0.0.0'
      zeppelin.site['zeppelin.server.port'] ?= '9090'
      zeppelin.site['zeppelin.notebook.dir'] ?= '/var/lib/zeppelin/notebook'
      zeppelin.site['zeppelin.websocket.addr'] ?= '0.0.0.0'
      #If the port value is negative, then it'll default to the server port + 1
      zeppelin.site['zeppelin.websocket.port'] ?= '-1'
      zeppelin.site['zeppelin.notebook.storage'] ?= 'org.apache.zeppelin.notebook.repo.VFSNotebookRepo'
      zeppelin.site['zeppelin.interpreter.dir'] ?= 'interpreter'
      #list of interpreters, the first is the default 
      zeppelin.site['zeppelin.interpreters'] ?= [
        'org.apache.zeppelin.spark.SparkInterpreter'
        'org.apache.zeppelin.spark.PySparkInterpreter'
        'org.apache.zeppelin.spark.SparkSqlInterpreter'
        'org.apache.zeppelin.spark.DepInterpreter'
        'org.apache.zeppelin.markdown.Markdown'
        'org.apache.zeppelin.angular.AngularInterpreter'
        'org.apache.zeppelin.shell.ShellInterpreter'
        'org.apache.zeppelin.hive.HiveInterpreter'
        'org.apache.zeppelin.tajo.TajoInterpreter'
        'org.apache.zeppelin.flink.FlinkInterpreter'
        'org.apache.zeppelin.lens.LensInterpreter'
        'org.apache.zeppelin.ignite.IgniteInterprete'
        'org.apache.zeppelin.ignite.IgniteSqlInterpreter'
      ]
      zeppelin.site['zeppelin.interpreter.connect.timeout'] ?= '30000'
      #for now ryba does not install zepplin with SSL
      #putting properties for further installation
      #will be made soon
      zeppelin.site['zeppelin.ssl'] ?= 'false'
      zeppelin.site['zeppelin.ssl.client.auth'] ?= 'false'
      zeppelin.site['zeppelin.ssl.keystore.path'] ?= 'keystore'
      zeppelin.site['zeppelin.ssl.keystore.type'] ?= 'JKS'
      zeppelin.site['zeppelin.ssl.keystore.password'] ?= 'password'
      zeppelin.site['zeppelin.ssl.key.manager.password'] ?= 'password'
      zeppelin.site['zeppelin.ssl.truststore.path'] ?= 'truststore'
      zeppelin.site['zeppelin.ssl.truststore.type'] ?= 'JKS'
      zeppelin.site['zeppelin.ssl.truststore.password'] ?= 'password'
      hadoop_conf_dir = @config.ryba.hadoop_conf_dir ?= 'undefined'
      zeppelin.env ?= {}
      zeppelin.env['HADOOP_CONF_DIR'] = if hadoop_conf_dir? then hadoop_conf_dir else throw new Error 'Need Hadoop core installed'
      zeppelin.env['ZEPPELIN_LOG_DIR'] ?= '/var/log/zeppelin'
      zeppelin.env['ZEPPELIN_PID_DIR'] ?= '/var/run/zeppelin'
      zeppelin.env['ZEPPELIN_PORT'] ?= zeppelin.site['zeppelin.server.port']
      zeppelin.env['ZEPPELIN_INTERPRETER_DIR'] ?= 'interpreter'
      zeppelin.env['MASTER'] ?= 'yarn-client'
      zeppelin.env['ZEPPELIN_SPARK_USEHIVECONTEXT'] ?= 'false'
      zeppelin.env['SPARK_HOME'] ?= '/usr/hdp/current/spark-client'
      zeppelin.env['ZEPPELIN_JAVA_OPTS'] ?= '-Dhdp.version=2.3.0.0-2557'
      #zeppelin.env['SPARK_YARN_JAR'] ?= 'file:///var/lib/zeppelin/interpreter/spark/zeppelin-spark-0.6.0-incubating-SNAPSHOT.jar'
      # zeppelin.env['SPARK_YARN_JAR'] ?= 'hdfs:///user/spark/share/lib/spark-assembly-1.3.1.2.3.0.0-2557-hadoop2.7.1.2.3.0.0-2557.jar'
      zeppelin.env['HADOOP_HOME'] ?= '/usr/hdp/current/hadoop-client'
