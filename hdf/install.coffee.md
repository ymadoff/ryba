
# HDF Install

    module.exports = header: 'HDF Install', handler: (options) ->
      options = @config.ryba.hdp
      @tools.repo
        if: options.repo?
        header: 'Repository'
        source: options.repo
        target: '/etc/yum.repos.d/hdf.repo'
        replace: 'hdf*'
        update: true
