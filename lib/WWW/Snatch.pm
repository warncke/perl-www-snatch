package WWW::Snatch;

use strict;
use warnings;

our $VERSION = '0.01';

use EV;
use AnyEvent;
use AnyEvent::Curl::Multi;
use Data::Dumper;
use HTML::Xit;
use JSON::XS;
use Scalar::Util qw(blessed reftype);
use Time::HiRes qw(sleep time);
use XML::RSS::LibXML;

use WWW::Snatch::Task;
use WWW::Snatch::TaskGroup;



sub new
{
    my $class = shift;

    my $self = {
        active_tasks => {},
    };
    bless($self, $class);

    # args may be one or more hash refs which will be
    # used to create Tasks
    $self->add_task($_) for @_;

    return $self;
}

sub active_tasks { $_[0]->{active_tasks} }

sub add_task
{
    my($self, $args) = @_;
    # require hash
    return unless ref $args
        and reftype $args eq 'HASH';
    # try to create new WWW::Snatch::Task from arg
    # task will be added to correct TaskGroup in global
    # task_groups register
    WWW::Snatch::Task->new($args)
}

sub client
{
    my($self) = @_;

    return $self->{client}
        if $self->{client};

    my $client = $self->{client} = AnyEvent::Curl::Multi->new;

    # success handler
    $client->reg_cb(response => sub {
        my($client, $request, $response, $stats) = @_;
        # get task
        my $task = delete $self->{active_tasks}->{$request}
            or return;
        # depending on either the task type or the response
        # content-type header use the appropriate parser for
        # the response content
        my($res_type, $res) = $self->parse_response($task, $response);

        if ($res) {
            # call response handler
            $task->success($res_type, $res, $request, $response, $stats);
        }
        else {
            $task->error($request, "PARSE ERROR: $@", $stats);
        }

        $task->delete;
    });

    # error handler
    $client->reg_cb(error => sub {
        my($client, $request, $errmsg, $stats) = @_;
        # get task
        my $task = delete $self->{active_tasks}->{$request}
            or return;
        # call response handler
        $task->error($request, $errmsg, $stats);

        $task->delete;
    });

    return $self->{client};
}

sub exit { $_[0]->{exit} }

sub max_concurrency
{
    my($self, $val) = @_;

    $self->{max_concurrency} = $val
        if defined $val;

    return $self->{max_concurrency} ||= 10;
}

sub parse_response
{
    my($self, $task, $response) = @_;
    # get type, using explicitly set type first
    my $type = $task->type || $response->header('Content-Type');

    my($res_type, $res);

    if ($type =~ m{html}i) {
        $res_type = 'html';
        $res = eval { HTML::Xit->new( $response->content ) };
    }
    elsif ($type =~ m{javascript}i) {
        $res_type = 'javascript';
        $res = eval { JSON::XS->new->utf8->decode( $response->content ) };
    }
    elsif ($type =~ m{rss}i) {
        $res_type = 'rss';
        $res = eval { XML::RSS::LibXML->new->parse( $response->content ) };
    }
    else {
        $res_type = 'test';
        $res = $response->content;
    }

    return($res_type, $res);
}

sub run
{
    my($self) = @_;

    while (!$self->exit) {
        # start running any pending tasks
        $self->run_tasks;
        # enter event loop
        EV::run EV::RUN_ONCE;
    }
}

sub run_task
{
    my($self, $task) = @_;
    warn "GET " . $task->request->uri;
    # add request to Curl::AnyEvent::Multi active set
    $task->{handle} = $self->client->request($task->request);
    # add task to active tasks
    $self->active_tasks->{$task->request} = $task;
}

sub run_tasks
{
    my($self) = @_;

    ACTIVE:
    while (keys %{$self->active_tasks} < $self->max_concurrency)
    {
        my $run = 0;
        # loop through task group(s) pull next task from queue on
        # each
        for my $task_group ( values %{$self->task_groups} )
        {
            # get next task from queue
            my $task = $task_group->get_task
                or next;
            # keep run tasks
            $run++;
            # run task
            $self->run_task($task);
            # break outer loop if we have reach max active
            last ACTIVE
                if keys %{$self->active_tasks} == $self->max_concurrency;
        }
        # if looping through task groups did not find any
        # new tasks to add then break outer loop
        last ACTIVE
            if $run == 0;
    }

    # if we have gone through all task groups and we have
    # no active tasks then it is time to exit.  In the future
    # this will be modified to take into account task groups that
    # still have items in queue but are waiting on delays
    $self->{exit} = 1
        if keys %{$self->active_tasks} == 0;
}

sub task_groups { $WWW::Snatch::TaskGroup::task_groups }

__END__

=head1 NAME

WWW::Snatch - Async HTTP Agent using AnyEvent::Curl::Multi

=head1 SYNOPSIS

    my $snatch = WWW::Snatch->new({
        request => "http://jobs.perl.org",
        success => sub {
            my($snatch, $res) = @_;

        },
        error => sub {
            my($snatch, $err) = @_;
        },
    });

    $snatch->run();

=head1 DESCRIPTION

=head1 METHODS

=over 4

=back

=head1 SEE ALSO

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

