[![Build Status](https://travis-ci.org/powerman/perl-Mojolicious-Plugin-Narada.svg?branch=master)](https://travis-ci.org/powerman/perl-Mojolicious-Plugin-Narada)
[![Coverage Status](https://coveralls.io/repos/powerman/perl-Mojolicious-Plugin-Narada/badge.svg?branch=master)](https://coveralls.io/r/powerman/perl-Mojolicious-Plugin-Narada?branch=master)

# NAME

Mojolicious::Plugin::Narada - Narada configuration plugin

# VERSION

This document describes Mojolicious::Plugin::Narada version v1.0.0

# SYNOPSIS

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
        Mojo::IOLoop->timer(1 => $c->weak_proxy(sub { say 'Alive' }));
        Mojo::IOLoop->timer(2 => $c->proxy(sub {
              $c->render(text => 'Delayed by 2 seconds!');
        }));
        Mojo::IOLoop->timer(3 => $c->weak_proxy(sub { say 'Dead' }));
    }

# DESCRIPTION

[Mojolicious::Plugin::Narada](https://metacpan.org/pod/Mojolicious::Plugin::Narada) is a plugin that configure [Mojolicious](https://metacpan.org/pod/Mojolicious)
to work in [Narada](https://metacpan.org/pod/Narada) project management environment.

Also this plugin add helpers `proxy` and `weak_proxy`, and you **MUST**
use them to wrap all callbacks you setup for handling delayed events like
timers or I/O (both global in your app and related to requests in your
actions).

There is also one feature unrelated to Narada - if callback started by any
action throw unhandled exception it will be sent to browser using same
`$c->reply->exception` as it already works for actions without
delayed response.

- Logging

    [Mojolicious](https://metacpan.org/pod/Mojolicious) default [Mojo::Log](https://metacpan.org/pod/Mojo::Log) replaced with [MojoX::Log::Fast](https://metacpan.org/pod/MojoX::Log::Fast) to
    support logging to project-local syslog daemon in addition to files.
    In most cases it works as drop-in replacement and doesn't require any
    modifications in user code.

    Also it set `$app->log->ident()` to `$c->req->url->path` to
    ease log file analyse.

- Configuration

    You should manually add these lines to `./you_app` starting script before
    call to `Mojolicious::Commands->start_app()`:

        use Narada::Config qw( get_config_line );
        # mode should be set here because it's used before executing MyApp::startup()
        local $ENV{MOJO_MODE} = get_config_line('mode');

    Config file `config/cookie.secret` automatically loaded and used to
    initialize `$app->secrets()` (each line of file became separate
    param).

    Config file `config/basepath` automatically loaded and used to fix
    `$c->req->url->base->path` and `$c->req->url->path` to
    guarantee their consistency in any environment:

    - url->path doesn't contain base->path
    - url->path does have leading slash
    - url->base->path set to content of config/basepath

    These config files automatically loaded from `config/hypnotoad/*`
    and used to initialize `$app->config(hypnotoad)`:

        listen
        proxy
        accepts
        workers

    Also hypnotoad configured to keep it lock/pid files in `var/`.

- Locking

    `unlock()` will be automatically called after all actions and callbacks,
    even if they throw unhandled exception.

# OPTIONS

[Mojolicious::Plugin::Narada](https://metacpan.org/pod/Mojolicious::Plugin::Narada) supports the following options.

## log

    plugin Narada => (log => Log::Fast->global);

Value for [MojoX::Log::Fast](https://metacpan.org/pod/MojoX::Log::Fast)->new().

# METHODS

[Mojolicious::Plugin::Narada](https://metacpan.org/pod/Mojolicious::Plugin::Narada) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## register

    $plugin->register(Mojolicious->new);
    $plugin->register(Mojolicious->new, {log => Log::Fast->global});

Register hooks in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# SEE ALSO

[Narada](https://metacpan.org/pod/Narada), [MojoX::Log::Fast](https://metacpan.org/pod/MojoX::Log::Fast), [Mojolicious](https://metacpan.org/pod/Mojolicious).

# SUPPORT

## Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at [https://github.com/powerman/perl-Mojolicious-Plugin-Narada/issues](https://github.com/powerman/perl-Mojolicious-Plugin-Narada/issues).
You will be notified automatically of any progress on your issue.

## Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

[https://github.com/powerman/perl-Mojolicious-Plugin-Narada](https://github.com/powerman/perl-Mojolicious-Plugin-Narada)

    git clone https://github.com/powerman/perl-Mojolicious-Plugin-Narada.git

## Resources

- MetaCPAN Search

    [https://metacpan.org/search?q=Mojolicious-Plugin-Narada](https://metacpan.org/search?q=Mojolicious-Plugin-Narada)

- CPAN Ratings

    [http://cpanratings.perl.org/dist/Mojolicious-Plugin-Narada](http://cpanratings.perl.org/dist/Mojolicious-Plugin-Narada)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Mojolicious-Plugin-Narada](http://annocpan.org/dist/Mojolicious-Plugin-Narada)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=Mojolicious-Plugin-Narada](http://matrix.cpantesters.org/?dist=Mojolicious-Plugin-Narada)

- CPANTS: A CPAN Testing Service (Kwalitee)

    [http://cpants.cpanauthors.org/dist/Mojolicious-Plugin-Narada](http://cpants.cpanauthors.org/dist/Mojolicious-Plugin-Narada)

# AUTHOR

Alex Efros &lt;powerman@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2013-2015 by Alex Efros &lt;powerman@cpan.org>.

This is free software, licensed under:

    The MIT (X11) License
