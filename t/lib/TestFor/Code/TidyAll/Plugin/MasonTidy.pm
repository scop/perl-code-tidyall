package TestFor::Code::TidyAll::Plugin::MasonTidy;

use Test::Class::Most parent => 'TestFor::Code::TidyAll::Plugin';

use Module::Runtime qw( require_module );
use Try::Tiny;

BEGIN {
    for my $mod (qw( Mason::Tidy )) {
        unless ( try { require_module($mod); 1 } ) {
            __PACKAGE__->SKIP_CLASS("This test requires the $mod module");
            return;
        }
    }
}

sub test_main : Tests {
    my $self = shift;

    my $source = "%if(\$foo) {\n%bar(1,2);\n%}";
    $self->tidyall(
        source      => $source,
        conf        => { argv => '-m 1' },
        expect_tidy => "% if (\$foo) {\n%     bar( 1, 2 );\n% }",
    );
    $self->tidyall(
        source      => $source,
        conf        => { argv => q{-m 1 --perltidy-argv="-pt=2 -i=3"} },
        expect_tidy => "% if (\$foo) {\n%    bar(1, 2);\n% }",
    );
    $self->tidyall(
        source      => $source,
        conf        => { argv => q{-m 2 --perltidy-line-argv=" "} },
        expect_tidy => "% if (\$foo) {\n%     bar( 1, 2 );\n% }",
    );
    $self->tidyall(
        source       => $source,
        conf         => { argv => '-m 1 --badoption' },
        expect_error => qr/Usage/,
    );
}

1;
