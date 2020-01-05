package TestFor::Code::TidyAll::Plugin::PerlTidy;

use Test::Class::Most parent => 'TestFor::Code::TidyAll::Plugin';

use Getopt::Long;
use Module::Runtime qw( require_module );
use Try::Tiny;

BEGIN {
    for my $mod (qw( Perl::Tidy )) {
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
        conf         => { argv => '-npro' },
        source       => 'if ($foo) {\n    my $bar = $baz;\n',
        expect_error => qr/Final nesting depth/
    );
    $self->tidyall(
        conf         => { argv => '-npro --badoption' },
        source       => $source,
        expect_error => qr/Unknown option: badoption/
    );
}

sub test_getopt_bug : Tests {
    my $self = shift;

    # This emulates what Getopt::Long::Descriptive does, which in turn breaks
    # Perl::Tidy. See https://rt.cpan.org/Ticket/Display.html?id=118558
    Getopt::Long::Configure(qw( bundling no_auto_help no_ignore_case ));

    my $source = 'if (  $foo) {\nmy   $bar =  $baz;\n}\n';
    $self->tidyall(
        conf        => { argv => '-npro' },
        source      => $source,
        expect_tidy => 'if ($foo) {\n    my $bar = $baz;\n}\n'
    );
}

1;
