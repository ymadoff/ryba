
## Configuration

The module extends the "ryba/hadoop/core" module configuration.

*   `hdp.sqoop.libs`, (array, string)
    List jar files (usually JDBC drivers) to upload into the Sqoop lib path.
    Use the space or comma charectere to separate the paths when the value is a
    string. This is for example used to add the Oracle JDBC driver "ojdbc6.jar"
    which cannt be downloaded for licensing reasons.
*   `sqoop_user` (object|string)
    The Unix Sqoop login name or a user object (see Nikita User documentation).

Todo, with oozie, it seems like drivers must be stored in "/user/oozie/share/lib/sqoop".

Example:

```json
{
  "ryba": {
    "sqoop": {
      "user": {
        "name": "sqoop", "system": true, "gid": "hadoop",
        "comment": "Sqoop User", "home": "/var/lib/sqoop"
      },
      "libs": "./path/to/ojdbc6.jar"
    }
  }
}
```

    module.exports = ->
      sqoop = @config.ryba.sqoop ?= {}
      # User
      sqoop.user = name: sqoop.user if typeof sqoop.user is 'string'
      sqoop.user ?= {}
      sqoop.user.name ?= 'sqoop'
      sqoop.user.system ?= true
      sqoop.user.comment ?= 'Sqoop User'
      sqoop.user.gid ?= 'hadoop'
      sqoop.user.home ?= '/var/lib/sqoop'
      # Layout
      sqoop.conf_dir ?= '/etc/sqoop/conf'
      # Configuration
      sqoop.site ?= {}
      # Libs
      sqoop.libs ?= []
      sqoop.libs = sqoop.libs.split /[\s,]+/ if typeof sqoop.libs is 'string'
