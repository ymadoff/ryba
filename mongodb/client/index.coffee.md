
# MongoDB Client

    module.exports = ->
      'configure': [
        'ryba/mongodb/client/configure'
      ]
      'install': [
        'ryba/mongodb/client/install'
      ]
      'check': [
        'ryba/mongodb/router/wait'
        'ryba/mongodb/client/check'
      ]
