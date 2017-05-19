
# HDF Configure

    module.exports = ->
      return unless @config.ryba.hdf
      @config.ryba.hdf = {} if @config.ryba.hdf is true
      options = @config.ryba.hdf
      options.repo ?= 'http://public-repo-1.hortonworks.com/HDF/centos7/2.x/updates/2.1.2.0/hdf.repo'
