
# TinkerPop Rexster (Titan Server)
[Rexster](https://github.com/tinkerpop/rexster/wiki) is a graph server that exposes any Blueprints graph through REST and a binary protocol called RexPro.
The HTTP web service provides standard low-level GET, POST, PUT, and DELETE methods, a flexible extensions model which allows plug-in like development for external servicesan’s modular architecture allows it to interoperate with a wide range of storage, index, and client technologies; it also eases the process of extending Titan to support new ones.
server-side “stored procedures” written in Gremlin, and a browser-based interface called The Dog House. Rexster Console makes it possible to do remote script evaluation against configured graphs inside of a Rexster Server.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/titan'

## Configure

*   `admin` (string | user object)
    The login name or a user object (see Mecano User documentation).
*   `config` (object)
    Object for Rexster configuration (xml) file

Example:

```json
{
  "ryba": {
    "rexster": {
      "admin": {
        "name": "rexster"
        "password": "rexster123"
      },
      "config": {
        "http": {
          [...]
        }
      }
    }
  }
}
```

    module.exports.configure = (ctx) ->
      require('../titan').configure ctx
      {titan, realm} = ctx.config.ryba
      rexster = ctx.config.ryba.rexster ?= {}
      rexster.user ?= {}
      rexster.user = name: rexster.user if typeof rexster.user is 'string'
      rexster.user.name ?= 'rexster'
      rexster.user.system ?= true
      rexster.user.gid ?= 'rexster'
      rexster.user.comment ?= 'Rexster User'
      # Group
      rexster.group ?= {}
      rexster.group = name: rexster.group if typeof rexster.group is 'string'
      rexster.group.name ?= 'rexster'
      rexster.group.system ?= true
      # Kerberos config
      rexster.krb5_user ?= {}
      rexster.krb5_user.principal ?= "rexster/#{ctx.config.host}@#{realm}"
      rexster.krb5_user.keytab ?= '/etc/security/keytabs/rexster.service.keytab'
      # Force rexster home to titan.home/rexhome
      rexster.user.home = path.join titan.home, 'rexhome'
      rexster.admin ?= {}
      rexster.admin = name: rexster.admin if typeof rexster.admin is 'string'
      rexster.admin.name ?= 'rexster'
      rexster.admin.password ?= 'rexster123'
      rexster.log_dir ?= '/var/log/rexster'
      config = rexster.config ?= {}
      config.http ?= {}
      config.http['server-port'] ?= 8182
      config.http['server-host'] ?= '0.0.0.0'
      config.http['base-uri'] ?= "http://#{ctx.config.host}"
      config.http['web-root'] ?= 'public'
      config.http['character-set'] ?= "UTF-8"
      config.http['enable-jmx'] ?= false
      config.http['enable-doghouse'] ?= true
      config.http['max-post-size'] ?= 2097152
      config.http['max-header-size'] ?= 8192
      config.http['upload-timeout-millis'] ?= 30000
      config.http['thread-pool'] ?=
        worker:
          "core-size": 8
          "max-size": 8
        kernal:
          "core-size": 4
          "max-size": 4
      config.http['io-strategy'] ?= "leader-follower"
      config.rexpro ?= {}
      config.rexpro['server-port'] ?= 8184
      config.rexpro['server-host'] ?= '0.0.0.0'
      config.rexpro['session-max-idle'] ?= 1790000
      config.rexpro['session-check-interval'] ?= 3000000
      config.rexpro['connection-max-idle'] ?= 180000
      config.rexpro['connection-check-interval'] ?= 3000000
      config.rexpro['read-buffer'] ?= 65536
      config.rexpro['enable-jmx'] ?= false
      config.rexpro['thread-pool'] ?=
        worker:
          'core-size': 8
          'max-size': 8
        kernal:
          'core-size': 4
          'max-size': 4
      config.rexpro['io-strategy'] ?= "leader-follower"

TODO: Security see https://github.com/tinkerpop/rexster/wiki/Rexster-Security

      config['security'] ?=
        authentication:
          type: 'default'

      if config.security.authentication.type is 'default'
        config.security.authentication.configuration ?= {}
        config.security.authentication.configuration.users ?= {}
        config.security.authentication.configuration.users.user ?= []
        config.security.authentication.configuration.users.user = [config.security.authentication.configuration.users.user] unless Array.isArray config.security.authentication.configuration.users.user
        if config.security.authentication.configuration.users.user.length is 0
          config.security.authentication.configuration.users.user.push
            username: rexster.admin.name
            password: rexster.admin.password
      config['shutdown-port'] ?= 8183
      config['shutdown-host'] = "127.0.0.1"
      config['config-check-interval'] ?= 10000
      config['script-engines'] ?= [
        "script-engine":
          "name": "gremlin-groovy"
          "reset-threshold": 500
          "imports": "com.tinkerpop.gremlin.*,com.tinkerpop.gremlin.java.*,com.tinkerpop.gremlin.pipes.filter.*,com.tinkerpop.gremlin.pipes.sideeffect.*,com.tinkerpop.gremlin.pipes.transform.*,com.tinkerpop.blueprints.*,com.tinkerpop.blueprints.impls.*,com.tinkerpop.blueprints.impls.tg.*,com.tinkerpop.blueprints.impls.neo4j.*,com.tinkerpop.blueprints.impls.neo4j.batch.*,com.tinkerpop.blueprints.impls.neo4j2.*,com.tinkerpop.blueprints.impls.neo4j2.batch.*,com.tinkerpop.blueprints.impls.orient.*,com.tinkerpop.blueprints.impls.orient.batch.*,com.tinkerpop.blueprints.impls.dex.*,com.tinkerpop.blueprints.impls.rexster.*,com.tinkerpop.blueprints.impls.sail.*,com.tinkerpop.blueprints.impls.sail.impls.*,com.tinkerpop.blueprints.util.*,com.tinkerpop.blueprints.util.io.*,com.tinkerpop.blueprints.util.io.gml.*,com.tinkerpop.blueprints.util.io.graphml.*,com.tinkerpop.blueprints.util.io.graphson.*,com.tinkerpop.blueprints.util.wrappers.*,com.tinkerpop.blueprints.util.wrappers.batch.*,com.tinkerpop.blueprints.util.wrappers.batch.cache.*,com.tinkerpop.blueprints.util.wrappers.event.*,com.tinkerpop.blueprints.util.wrappers.event.listener.*,com.tinkerpop.blueprints.util.wrappers.id.*,com.tinkerpop.blueprints.util.wrappers.partition.*,com.tinkerpop.blueprints.util.wrappers.readonly.*,com.tinkerpop.blueprints.oupls.sail.*,com.tinkerpop.blueprints.oupls.sail.pg.*,com.tinkerpop.blueprints.oupls.jung.*,com.tinkerpop.pipes.*,com.tinkerpop.pipes.branch.*,com.tinkerpop.pipes.filter.*,com.tinkerpop.pipes.sideeffect.*,com.tinkerpop.pipes.transform.*,com.tinkerpop.pipes.util.*,com.tinkerpop.pipes.util.iterators.*,com.tinkerpop.pipes.util.structures.*,org.apache.commons.configuration.*,com.thinkaurelius.titan.core.*,com.thinkaurelius.titan.core.attribute.*,com.thinkaurelius.titan.core.log.*,com.thinkaurelius.titan.core.olap.*,com.thinkaurelius.titan.core.schema.*,com.thinkaurelius.titan.core.util.*,com.thinkaurelius.titan.example.*,org.apache.commons.configuration.*,com.tinkerpop.gremlin.Tokens.T,com.tinkerpop.gremlin.groovy.*",
          "static-imports": "com.tinkerpop.blueprints.Direction.*,com.tinkerpop.blueprints.TransactionalGraph$Conclusion.*,com.tinkerpop.blueprints.Compare.*,com.thinkaurelius.titan.core.attribute.Geo.*,com.thinkaurelius.titan.core.attribute.Text.*,com.thinkaurelius.titan.core.Cardinality.*,com.thinkaurelius.titan.core.Multiplicity.*,com.tinkerpop.blueprints.Query$Compare.*"
      ]
      config['metrics'] ?= [
          reporter: type:"jmx"
        ,
          reporter: type:"http"
        ,
          reporter:
            type:"console"
            properties:
              "rates-time-unit": "SECONDS"
              "duration-time-unit": "SECONDS"
              "report-period": 10
              "report-time-unit": "MINUTES"
              "includes": "http.rest.*"
              "excludes": "http.rest.*.delete"
      ]
      config.graphs ?= [
        graph:
          'graph-name': 'titan'
          'graph-type': 'com.thinkaurelius.titan.tinkerpop.rexster.TitanGraphConfiguration'
          'graph-read-only': false
          'properties': titan.config
          'extensions': 'allows': 'allow': ['tp:gremlin']
      ]

    module.exports.push commands: 'install', modules: [
      'ryba/rexster/install',
      'ryba/rexster/start',
      'ryba/rexster/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/rexster/start'

    module.exports.push commands: 'check', modules: 'ryba/rexster/check'

    module.exports.push commands: 'status', modules: 'ryba/rexster/status'

    module.exports.push commands: 'stop', modules: 'ryba/rexster/stop'

## Module Dependencies

    path = require 'path'
