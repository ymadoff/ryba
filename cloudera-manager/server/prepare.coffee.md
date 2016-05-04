
# Cloudera Manager Server Prepare

Resources:
*   [Install](http://www.cloudera.com/documentation/enterprise/latest/topics/cm_ig_install_path_c.html)
*   [Download](http://www.cloudera.com/documentation/enterprise/release-notes/topics/cm_vd.html)

    module.exports = header: 'Cloudera Manager Server Prepare', timeout: -1, handler: ->
      @cache
        ssh: null
        source: 'https://archive.cloudera.com/cm5/cm/5/cloudera-manager-centos7-cm5.7.0_x86_64.tar.gz'
