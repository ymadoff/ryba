
# NagVis

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      nagvis = ctx.config.ryba.nagvis ?= {}
      nagvis.install_dir ?= '/usr/local/nagvis'
      nagvis.version ?= '1.9-nightly'
      nagvis.source ?= "https://www.nagvis.org/share/nagvis-#{nagvis.version}.tar.gz"
      nagvis.port ?= 50000

    module.exports.push commands: 'install', modules: 'ryba/nagvis/install'

    # module.exports.push commands: 'start', modules: 'ryba/nagvis/start'

    # module.exports.push commands: 'stop', modules: 'ryba/nagvis/stop'

    # module.exports.push commands: 'status', modules: 'ryba/nagvis/status'
