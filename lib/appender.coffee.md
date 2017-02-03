
# Appender
Create an appender and add it to a log4j object.

## Options:

*   `type`   (String)
    The type of appender. For example `org.apache.log4j.net.SocketAppender`
*   `name`   (String)
    The name of the appender. For example `SOCKET`
*   `log4j`   (Object)
    the target log4j properties object.
*   `properties`  (Object) 
    the options used to creatin the log4j properties.

## Source Code

    module.exports = (options) ->
      throw Error 'Missing type' unless options.type?
      throw Error 'Missing name' unless options.name?
      throw Error 'Missing properties' unless options.properties?
      log4j = options.log4j ?= {}
      log4j["log4j.appender.#{options.name}"] ?= "#{options.type}"
      for key, value of options.properties
        log4j["log4j.appender.#{options.name}.#{key}"] ?= "#{value}"
      log4j
