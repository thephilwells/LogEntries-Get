package LogEntries::Query;

use strict;
use warnings;
use HTTP::Request::Common qw(GET);
use HTTP::Cookies;
use LWP::UserAgent;
use LWP::Protocol::https;
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

sub handshake {
    my ($self, $url) = @_;
    
    my $response = $browser->get($url,
        "x-api-key" => $api_key,
        "Content-Type" => "application/json"
    );
    die "$url -- GET error: ", $response->status_line unless $response->is_success;
    return $response;
}

sub parseFirstPageLink {
    my ($self, $response) = @_;
    
    my $encoded_message = $response->decoded_content;
    my $message = decode_json($encoded_message);
    my @first_page_links = $message->{"links"};
    return $first_page_links[0][0]{'href'};
}

sub getSinglePageOfResults {
    my ($self, $link) = @_;
    ## Send a GET to our query link
    my $response = $browser->get($link,
        "x-api-key" => $api_key,
        "Content-Type" => "application/json"
    );
    die "$link -- GET error: ", $response->status_line unless $response->is_success;
    return $response;
}

sub getAllResults {
    my ($self, $first_page_link) = @_;
    
    my @all_events;
    my $next_page_link = $first_page_link;
    my $last_link = '';
    do {
        my $response = $self->getSinglePageOfResults($next_page_link);
        my $encoded_message = $response->decoded_content;
        my $message = decode_json($encoded_message);
        my @next_page_links = $message->{"links"};
        my @events_on_page = $message->{"events"};        
        $next_page_link =  $next_page_links[0][0]{'href'};
        sleep(2); ## Throttle, trying to prevent 503 errors, not much luck
        if (defined $next_page_link && $next_page_link ne $last_link) {
            push @all_events, @events_on_page;
            $last_link = $next_page_link;
            print "line 83: next_page_link: ".$next_page_link."\n"; ## Debug, remove for release
        }
    } while ( defined $next_page_link );
    return @all_events;
}

1;