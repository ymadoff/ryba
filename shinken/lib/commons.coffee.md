
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
        @service name: 'libcurl-devel'
        @service name: 'python-pycurl'
        @service name: 'python-devel'

## Layout

      @call header: 'Layout', handler: ->
        @mkdir
          target: '/etc/shinken/packs'
        @mkdir
          target: "#{shinken.user.home}/share"
          uid: shinken.user.name
          gid: shinken.group.name
        @mkdir
          target: "#{shinken.user.home}/doc"
          uid: shinken.user.name
          gid: shinken.group.name
        @chown
          target: shinken.log_dir
          uid: shinken.user.name
          gid: shinken.group.name
        @execute
          cmd: 'shinken --init'
          unless_exists: "#{shinken.user.home}/.shinken.ini"
