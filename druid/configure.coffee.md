
# Druid Configure

Example:

```json
{
  "ryba": {
    "druid": "version": "0.9.1.1"
  }
}
```

    module.exports  = handler: ->
      @config.ryba ?= {}
      druid = @config.ryba.druid ?= {}
      # Layout
      druid.dir ?= '/opt/druid'
      druid.conf_dir ?= '/etc/druid/conf'
      druid.log_dir ?= '/var/log/druid'
      druid.pid_dir ?= '/var/run/druid'
      druid.server_opts ?= ''
      druid.server_heap ?= ''
      # User
      druid.user = name: druid.user if typeof druid.user is 'string'
      druid.user ?= {}
      druid.user.name ?= 'druid'
      druid.user.system ?= true
      druid.user.comment ?= 'druid User'
      druid.user.home ?= '/var/lib/druid'
      druid.user.groups ?= ['hadoop']
      # Group
      druid.group = name: druid.group if typeof druid.group is 'string'
      druid.group ?= {}
      druid.group.name ?= 'druid'
      druid.group.system ?= true
      druid.user.gid = druid.group.name
      # Package
      druid.version ?= '0.9.1.1'
      druid.source ?= "http://static.druid.io/artifacts/releases/druid-#{druid.version}-bin.tar.gz"
