
# Titan

Titan is a distributed graph database. It is an hadoop-friendly implementation of [TinkerPop]
[Blueprints]. Therefore it also use ThinkerPop REPL [Gremlin], and Front server [Rexster]

    module.exports = ->
      'configure':
        'ryba/titan/configure'
      'install': [
        'ryba/hbase/client'
        'ryba/titan/install'
        'ryba/titan/check'
      ]
      'check':
        'ryba/titan/check'

## Resources

[TinkerPop]: http://www.tinkerpop.com/
[Blueprints]: https://github.com/tinkerpop/blueprints/wiki
[Gremlin]: https://github.com/tinkerpop/gremlin/wiki
[Rexster]: https://github.com/tinkerpop/rexster/wiki
