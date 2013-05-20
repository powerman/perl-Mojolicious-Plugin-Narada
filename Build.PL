use 5.010;
use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => 'Module::Build::Custom',
    code => <<'SUBCLASS' );

# Better compatibility with Gentoo ebuilds.
sub dist_version {
    my $self = shift;
    my $v = $self->SUPER::dist_version;
    $v =~ s/\Av//ms;
    return $v;
}
SUBCLASS

my $builder = $class->new(
    module_name         => 'Mojolicious::Plugin::Narada',
    license             => 'mit',
    dist_author         => q{Alex Efros <powerman@cpan.org>},
    dist_version_from   => 'lib/Mojolicious/Plugin/Narada.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build'         => 0,
    },
    build_requires => {
        'Test::More'            => 0,
#         'Test::Exception'       => 0,
    },
    requires => {
        'perl'                  => 5.010,
        'version'               => '0.77',
        'Mojolicious'           => 0,
        'MojoX::Log::Fast'      => 0,
        'Narada'                => 0,
    },
    recommends => {
        'Test::CheckManifest'   => '0.9',
        'Test::Perl::Critic'    => 0,
        'Test::Pod::Coverage'   => '1.08',
        'Pod::Coverage'         => '0.18',
        'Test::Pod'             => '1.22',
    },
#     add_to_cleanup     => [ 'Mojolicious-Plugin-Narada-*' ],
);

$builder->create_build_script();
