#!/usr/bin/perl -w
#
# part of "Käykee joka Kohassa" programming assignment 
# (c) Eli Parviainen 2019
#
use strict;
use warnings;
use CGI::Simple;
use JSON qw//;
binmode STDOUT, ":encoding(utf-8)";


my $q    = CGI::Simple->new;
my $json = $q->param('POSTDATA');

my %graphInfo = %{ JSON::decode_json($json) }; 

# representation of the graph
my @nodeList = @{$graphInfo{"nodes"}};
my @edgeList = @{$graphInfo{"edges"}};
my %ind2neighbors;
my %name2index;
for my $ind (0..$#nodeList) 
{ 
    # numeric indices to be used in neighbor lists
    $name2index{$nodeList[$ind]} = $ind; 
}

# read variables from the json data
my $startNode = $name2index{$graphInfo{"startNode"}};
my %weights = ("red"=>$graphInfo{"red"}, "green"=>$graphInfo{"green"}, "blue"=>$graphInfo{"blue"});

# graph neighbors for each nodes (n.b. edges run to both directions) 
foreach (@edgeList)
{
    my $startInd = $name2index{%{$_}{"start"}};
    my $endInd = $name2index{%{$_}{"end"}};
    $ind2neighbors{$startInd}{$endInd} = $weights{%{$_}{"color"}};
    $ind2neighbors{$endInd}{$startInd} = $weights{%{$_}{"color"}};
}



my @unvisited = (1) x ($#nodeList+1);   
my @route;
my $totalTime=0;
# recursively visit all nodes
# updates variables: route, totalTime, unvisited
visit($startNode);

my %result;
$result{"time"}=$totalTime;
$result{"route"}=\@route;

print "Content-type: text/html\n\n";
# n.b. this must be to_json, not encode_json, otherwise äö:s get messed up
my $str = JSON::to_json(\%result);

print "$str";


# ============================================================
sub visit {
    my $currentNode = $_[0];

    # mark current node as visited
    $unvisited[$currentNode]=0;

    # visit cheapest neighbors first (a<b is ascending order)
    my %allNeighbors=%{$ind2neighbors{$currentNode}};
    foreach my $nei (sort {$allNeighbors{$a} <=> $allNeighbors{$b}} keys %allNeighbors) {

	# do not revisit nodes
	if (not $unvisited[$nei]) { 
	    next; 
	}

	# record that we are entering a node
	$totalTime += $ind2neighbors{$currentNode}{$nei};
	my $step = {
	    "from" => $nodeList[$currentNode],
	    "to" => $nodeList[$nei]
	};	
	push(@route, $step);

	# recurse to the node at hand
	visit($nei);

	# record that we are returning from a node, unless the route has 
	# already visited all nodes (the route back home is not needed)
	my $numleft = 0;
	map { $numleft += $_ } @unvisited;
	if ($numleft>0) {
	    $totalTime += $ind2neighbors{$nei}{$currentNode};
	    my $step = {
		"to" => $nodeList[$currentNode],
		"from" =>  $nodeList[$nei]
	    };	
	    push(@route, $step);
	}#if
    }#foreach
}#sub
