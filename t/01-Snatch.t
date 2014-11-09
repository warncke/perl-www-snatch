use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Test::More;

BEGIN {
    use_ok('WWW::Snatch');
    use_ok('WWW::Snatch::Task');
    use_ok('WWW::Snatch::TaskGroup');
}

my $snatch = WWW::Snatch->new({
    request => "http://jobs.perl.org",
    success => sub {
        my($snatch, $res_type, $res) = @_;
        is($res_type, 'html', 'res_type');
        isa_ok($res, 'HTML::Xit', 'res');
    },
    error => sub {
        my($snatch, $err) = @_;
        warn $err;
    },
});

$snatch->run();

done_testing();
