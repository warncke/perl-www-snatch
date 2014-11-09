use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok('WWW::Snatch');
    use_ok('WWW::Snatch::Task');
    use_ok('WWW::Snatch::TaskGroup');
}

done_testing();
