
# Cloudera Manager Server Configuration

Example:

```json
{ "ryba": { "cloudera_manager": { "server":
    "db": {
      "type": "mysql",
      "host": "localhost",
      "port": "3306",
      "root_password": '',
      "main_account": {
        "user": "cloudera",
        "password": "cloudera123",
        "db_name": "cloudera"
      },
      "accounts": [
        {
          "user": "...",
          "password": "...",
          "db_name": "..."
        }
      ]
    }
} } }
```

    module.exports = ->
      cloudera_manager = @config.ryba.cloudera_manager ?= {}
      cloudera_manager.server ?= {}
      cloudera_manager.server.admin_port ?= '7182'
      cloudera_manager.server.ui_port ?= '7180'
      cloudera_manager.server.db ?= {}
      cloudera_manager.server.db.type ?= 'mysql'
      cloudera_manager.server.db.main_account ?= {}
      cloudera_manager.server.db.main_account.user ?= "cloudera"
      cloudera_manager.server.db.main_account.password ?= "cloudera123"
      cloudera_manager.server.db.main_account.db_name ?= "cloudera"
      cloudera_manager.server.db.accounts ?= {}
