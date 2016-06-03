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
my $json_response;
my $next_page_link;

## Convert time strings to epoch timestamps
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

# $browser->header();
$json_response = $browser->get($url,
    "x-api-key" => $api_key,
    "Content-Type" => "application/json"
);

my $message = $json_response->decoded_content;

print $message."\n";;

## Get back a response containing the URI to your results

## Poll that URI until it returns your results, as complex queries or queries spanning a large set of entries may take longer to complete

## Parse the results and display in your own application
