
# HDP Configure

    module.exports = ->
      ryba = @config.ryba ?= {}
      ryba.hdp_repo ?= 'http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.5.0.0/hdp.repo'
