## Sample script to illustrate use of LE::Query methods

use LogEntries::Query;
use strict;
use warnings;
use Date::Parse;
use Data::Dumper;
use JSON;

my @log_keys = [];
push @log_keys, $ENV{'LOGENTRIES_LOG_KEY'};
my $api_key = $ENV{'LOGENTRIES_API_KEY'};
my $start_time = "07/10/2016 06:24PM";
my $end_time = "07/17/2016 06:24PM";
my $query_string = "where(*)";
my $uri_handshake_response;
my $handshake_response;
my $first_page_link;

## Convert time strings to epoch timestamps
## Adding the additional zeroes to convert these to ms
my $start_timestamp = str2time($start_time)."000";
my $end_timestamp = str2time($end_time)."000";

## Instantiate LogEntries Query object
my $query = LogEntries::Query->new();

## Get back a handshake_response containing the URI to your results

$handshake_response = $query->handshake($api_key, \@log_keys, $start_timestamp,
    $end_timestamp, $query_string);

## Extract the URI link to the first page of results
$first_page_link = $query->parseResultPageLink($handshake_response);

# # Poll that URI until it returns first page of results
# my $first_page = $query->getSinglePageOfResults($api_key, $first_page_link);

# # Parse the results and display in your own application
# my $encoded_message = $first_page->decoded_content;
# print "!! first page of result: $encoded_message\n";

## Get all available pages of results
my @all_events = $query->getAllResults($api_key, $first_page_link);
print Dumper @all_events;
