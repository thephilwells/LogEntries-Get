## Sample script to illustrate use of LE::Query methods

use LogEntries::Query;
use strict;
use warnings;
use Date::Parse;
use HTTP::Request::Common qw(GET);
use HTTP::Cookies;
use LWP::UserAgent;
use LWP::Protocol::https;
use Data::Dumper;
use JSON;

my $log_key = $ENV{'LOGENTRIES_LOG_KEY'};
my $api_key = $ENV{'LOGENTRIES_API_KEY'};
my $start_time = "05/26/2016 01:10PM";
my $end_time = "05/27/2016 01:10PM";
my $query_string = "where(error)";
my $uri_response;
my $response;
my $first_page_link;

## Convert time strings to epoch timestamps
## Adding the additional zeroes to convert these to ms
my $start_timestamp = str2time($start_time)."000";
my $end_timestamp = str2time($end_time)."000";

my $browser = LWP::UserAgent->new();
$browser->cookie_jar(HTTP::Cookies->new(file => "lwpcookies.txt", autosave => 1));

my $query = LogEntries::Query->new();;

my $url = $query->newUrl(
    $log_key,
    $start_timestamp,
    $end_timestamp,
    $query_string
);

## Get back a response containing the URI to your results
$response = $browser->get($url,
    "x-api-key" => $api_key,
    "Content-Type" => "application/json"
);

die "$url -- GET error: ", $response->status_line unless $response->is_success;

$first_page_link = $query->parseFirstPageLink($response);

## Poll that URI until it returns your results, as complex queries or queries spanning 
## a large set of entries may take longer to complete
my $first_page = $query->pollQueryLink($first_page_link);
my $encoded_message = $first_page->decoded_content;
print $encoded_message;

## Parse the results and display in your own application
