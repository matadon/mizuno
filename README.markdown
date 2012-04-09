Mizuno is a set of Jetty-powered running shoes for JRuby/Rack.

To use Mizuno with your Rack app:

    gem install mizuno
    cd /path/to/my/rack/app
    mizuno

...and you're off and running.  You don't need to set up a Java web
container for your Rack application to run under JRuby, because Mizuno
works just like Mongrel, WEBRick, Thin, or any other standard Rack
handler.

Mizuno also supports asynchronous request handling, via the Java Servlet
3.0 asynchronous processing mechanism

All the speed comes from Jetty 8; Mizuno just ties it to Rack through
JRuby's Ruby/Java integration layer.

Note that Mizuno is NOT a direct replacement for jruby-rack or Warbler,
because it doesn't produce WAR files or make any attempt to package a
Rack application for installation in a Java web container.

You can also run Mizuno via rackup:

    rackup -s mizuno

Or with live reloading support:

    mizuno --reloadable

Mizuno is licensed under the Apache Public License, version 2.0; see
the LICENSE file for details, and was developed on behalf of 
[Mad Wombat Software](http://www.madwombat.com)

Jetty is dual-licensed under the [Eclipse and Apache open-source 
licenses](http://www.eclipse.org/jetty/licenses.php), and its
development is hosted by the [Eclipse 
Foundation](http://www.eclipse.org/jetty/)
