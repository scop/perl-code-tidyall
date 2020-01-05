package TestFor::Code::TidyAll::Plugin::PerlTidySweet;

use Test::Class::Most parent => 'TestFor::Code::TidyAll::Plugin';

use Module::Runtime qw( require_module );
use Try::Tiny;

BEGIN {
    for my $mod (qw( Perl::Tidy::Sweetened )) {
        unless ( try { require_module($mod); 1 } ) {
            __PACKAGE__->SKIP_CLASS("This test requires the $mod module");
            return;
        }
    }
}

sub test_main : Tests {
    my $self = shift;

    my $source = 'if (  $foo) {\nmy   $bar =  $baz;\n}\n';
    $self->tidyall(
        conf        => { argv => '-npro' },
        source      => $source,
        expect_tidy => 'if ($foo) {\n    my $bar = $baz;\n}\n'
    );
    $self->tidyall(
        conf        => { argv => '-npro -bl' },
        source      => $source,
        expect_tidy => 'if ($foo)\n{\n    my $bar = $baz;\n}\n'
    );
    $self->tidyall(
        conf      => { argv => '-npro' },
        source    => 'if ($foo) {\n    my $bar = $baz;\n}\n',
        expect_ok => 1
    );
    $self->tidyall(
        source      => 'method  foo  ($x,$y){\nmy  $x=$self->x;}\n',
        expect_tidy => 'method foo ($x,$y) {\n    my $x = $self->x;\n}\n',
    );
    $self->tidyall(
        source       => 'if ($foo) {\n    my $bar = $baz;\n',
        expect_error => qr/Final nesting depth/
    );
    $self->tidyall(
        conf         => { argv => '--badoption' },
        source       => $source,
        expect_error => qr/Unknown option: badoption/
    );
}

1;
