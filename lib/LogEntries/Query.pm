package LogEntries::Query;

use strict;
use warnings;
use HTTP::Request::Common qw(GET);
use HTTP::Cookies;
use LWP::UserAgent;
use JSON;
use Async;

my $browser = LWP::UserAgent->new();
$browser->cookie_jar(HTTP::Cookies->new(file => "lwpcookies.txt", autosave => 1));
my $api_key = $ENV{'LOGENTRIES_API_KEY'};

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

sub parseFirstPageLink {
    my ($self, $response) = @_;
    
    my $encoded_message = $response->decoded_content;
    my $message = decode_json($encoded_message);
    my @first_page_links = $message->{"links"};
    return $first_page_links[0][0]{'href'};
}

sub pollQueryLink {
    my ($self, $link) = @_;
    ## Send a GET to our query link
    my $response = $browser->get($link,
        "x-api-key" => $api_key,
        "Content-Type" => "application/json"
    );
    die "$link -- GET error: ", $response->status_line unless $response->is_success;
    return $response;
}

1;