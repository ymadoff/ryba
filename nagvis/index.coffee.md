
# NagVis

NagVis is a visualization addon for the well known network managment system Nagios.

NagVis can be used to visualize Nagios Data, e.g. to display IT processes like a
mail system or a network infrastructure.

NagVis is also compliant with shinken.

    module.exports = ->
      'configure':
        'ryba/nagvis/configure'
      'install': [
        'masson/core/yum'
        'masson/core/iptables'
        'ryba/nagvis/install'
      ]
