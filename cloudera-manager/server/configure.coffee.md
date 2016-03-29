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


    module.exports = handler: ->
      cloudera_manager = @config.ryba.cloudera_manager ?= {}
      server = @config.ryba.cloudera_manager.server ?= {}
      server.admin_port ?= '7182'
      server.ui_port ?= '7180'
      server.db ?= {}
      server.db.type ?= 'mysql'
      server.db.main_account ?= {}
      server.db.main_account.user ?= "cloudera"
      server.db.main_account.password ?= "cloudera123"
      server.db.main_account.db_name ?= "cloudera"
      server.db.accounts ?= {}
