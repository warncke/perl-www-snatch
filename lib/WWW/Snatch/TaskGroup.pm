package WWW::Snatch::TaskGroup;

use strict;
use warnings;

use Scalar::Util qw(blessed reftype weaken);



# tasks are organized into groups by name.  Only one
# TaskGroup object per name is allowed to be created
# and changes to this TaskGroup effect all tasks
# within the group
our $task_groups = {};



sub new
{
    my($class, $args) = @_;
    # require hashref for args
    $args //= {};
    die "invalid args"
        unless ref $args && reftype $args eq 'HASH';
    # get TaskGroup name or use 'default'
    my $name = delete $args->{name} // 'default';
    # if a TaskGroup already exists for this name then return it
    return $task_groups->{$name}
        if defined $task_groups->{$name};
    # create new TaskGroup instance and add to task_groups register
    my $self = $task_groups->{$name} = {
        name => $name,
    };
    bless($self, $class);
    # queue of tasks waiting to be performed
    $self->{queue} = [];

    return $self;
}

# add_task
#
# add task to queue
sub add_task
{
    my($self, $task) = @_;
    # require valid task
    die "invalid task"
        unless blessed $task && $task->isa('WWW::Snatch::Task');
    # prevent circular ref
    weaken $task;
    # add task to end of queue
    push(@{$self->queue}, $task);
}

# get_task
#
# get next task from front of queue
sub get_task { shift @{ $_[0]->{queue} }  }

# name
#
# return TaskGroup name
sub name { $_[0]->{name} }

# queue
#
# return queue array ref
sub queue { $_[0]->{queue} }

1;
