
# HDP Configure

    module.exports = ->
      return unless @config.ryba.hdp
      @config.ryba.hdp = {} if @config.ryba.hdp is true
      options = @config.ryba.hdp
      options.repo ?= 'http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.5.3.0/hdp.repo'
