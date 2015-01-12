
# YARN Client

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.configure = require('./yarn').configure

    module.exports.push commands: 'check', modules: 'ryba/hadoop/yarn_client_check'

    module.exports.push commands: 'info', modules: 'ryba/hadoop/yarn_client_info'

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/yarn_client_install'
      'ryba/hadoop/yarn_client_check'
    ]

