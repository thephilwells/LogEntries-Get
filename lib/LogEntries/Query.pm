package LogEntries::Query;

use strict;
use warnings;
use HTTP::Request::Common qw(GET);
use HTTP::Cookies;
use LWP::UserAgent;
use LWP::Protocol::https;
use JSON;
use Data::Dumper;

my @log_keys;

my $browser = LWP::UserAgent->new();
$browser->cookie_jar(
    HTTP::Cookies->new(file => "lwpcookies.txt", autosave => 1)
);

my $queryUrl = "https://rest.logentries.com/query/logs/";

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    return $self;
}

## As some queries may take a little longer to return results, this first call 
## to the API will return  a new URI to my results, rather than keep the 
## connection open until the results are ready. When you hit the results URI, I
## will get back a “continue” URI until the results are ready. This reduces the
## risk of timeouts.
sub handshake {
    my ($self, $api_key, $log_keys, $start_timestamp,
        $end_timestamp, $query_string) = @_;

    @log_keys = @{ $log_keys };
    print "!! LINE 34 log_keys: ".$log_keys[0]."\n";

    my $payload = __buildPayload($start_timestamp,
        $end_timestamp, $query_string);
    
    my $response = $browser->post($queryUrl,
        "x-api-key" => $api_key,
        "Content-Type" => "application/json",
        "Content" => $payload
    );
    die "$queryUrl -- POST error: ",
        $response->status_line unless $response->is_success;
    return $response;
}

## Helper method to retrieve the results URI from the query response.
sub parseResultPageLink {
    my ($self, $response) = @_;
    
    my $encoded_message = $response->decoded_content;
    my $message = decode_json($encoded_message);
    my @first_page_links = $message->{"links"};
    return $first_page_links[0][0]{'href'};
}

## Helper method to retrieve an array of events from the query response.
sub parseResultPageEvents {
    my ($self, $response) = @_;

    my $encoded_message = $response->decoded_content;
    my $message = decode_json($encoded_message);
    my @events_on_page = $message->{"events"};
    return @events_on_page;
}

## Helper method to decode the JSON response
sub decodeResponse {
    my ($self, $response) = @_;

    my $encoded_message = $response->decoded_content;
    my $message = decode_json($encoded_message);
    return $message;
}

## Use the results URI to get a page of log results, including the liurlnk to
## the next page
sub getSinglePageOfResults {
    my ($self, $api_key, $url) = @_;
    ## Send a GET to our query url
    my $response = $browser->get($url,
        "x-api-key" => $api_key,
        "Content-Type" => "application/json"
    );
    die "$url -- GET error: ",
        $response->status_line unless $response->is_success;
    return $response;
}

## Helper method to iterate through all results pages for a query and return
## them as one big array.
sub getAllResults {
    my ($self, $api_key, $first_page_link) = @_;
    
    my @all_events;
    my $next_page_link = $first_page_link;
    my $last_link = '';
    do {
        my $response = $self->getSinglePageOfResults($api_key, $next_page_link);
        # my $message = decodeResponse($response);
        my $encoded_message = $response->decoded_content;
        my $message = decode_json($encoded_message);
        my @next_page_links = $message->{"links"};
        my @events_on_page = $message->{"events"};
        $next_page_link =  $next_page_links[0][0]{'href'};
        if (defined $next_page_link && $next_page_link ne $last_link) {
            push @all_events, @events_on_page;
            $last_link = $next_page_link;
        }
    } while ( defined $next_page_link );
    return @all_events;
}

sub __buildPayload {
    my ($start_timestamp, $end_timestamp, $query_string) = @_;

    my %payloadHash = (
        logs => @log_keys,
        leql => {
            during => {
                from => $start_timestamp,
                to => $end_timestamp
            },
            statement => $query_string
        }
    );

    ## convert hash to json string
    my $payload =  to_json(\%payloadHash);

    ## if only one log is in @log_keys, it doesn't get brackets,
    ## so we need to interpolate them here
    print "initial payload: ".$payload."\n";
    $payload =~ s/"logs":("\S+")/"logs":[$1]/;
    return $payload;
}

1;