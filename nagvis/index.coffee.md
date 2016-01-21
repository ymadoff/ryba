
# NagVis

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      nagvis = ctx.config.ryba.nagvis ?= {}
      # User
      nagvis.user ?= {}
      nagvis.user.name ?= 'nagvis'
      nagvis.user.system ?= true
      nagvis.user.comment ?= 'NagVis User'
      # nagvis.user.home ?=
      # Groups
      nagvis.group = name: nagvis.group if typeof nagvis.group is 'string'
      nagvis.group ?= {}
      nagvis.group.name ?= 'nagvis'
      nagvis.group.system ?= true
      nagvis.user.gid = nagvis.group.name
      #
      nagvis.install_dir ?= '/usr/local/nagvis'
      nagvis.version ?= '1.9-nightly'
      nagvis.source ?= "https://www.nagvis.org/share/nagvis-#{nagvis.version}.tar.gz"

    module.exports.push commands: 'install', modules: 'ryba/nagvis/install'

    # module.exports.push commands: 'start', modules: 'ryba/nagvis/start'

    # module.exports.push commands: 'stop', modules: 'ryba/nagvis/stop'

    # module.exports.push commands: 'status', modules: 'ryba/nagvis/status'
