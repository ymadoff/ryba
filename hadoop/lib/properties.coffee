
fs = require 'ssh2-fs'
# jsdom = require 'jsdom'
xmldom = require 'xmldom'
builder = require 'xmlbuilder'
misc = require 'mecano/lib/misc'

self = module.exports = 
  ###
  `parse(xml, [property])`
  ----------------------------------

  Parse an xml document and retrieve one or multiple properties.

  Retrieve all properties
      properties = parse(xml);

  Retrieve a property
      value = parse(xml, property);
  ###
  parse: (markup, property, callback) ->
    if arguments.length is 2
      callback = property
      property = null
    properties = {}
    doc = new xmldom.DOMParser().parseFromString markup
    for propertyChild in doc.documentElement.childNodes
      continue unless propertyChild.tagName?.toUpperCase() is 'PROPERTY'
      name = value = null
      for child in propertyChild.childNodes
        if child.tagName?.toUpperCase() is 'NAME'
          name = child.childNodes[0].nodeValue
        if child.tagName?.toUpperCase() is 'VALUE'
          value = child.childNodes[0]?.nodeValue or ''
          console.log '>>>', name, '<<<', markup if child.childNodes.length > 1
      return value if property and name is property and value?
      properties[name] = value if name and value?
    return properties
    # doc = jsdom.jsdom markup, jsdom.level(1, "core")
    # for configChild in doc.childNodes
    #   continue unless configChild.tagName is 'CONFIGURATION'
    #   for propertyChild in configChild.childNodes
    #     continue unless propertyChild.tagName is 'PROPERTY'
    #     name = value = null
    #     for child in propertyChild.childNodes
    #       if child.tagName is 'NAME'
    #         name = child.innerHTML
    #       if child.tagName is 'VALUE'
    #         value = child.innerHTML
    #     return value if property and name is property and value?
    #     properties[name] = value if name and value?
    # return properties
  ###
  `stringify(properties)`
  -----------------------

  Convert a property object into a valid Hadoop XML markup. Properties are 
  ordered by name.

  Convert an object into a string
    properties = {'fs.defaultFS': 'hdfs://namenode:8020'}
    markup = stringify(properties);

  Convert an array into a string
    properties = [{@name 'fs.defaultFS', value: 'hdfs://namenode:8020'}]
    markup = stringify(properties);

  ###
  stringify: (properties) ->
    markup = builder.create 'configuration', version: '1.0', encoding: 'UTF-8'
    if Array.isArray properties
      properties.sort (el1, el2) -> el1.name > el2.name
      for {name, value} in properties
        property = markup.ele 'property'
        property.ele 'name', name
        property.ele 'value', value
    else
      ks = Object.keys properties
      ks.sort()
      for k in ks
        property = markup.ele 'property'
        property.ele 'name', k
        property.ele 'value', properties[k]
    markup.end pretty: true
  ###
  `read([ssh], path, [property], callback)`
  ----------------------------------
  
  Similar to `parse` but read the xml from a file instead of 
  expecting a XML markup.
  ###
  read: (path, property, callback) ->
    args = Array.prototype.slice.call arguments, 0
    # I tried `if args[0] instanceof Connection` but it wasnt working
    ssh = if typeof args[0] isnt 'string' then args.shift() else null
    path = args[0]
    property = args[1]
    callback = args[2]
    if args.length is 2
      callback = property
      property = null
    fs.readFile ssh, path, 'utf8', (err, markup) ->
      return callback err if err
      callback null, self.parse markup, property
  ###
  `write([ssh], path, properties, callback)`
  ------------------------------------------
  
  Similar to `stringify` but write the xml to a file instead of 
  returning an XML markup. The generated XML markup is also 
  provided as the second argument of the callback.
  ###
  write: (path, properties, callback) ->
    args = Array.prototype.slice.call arguments, 0
    # I tried `if args[0] instanceof Connection` but it wasnt working
    ssh = if typeof args[0] isnt 'string' then args.shift() else null
    path = args[0]
    properties = args[1]
    callback = args[2]
    markup = self.stringify properties
    fs.writeFile ssh, path, markup, (err) ->
      return callback err if err
      callback null, markup




