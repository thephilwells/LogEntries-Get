package LogEntries::Query;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    return $self;
}

sub newUrl {
    my ($self, $log_key, $start_time, $end_time, $query)  = @_;
    return "https://rest.logentries.com/query/logs/"
           .$log_key
           ."?from="
           .$start_time
           ."&to="
           .$end_time
           ."&query="
           .$query;
}

1;