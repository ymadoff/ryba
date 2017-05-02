
# Falcon Client Configure

[Apache Falcon](http://falcon.apache.org) is a data processing and management solution for Hadoop designed
for data motion, coordination of data pipelines, lifecycle management, and data
discovery. Falcon enables end consumers to quickly onboard their data and its
associated processing and management tasks on Hadoop clusters.

    module.exports = ->
      [f_context] = @contexts 'ryba/falcon/server', require('../server/configure').handler
      {realm} = @config.ryba
      falcon = @config.ryba.falcon ?= {}
      falcon.client ?= {}
      # Layout
      falcon.client.conf_dir ?= '/etc/falcon/conf'

## Identities

      # User
      falcon.client.user ?= f_context.config.ryba.falcon.user
      # Group
      falcon.client.group ?= f_context.config.ryba.falcon.group
