Mizuno is a set of Jetty-powered running shoes for JRuby/Rack.

To use Mizuno with your Rack app:

    gem install mizuno
    cd /path/to/my/rack/app
    mizuno

...and you're off and running.  You don't need to set up a Java web
container for your Rack application to run under JRuby, because Mizuno
works just like Mongrel, WEBRick, Thin, or any other standard Rack
handler.

Mizuno is the fastest option for Rack applications on JRuby:

    Mizuno: 6106.66 req/s (mean)
    Jetty (via jruby-rack): 2011.67 req/s (mean)
    Mongrel: 1479.15 req/sec (mean)

Mizuno also supports asynchronous request handling, via the Java Servlet
3.0 asynchronous processing mechanism

All the speed comes from Jetty 7; Mizuno just ties it to Rack through
JRuby's Ruby/Java integration layer.

Note that Mizuno is NOT a direct replacement for jruby-rack or Warbler,
because it doesn't produce WAR files or make any attempt to package a
Rack application for installation in a Java web container.

There's also a few features that I have yet to implement:

1. Route Jetty's logs into Rack::Logger.
2. Add hooks for realtime monitoring of server performance.

Mizuno is licensed under the Apache Public License, version 2.0; see
the LICENSE file for details, and was developed on behalf of 
[Mad Wombat Software](http://www.madwombat.com)

Jetty is dual-licensed under the [Eclipse and Apache open-source 
licenses](http://www.eclipse.org/jetty/licenses.php), and its
development is hosted by the [Eclipse 
Foundation](http://www.eclipse.org/jetty/)
