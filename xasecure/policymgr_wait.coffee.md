
# XASecure Policy Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push
      header: 'XASecure Policy # Wait'
      timeout: -1
      if: -> @hosts_with_module('ryba/xasecure/policymgr').length
      handler: ->
        @wait_connect
          host: @hosts_with_module 'ryba/xasecure/policymgr'
          port: 6080
