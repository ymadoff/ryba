
# Shinken Receiver Configure

    module.exports = handler: ->
      {shinken} = @config.ryba
      receiver = shinken.receiver ?= {}
      # Additionnal Modules to install
      receiver.modules ?= {}
      # Config
      receiver.config ?= {}
      receiver.config.port ?= 7773
      receiver.config.spare ?= '0'
      receiver.config.realm ?= 'All'
      receiver.config.modules = [receiver.config.modules] if typeof receiver.config.modules is 'string'
      receiver.config.modules ?= Object.keys receiver.modules
      receiver.config.use_ssl ?= shinken.config.use_ssl
      receiver.config.hard_ssl_name_check ?= shinken.config.hard_ssl_name_check