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

1. Add hooks for realtime monitoring of server performance.

## Logging

Mizuno requires [rjack-slf4j][] which provides a unified interface for
Java/Ruby logging. Jetty auto-detect SLF4J's presence and logs
there. A logging output provider must also be loaded. The minzuno
script will load [rjack-logback][] if found or otherwise fall back to
`rjack-slf4j/simple`.  If you are starting Mizuno through some other
means than the mizuno script, you will need to load an output provider
(see linked docs.)

[rjack-slf4j]:   http://rjack.rubyforge.org/slf4j/RJack/SLF4J.html
[rjack-logback]: http://rjack.rubyforge.org/logback/RJack/Logback.html

## License

Mizuno is licensed under the Apache Public License, version 2.0; see
the LICENSE file for details, and was developed on behalf of 
[Mad Wombat Software](http://www.madwombat.com)

Jetty is dual-licensed under the [Eclipse and Apache open-source 
licenses](http://www.eclipse.org/jetty/licenses.php), and its
development is hosted by the [Eclipse 
Foundation](http://www.eclipse.org/jetty/)
