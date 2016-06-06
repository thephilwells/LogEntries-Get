## Sample script to illustrate use of LE::Query methods

use LogEntries::Query;
use strict;
use warnings;
use Date::Parse;
use Data::Dumper;
use JSON;

my $log_key = $ENV{'LOGENTRIES_LOG_KEY'};
my $api_key = $ENV{'LOGENTRIES_API_KEY'};
my $start_time = "05/26/2016 01:10PM";
my $end_time = "05/27/2016 01:10PM";
my $query_string = "where(PWATMWEB001 AND error)";
my $uri_handshake_response;
my $handshake_response;
my $first_page_link;

## Convert time strings to epoch timestamps
## Adding the additional zeroes to convert these to ms
my $start_timestamp = str2time($start_time)."000";
my $end_timestamp = str2time($end_time)."000";

## Instantiate LogEntries Query object
my $query = LogEntries::Query->new();

## Construct logEntries handshake URL
my $url = $query->newUrl($log_key, $start_timestamp, $end_timestamp, $query_string);

## Get back a handshake_response containing the URI to your results
$handshake_response = $query->handshake($url);

## Extract the URI link to the first page of results
$first_page_link = $query->parseFirstPageLink($handshake_response);

## Poll that URI until it returns first page of results
# my $first_page = $query->getSinglePageOfResults($first_page_link);

## Parse the results and display in your own application
# my $encoded_message = $first_page->decoded_content;
# print $encoded_message;

## Get all available pages of results
my @all_events = $query->getAllResults($first_page_link);
print Dumper @all_events;

## Get X pages of results
