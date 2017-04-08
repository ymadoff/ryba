
# Shinken Install

    module.exports = header: 'Shinken Install', handler: ->
      {shinken} = @config.ryba

## Users & Groups

      @system.group shinken.group
      @system.user shinken.user

## Commons Packages

      @call header: 'Commons Packages', ->
        @service name: 'python'
        @service name: 'python-pip'
        @service name: 'libcurl-devel'
        @service name: 'python-pycurl'
        @service name: 'python-devel'

## Layout

      @call header: 'Layout', ->
        @system.mkdir
          target: '/etc/shinken/packs'
        @system.mkdir
          target: "#{shinken.user.home}/share"
          uid: shinken.user.name
          gid: shinken.group.name
        @system.mkdir
          target: "#{shinken.user.home}/doc"
          uid: shinken.user.name
          gid: shinken.group.name
        @system.chown
          target: shinken.log_dir
          uid: shinken.user.name
          gid: shinken.group.name
        @system.execute
          cmd: 'shinken --init'
          unless_exists: "#{shinken.user.home}/.shinken.ini"
