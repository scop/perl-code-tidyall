package TestFor::Code::TidyAll::Plugin::CSSUnminifier;

use Path::Tiny qw( cwd );
use Test::Class::Most parent => 'TestFor::Code::TidyAll::Plugin';

sub _extra_path {
    cwd()->child(qw( node_modules .bin ));
}

sub test_main : Tests {
    my $self = shift;

    return unless $self->require_executable('node');
    return unless $self->require_executable('cssunminifier');

    my $source = "body {\nfont-family:helvetica;\nfont-size:15pt;\n}";
    $self->tidyall(
        source      => $source,
        expect_tidy => "body {\n    font-family: helvetica;\n    font-size: 15pt;\n}\n"
    );
    $self->tidyall(
        source      => $source,
        conf        => { argv => '-w=2' },
        expect_tidy => "body {\n  font-family: helvetica;\n  font-size: 15pt;\n}\n"
    );
}

1;
