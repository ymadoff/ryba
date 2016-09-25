
# TinkerPop Rexster (Titan Server)

[Rexster](https://github.com/tinkerpop/rexster/wiki) is a graph server that exposes
any Blueprints graph through REST and a binary protocol called RexPro.
The HTTP web service provides standard low-level GET, POST, PUT, and DELETE methods,
a flexible extensions model which allows plug-in like development for external 
services an’s modular architecture allows it to interoperate with a wide range of
storage, index, and client technologies; it also eases the process of extending
Titan to support new ones.
server-side “stored procedures” written in Gremlin, and a browser-based interface
called The Dog House. 
Rexster Console makes it possible to do remote script evaluation against configured
graphs inside of a Rexster Server.


    module.exports = ->
      'configure':
        'ryba/rexster/configure'
      'install': [
        'masson/core/iptables'
        'masson/core/yum'
        'masson/commons/java'
        'ryba/rexster/install'
        'ryba/rexster/start'
        'ryba/rexster/check'
      ]
      'check': [
        'ryba/rexster/check'
      ]
      'start':
        'ryba/rexster/start'
      'stop':
        'ryba/rexster/stop'
      'status':
        'ryba/rexster/status'
