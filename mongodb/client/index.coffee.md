
# MongoDB Client

    module.exports =
      use: 
        core_local: implicit: true, module: 'masson/core/locale'
      configure:
        'ryba/mongodb/client/configure'
      commands:
        'install':
          'ryba/mongodb/client/install'
        'check':
          'ryba/mongodb/client/check'
