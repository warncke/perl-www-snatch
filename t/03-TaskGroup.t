use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Test::More;

BEGIN {
    use_ok('WWW::Snatch');
    use_ok('WWW::Snatch::Task');
    use_ok('WWW::Snatch::TaskGroup');
}

# get global task group register
my $task_groups = $WWW::Snatch::TaskGroup::task_groups;
# create new default task group
my $task_group = WWW::Snatch::TaskGroup->new();

is($task_group->name, 'default', "name default");
is_deeply($task_group->queue, [], "queue created");
is_deeply($task_groups, {default => $task_group}, "task group registered");

# create another default which should return first instance
my $task_group2 = WWW::Snatch::TaskGroup->new();
is($task_group, $task_group2, "task group singleton");

# create a new WWW::Task with no group specified which should
# add the task to the default TaskGroup
my $task = WWW::Snatch::Task->new();
# get task from queue
my $task2 = $task_group->get_task();
is($task, $task2, "task enqueue/dequeue");

done_testing();
