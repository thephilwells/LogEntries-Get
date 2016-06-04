package LogEntries::Query;

use strict;
use warnings;
use JSON;

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

sub getFirstPageLink {
    my ($self, $response) = @_;
    my $encoded_message = $response->decoded_content;
    my $message = decode_json($encoded_message);
    my @first_page_links = $message->{"links"};
    return $first_page_links[0][0]{'href'};
}

1;