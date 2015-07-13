# Apache Zeppelin

    module.exports = []

## Configuring Global variables

    module.exports.configure = (ctx) ->
      require('../hadoop/core').configure ctx
      zeppelin = ctx.config.ryba.zeppelin ?= {}
      zeppelin.repository = 'https://github.com/apache/incubator-zeppelin.git'
      zeppelin.source = "#{__dirname}/../resources/zeppelin-build.tar.gz"
      zeppelin.destination = '/var/lib/zeppelin'
      zeppelin.conf_dir = '/var/lib/zeppelin/conf'
      #Set to true if you want to deploy from build 
      #in this case zeppelin.source is required
      zeppelin.build ?= {}
      zeppelin.build.name ?= 'ryba/zeppelin-build'
      zeppelin.build.execute ?= true
      zeppelin.build.dockerfile ?= "#{__dirname}/../resources/zeppelin/Dockerfile"
      zeppelin.build.directory ?= '/tmp/ryba/zeppelin-build/'
      zeppelin.build.local ?= false
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
      hadoop_conf_dir = ctx.config.ryba.hadoop_conf_dir ?= 'undefined'
      zeppelin.env ?= {}
      zeppelin.env['HADOOP_CONF_DIR'] = if hadoop_conf_dir? then hadoop_conf_dir else throw new Error 'Need Hadoop core installed'
      zeppelin.env['ZEPPELIN_LOG_DIR'] ?= '/var/log/zeppelin'
      zeppelin.env['ZEPPELIN_PID_DIR'] ?= '/var/run/zeppelin'
      zeppelin.env['ZEPPELIN_PORT'] ?= zeppelin.site['zeppelin.server.port']
      zeppelin.env['ZEPPELIN_INTERPRETER_DIR'] ?= 'interpreter'

    module.exports.push commands: 'prepare', modules:  'ryba/zeppelin/prepare'

    module.exports.push commands: 'install', modules: [
      # 'ryba/zeppelin/build'
      'ryba/zeppelin/install'
    ]

      
      
      
      

      

