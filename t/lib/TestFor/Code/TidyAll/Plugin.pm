package TestFor::Code::TidyAll::Plugin;

use strict;
use warnings;
use autodie;

use Capture::Tiny qw(capture);
use Code::TidyAll::Util qw(tempdir_simple);
use Code::TidyAll;
use Path::Tiny qw(path);
use Test::Class::Most parent => 'TestHelper::Test::Class';
use Test::Differences qw( eq_or_diff );

__PACKAGE__->SKIP_CLASS('Virtual base class');

my $Test = Test::Builder->new;

sub startup : Tests(startup => no_plan) {
    my $self = shift;

    $self->{root_dir} = tempdir_simple();

    my @extra = $self->_extra_path();
    $ENV{PATH} .= q{:} . join ':', @extra if @extra;

    return;
}

sub plugin_class {
    my ($self) = @_;

    return ( split( '::', ref($self) ) )[-1];
}

sub test_filename {'foo.txt'}

sub tidyall {
    my ( $self, %p ) = @_;

    my $ct = Code::TidyAll->new(
        quiet    => 1,
        root_dir => $self->{root_dir},
        plugins  => ( $p{plugin_conf} ? $p{plugin_conf} : $self->_plugin_conf( $p{conf} ) ),
    );

    my ( $source, $result, $output, $error );
    if ( $p{source} ) {
        $source = $p{source};
        $source =~ s/\\n/\n/g;
        ( $output, $error ) = capture {
            $result = $ct->process_source( $source, $self->test_filename )
        };
    }
    elsif ( $p{source_file} ) {
        ( $output, $error )
            = capture { $result = $ct->process_file( $p{source_file} ) };
    }
    else {
        die 'The tidyall() method requires a source or source_file parameter';
    }

    my $desc = $p{desc} || $p{source} || $p{source_file};

    $Test->diag($output) if $output && $ENV{TEST_VERBOSE};
    $Test->diag($error)  if $error  && $ENV{TEST_VERBOSE};

    subtest(
        $desc,
        sub {
            if ( my $expect_tidy = $p{expect_tidy} ) {
                $expect_tidy =~ s/\\n/\n/g;
                is( $result->state, 'tidied', 'state=tidied' );
                eq_or_diff(
                    $result->new_contents, $expect_tidy,
                    'new contents'
                );
                is( $result->error, undef, 'no error' );
            }
            elsif ( my $expect_ok = $p{expect_ok} ) {
                is( $result->state, 'checked', 'state=checked' );
                is( $result->error, undef,     'no error' );
                if ( $result->new_contents ) {
                    $source ||= path( $p{source_file} )->slurp_raw;
                    is( $result->new_contents, $source, 'same contents' );
                }
            }
            elsif ( my $expect_error = $p{expect_error} ) {
                is( $result->state, 'error', 'state=error' );
                like( $result->error || '', $expect_error, 'error message' );
            }
        }
    );
}

sub _plugin_conf {
    my $self = shift;
    my $conf = shift;

    my $plugin_class = $self->plugin_class;
    return { $plugin_class => { select => '*', %{ $conf || {} } } };
}

sub _extra_path {
    return;
}

{
    my $Perl = $^X;
    if ( $^O eq 'MSWin32' ) {

        # We need to use forward slashes to get this working with all the
        # layers of quoting in RunsCommand and IPC::Run3.
        $Perl =~ s{\\}{/}g;

        # Text::ParseWords will break on spaces later so we need to wrap the
        # path in quotes. Technically, this should be done for the *nix case
        # too, but spaces in paths are quite uncommon on Unix and we don't
        # want to risk the breakage changing this for *nix might lead to.
        $Perl = qq{"$Perl"};
    }

    sub _this_perl {
        return $Perl;
    }
}

1;
