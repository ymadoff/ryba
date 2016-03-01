
# YARN NodeManager Check

    module.exports = header: 'YARN NM Check', label_true: 'CHECKED', handler: ->
      {yarn} = @config.ryba
      
      @call header: 'YARN NM # FS Permissions', handler: ->
        log_dirs = yarn.site['yarn.nodemanager.log-dirs'].split ','
        local_dirs = yarn.site['yarn.nodemanager.local-dirs'].split ','
        cmds = []
        for dir in log_dirs then cmds.push cmd: "su -l #{yarn.user.name} -c 'ls -l #{dir}'"
        for dir in local_dirs then cmds.push cmd: "su -l #{yarn.user.name} -c 'ls -l #{dir}'"
        @execute cmds
