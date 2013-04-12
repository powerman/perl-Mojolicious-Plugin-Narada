package Mojolicious::Plugin::Narada;

use strict;
use warnings;

use version; our $VERSION = qv('0.1.1');    # REMINDER: update Changes

# REMINDER: update dependencies in Build.PL
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Util qw( monkey_patch );
use MojoX::Log::Fast;
use Narada::Config qw( get_config get_config_line );
use Narada::Lock qw( unlock );

my ($Log, $Ident);


sub register {
    my ($self, $app, $conf) = @_;

    $Log = MojoX::Log::Fast->new($conf->{log});
    $Ident = $Log->ident();

    # Replace default logger with Log::Fast.
    $app->log($Log);

    # Load Mojo-specific config files.
    $app->secret(get_config_line('cookie.secret'));
    $app->config(hypnotoad => {
        listen      => [split /\n/ms, get_config('hypnotoad/listen')],
        proxy       => get_config_line('hypnotoad/proxy'),
        accepts     => get_config_line('hypnotoad/accepts'),
        workers     => get_config_line('hypnotoad/workers'),
        lock_file   => 'var/hypnotoad.lock',
        pid_file    => 'var/hypnotoad.pid',
    });

    # * Fix url->path and url->base->path.
    # * Set correct ident while handler runs.
    # * unlock() if handler died.
    my $realbase = Mojo::Path->new( get_config_line('basepath') ) ## no critic(ProhibitLongChainsOfMethodCalls)
        ->trailing_slash(0)
        ->leading_slash(1)
        ->to_string;
    $app->hook(around_dispatch => sub {
        my ($next, $c) = @_;
        my $url = $c->req->url;
        my $base = $url->base->path;
        my $path = $url->path;
        if ($base eq q{} && $path =~ m{\A\Q$realbase\E(.*)\z}mso) {
            $path->parse($1);
        }
        $base->parse($realbase);
        $path->leading_slash(1);
        $Log->ident($url->path);
        my $err = eval { $next->(); 1 } ? undef : $@;
        unlock();
        die $err if defined $err;   ## no critic(RequireCarping)
    });

    monkey_patch 'Mojo::Base', proxy => \&_proxy;

    return;
}

sub _proxy {
    my ($this, $cb, @p) = @_;
    return $this->isa('Mojolicious::Controller')
        # * Set correct ident while delayed handler runs.
        # * unlock() if delayed handler died.
        # * Finalize request with render_exception() if delayed handler died.
        ? sub {
            $Log->ident($this->req->url->path);
            my $err = eval { $cb->($this, @p, @_); 1 } ? undef : $@;
            unlock();
            $this->render_exception($err) if defined $err;  ## no critic(ProhibitPostfixControls)
        }
        # * Set correct ident while global event handler runs.
        # * unlock() if global event handler died.
        : sub {
            $Log->ident($Ident);
            my $err = eval { $cb->($this, @p, @_); 1 } ? undef : $@;
            unlock();
            die $err if defined $err;   ## no critic(RequireCarping)
        };
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Narada - Narada configuration plugin


=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('Narada');
    $self->plugin(Narada => (log => Log::Fast->global));

    # Mojolicious::Lite
    plugin 'Narada';
    plugin Narada => (log => Log::Fast->global);

    # Global timer
    package MyApp;
    sub startup {
        my $app = shift;
        Mojo::IOLoop->timer(0 => $app->proxy(sub { say 'Next tick.' }));
    }

    # Request-related timer
    package MyApp::MyController;
    sub myaction {
        my $c = shift;
        $c->render_later;
        Mojo::IOLoop->timer(2 => $c->proxy(sub {
              $c->render(text => 'Delayed by 2 seconds!');
        }));
    }

=head1 DESCRIPTION

L<Mojolicious::Plugin::Narada> is a plugin that configure L<Mojolicious>
to work in L<Narada> project management environment.

Also this plugin add method proxy() into L<Mojo::Base>, and you B<MUST>
use it to wrap all callbacks you setup for handling delayed events like
timers or I/O (both global in your app and related to requests in your
actions).

There is also one feature unrelated to Narada - if callback started by any
action throw unhandled exception it will be sent to browser using same
C<< $c->render_exception >> as it already works for actions without
delayed response.

=over

=item Logging

L<Mojolicious> default L<Mojo::Log> replaced with L<MojoX::Log::Fast> to
support logging to project-local syslog daemon in addition to files.
In most cases it works as drop-in replacement and doesn't require any
modifications in user code.

Also it set C<< $app->log->indent() >> to C<< $c->req->url->path >> to
ease log file analyse.

=item Configuration

You should manually add these lines to C<./you_app> starting script before
call to C<< Mojolicious::Commands->start_app() >>:

    use Narada::Config qw( get_config_line );
    # mode should be set here because it's used before executing MyApp::startup()
    local $ENV{MOJO_MODE} = get_config_line('mode');

Config file C<config/cookie.secret> automatically loaded and used to
initialize C<< $app->secret() >>.

Config file C<config/basepath> automatically loaded and used to fix
C<< $c->req->url->base->path >> and C<< $c->req->url->path >> to
guarantee their consistency in any environment:

=over

=item * url->path doesn't contain base->path

=item * url->path does have leading slash

=item * url->base->path set to content of config/basepath

=back


These config files automatically loaded from C<config/hypnotoad/*>
and used to initialize C<< $app->config(hypnotoad) >>:

    listen
    proxy
    accepts
    workers

Also hypnotoad configured to keep it lock/pid files in C<var/>.

=item Locking

C<unlock()> will be automatically called after all actions and callbacks,
even if they throw unhandled exception.

=back


=head1 OPTIONS

L<Mojolicious::Plugin::Narada> supports the following options.

=head2 log

  plugin Narada => (log => Log::Fast->global);

Value for L<MojoX::Log::Fast>->new().


=head1 METHODS

L<Mojolicious::Plugin::Narada> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);
  $plugin->register(Mojolicious->new, {log => Log::Fast->global});

Register hooks in L<Mojolicious> application.


=head1 SEE ALSO

L<Narada>, L<MojoX::Log::Fast>, L<Mojolicious>.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.


=head1 SUPPORT

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-Narada>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

You can also look for information at:

=over

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-Narada>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-Narada>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-Narada>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-Narada/>

=back


=head1 AUTHOR

Alex Efros  C<< <powerman@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Alex Efros <powerman@cpan.org>.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

