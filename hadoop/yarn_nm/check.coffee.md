
# YARN NodeManager Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/yarn_rm/wait'
    # module.exports.push require('./index').configure

    module.exports.push header: 'YARN NM # FS Permissions', label_true: 'CHECKED', handler: ->
      {yarn} = @config.ryba
      log_dirs = yarn.site['yarn.nodemanager.log-dirs'].split ','
      local_dirs = yarn.site['yarn.nodemanager.local-dirs'].split ','
      cmds = []
      for dir in log_dirs then cmds.push cmd: "su -l #{yarn.user.name} -c 'ls -l #{dir}'"
      for dir in local_dirs then cmds.push cmd: "su -l #{yarn.user.name} -c 'ls -l #{dir}'"
      @execute cmds
