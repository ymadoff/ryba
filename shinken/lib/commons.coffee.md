
# Shinken Install

    module.exports = header: 'Shinken Install', handler: ->
      {shinken} = @config.ryba

## Users & Groups

      @group shinken.group
      @user shinken.user

## Commons Packages

      @call header: 'Commons Packages', handler: ->
        @service name: 'python'
        @service name: 'python-pip'
        @service name: 'python-pycurl'