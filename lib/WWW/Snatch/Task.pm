package WWW::Snatch::Task;

use strict;
use warnings;

use HTTP::Request;
use Scalar::Util qw(blessed reftype);

use WWW::Snatch::TaskGroup;



sub new
{
    my($class, $args) = @_;
    # require hashref for args
    $args //= {};
    die "invalid args"
        unless ref $args && reftype $args eq 'HASH';
    # create new Task instance
    my $self = {};
    bless($self, $class);
    # get TaskGroup from args if passed
    $self->group( delete $args->{group} );
    # add Task to TaskGroup
    $self->group->add_task($self);
    # copy properties
    for my $arg ( qw(error success type) ) {
        $self->{$arg} = delete $args->{$arg};
    }
    # copy properties with setters
    for my $arg ( qw(request) ) {
        $self->$arg( delete $args->{$arg} );
    }

    return $self;
}

# delete
#
# empty task
sub delete
{
    my($self) = @_;

    delete $self->{$_} for keys %$self;
}

# error
#
# error callback
sub error
{
    my($self) = @_;
    # need a code ref to call
    return unless defined $self->{error}
        and reftype $self->{error} eq 'CODE';

    goto &{$self->{error}};
}

# group
#
# TaskGroup object for this task
sub group
{
    my($self, $group) = @_;

    if (defined $group) {
        # if group is passed then create a new TaskGroup
        return $self->{group} = WWW::Snatch::TaskGroup->new($group);
    }
    else {
        # return existing group or create or get default TaskGroup
        return $self->{group} ||= WWW::Snatch::TaskGroup->new();
    }
}

# handle
#
# AnyEvent::Curl::Multi handle
sub handle { $_[0]->{handle} }

# request
#
# get/set HTTP::Request for Task
sub request
{
    my($self, $request) = @_;

    if (defined $request) {
        # request may be HTTP::Request object
        if ( blessed $request && $request->isa("HTTP::Request") ) {
            $self->{request} = $request;
        }
        # otherwise try to create HTTP::Request
        else {
            $self->{request} = HTTP::Request->new(GET => $request);
        }
    }

    return $self->{request}
}

# success
#
# success callback
sub success
{
    my($self, $success) = @_;
    # need a code ref to call
    return unless defined $self->{success}
        and reftype $self->{success} eq 'CODE';

    goto &{$self->{success}};
}

# type
#
# response type (html, json, rss)
sub type { $_[0]->{type} }


1;
