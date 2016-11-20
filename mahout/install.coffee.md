
# Mahout

http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.1/bk_installing_manually_book/content/rpm-chap5-1.html

    module.exports = header: 'Hadoop Mahout Install', timeout: -1, handler: ->

## Register

      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## Package

      @service name: 'mahout'
      @hdp_select name: 'mahout-client'
