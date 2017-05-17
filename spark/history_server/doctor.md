
# Apache Spark History Server

## ATS implementation for the Spark History Server

The SHS doent seems to server webpage. The log shows:

```
15/07/01 11:17:47 WARN servlet.ServletHandler: /history/application_1435308807622_0053
com.sun.jersey.api.client.ClientHandlerException: A message body reader for Java class org.apache.hadoop.yarn.api.records.timeline.TimelineEntity, and Java type class org.apache.hadoop.yarn.api.records.timeline.TimelineEntity, and MIME media type text/html; charset=iso-8859-1 was not found
  at com.sun.jersey.api.client.ClientResponse.getEntity(ClientResponse.java:549)
  at com.sun.jersey.api.client.ClientResponse.getEntity(ClientResponse.java:506)
  at org.apache.spark.deploy.yarn.history.YarnHistoryProvider.getAppUI(YarnHistoryProvider.scala:110)
  at org.apache.spark.deploy.history.HistoryServer$$anon$3.load(HistoryServer.scala:55)
  at org.apache.spark.deploy.history.HistoryServer$$anon$3.load(HistoryServer.scala:53)
  at org.spark-project.guava.common.cache.LocalCache$LoadingValueReference.loadFuture(LocalCache.java:3599)
  at org.spark-project.guava.common.cache.LocalCache$Segment.loadSync(LocalCache.java:2379)
  at org.spark-project.guava.common.cache.LocalCache$Segment.lockedGetOrLoad(LocalCache.java:2342)
  at org.spark-project.guava.common.cache.LocalCache$Segment.get(LocalCache.java:2257)
  at org.spark-project.guava.common.cache.LocalCache.get(LocalCache.java:4000)
  at org.spark-project.guava.common.cache.LocalCache.getOrLoad(LocalCache.java:4004)
  at org.spark-project.guava.common.cache.LocalCache$LocalLoadingCache.get(LocalCache.java:4874)
  at org.apache.spark.deploy.history.HistoryServer$$anon$1.doGet(HistoryServer.scala:85)
  at javax.servlet.http.HttpServlet.service(HttpServlet.java:735)
  at javax.servlet.http.HttpServlet.service(HttpServlet.java:848)
  at org.eclipse.jetty.servlet.ServletHolder.handle(ServletHolder.java:684)
  at org.eclipse.jetty.servlet.ServletHandler.doHandle(ServletHandler.java:501)
  at org.eclipse.jetty.server.handler.ContextHandler.doHandle(ContextHandler.java:1086)
  at org.eclipse.jetty.servlet.ServletHandler.doScope(ServletHandler.java:428)
  at org.eclipse.jetty.server.handler.ContextHandler.doScope(ContextHandler.java:1020)
  at org.eclipse.jetty.server.handler.ScopedHandler.handle(ScopedHandler.java:135)
  at org.eclipse.jetty.server.handler.ContextHandlerCollection.handle(ContextHandlerCollection.java:255)
  at org.eclipse.jetty.server.handler.HandlerWrapper.handle(HandlerWrapper.java:116)
  at org.eclipse.jetty.server.Server.handle(Server.java:370)
  at org.eclipse.jetty.server.AbstractHttpConnection.handleRequest(AbstractHttpConnection.java:494)
  at org.eclipse.jetty.server.AbstractHttpConnection.headerComplete(AbstractHttpConnection.java:971)
  at org.eclipse.jetty.server.AbstractHttpConnection$RequestHandler.headerComplete(AbstractHttpConnection.java:1033)
  at org.eclipse.jetty.http.HttpParser.parseNext(HttpParser.java:644)
  at org.eclipse.jetty.http.HttpParser.parseAvailable(HttpParser.java:235)
  at org.eclipse.jetty.server.AsyncHttpConnection.handle(AsyncHttpConnection.java:82)
  at org.eclipse.jetty.io.nio.SelectChannelEndPoint.handle(SelectChannelEndPoint.java:667)
  at org.eclipse.jetty.io.nio.SelectChannelEndPoint$1.run(SelectChannelEndPoint.java:52)
  at org.eclipse.jetty.util.thread.QueuedThreadPool.runJob(QueuedThreadPool.java:608)
  at org.eclipse.jetty.util.thread.QueuedThreadPool$3.run(QueuedThreadPool.java:543)
  at java.lang.Thread.run(Thread.java:745)
```

No solution found for now, seems like current yarn ATS and spark SHS are incompatabible, we dont activate SHS.
