# Cloudera Manager Server

[Cloudera Manager Server][Cloudera-server-install] is the master host for the
cloudera manager software.
Once logged into the cloudera manager server host, the administrator can
provision, manage and monitor a Hadoop cluster.
You must have configured yum to use the [cloudera manager repo][Cloudera-manager-repo]
or the [cloudera cdh repo][Cloudera-cdh-repo].


    module.exports = []

## Configuration

Example:

```json
cloudera_manager:
  # name: 'big'
  # username: process.env['HADOOP_USERNAME']
  # password: process.env['HADOOP_PASSWORD']
  server:
    db:
      type: 'mysql'
      host: 'localhost'
      port: 3306
      root_password: ''
      main_account: # Cloudera manager account
        user: 'cloudera'
        password: 'cloudera123'
        db_name: 'cloudera'
      accounts: # accounts for hadoop services
        account:
          user: '...'
          password: '..'
          db_name: '...'
```


    module.exports.configure = (ctx) ->
      require('../../lib/base').configure ctx
      cloudera_manager = ctx.config.ryba.cloudera_manager ?= {}
      server = ctx.config.ryba.cloudera_manager.server ?= {}
      server.port ?= '7182'
      server.db ?= {}
      server.db.type ?= 'mysql'
      server.db.main_account ?= {}
      server.db.main_account.user ?= "cloudera"
      server.db.main_account.password ?= "cloudera123"
      server.db.main_account.db_name ?= "cloudera"
      server.db.accounts ?= {}

    module.exports.push commands: 'install', modules: [
      'ryba/cloudera-manager/server/install'
      # 'ryba/cloudera-manager/server/start'
    ]

    module.exports.push commands: 'start', modules: 'ryba/cloudera-manager/server/start'

    module.exports.push commands: 'stop', modules: 'ryba/cloudera-manager/server/stop'

[Cloudera-server-install]: http://www.cloudera.com/content/www/en-us/documentation/enterprise/5-2-x/topics/cm_ig_install_path_b.html#cmig_topic_6_6_4_unique_1
[Cloudera-manager-repo]: http://archive.cloudera.com/cm5/redhat/6/x86_64/cm/cloudera-manager.repo
[Cloudera-cdh-repo]: http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/cloudera-cdh5.repo
