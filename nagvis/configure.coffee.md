
# NagVis configure

*   `nagvis.install_dir` (string)
    Installation directory
*   `nagvis.version` (string)
    NagVis version. Used to automatically set source
*   `nagvis.source` (string)
    URL path to the source. You should not have to change it.
*   `nagvis.port` (int)
    Nagvis port.

Example

```json
    "nagvis": {
      "install_dir": "/usr/local/nagvis",
      "version": "1.9"
      "livestatus_address": "host.mydomain:50000"
    }
```

    module.exports = handler: ->
      nagvis = @config.ryba.nagvis ?= {}
      nagvis.install_dir ?= '/usr/local/nagvis'
      if [ctx] = @contexts 'ryba/shinken/broker', [require('../shinken/lib/configure').handler, require('../shinken/broker/configure').handler]
        nagvis.base_dir ?= ctx.config.ryba.shinken.user.home
        nagvis.livestatus_address ?= "#{if ctx.config.host is @config.host then '127.0.0.1' else @config.host}:#{ctx.config.ryba.shinken.broker.modules['livestatus'].config.port}"
      throw Error 'Must declare shinken broker module, or manually specify nagvis.base_dir and nagvis.livestatus_address' unless nagvis.base_dir? and nagvis.livestatus_address?
      nagvis.version ?= '1.9-nightly'
      nagvis.source ?= "https://www.nagvis.org/share/nagvis-#{nagvis.version}.tar.gz"
      nagvis.shinken_integrate ?= false
      nagvis.config ?= {}
      nagvis.config.global ?= {}
      nagvis.config.global.file_group ?= 'apache'
      nagvis.config.paths ?= {}
      nagvis.config.defaults ?= {}
      nagvis.config.index ?= {}
      nagvis.config.automap ?= {}
      nagvis.config.global ?= {}
      nagvis.config.wui ?= {}
      nagvis.config.worker ?= {}
      nagvis.config.backend_live_1 ?= {}
      nagvis.config.backend_live_1.backendtype ?= "mklivestatus"
      nagvis.config.backend_live_1.socket ?= "tcp:127.0.0.1:50000"
      nagvis.config.backend_ndomy_1 ?= {}
      nagvis.config.backend_ndomy_1.backendtype ?= "ndomy"
      nagvis.config.states ?= {}
