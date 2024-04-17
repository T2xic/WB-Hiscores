#!/usr/bin/perl

use LWP::Simple;
use strict;
use warnings;

my $wh = "https://discord.com/api/webhooks/ ...";       #Discord webhook for hall of fame channel
my $admin = "https://discord.com/api/webhooks/ ...";    #Discord webhook for admins channel

my @emotes = getfile("emotes.txt");
my @skills = getfile("skills.txt");
my @activities = getfile("activities.txt");
my @users = getfile("users.txt");

my @top; #2d array containing username and kc, updated with highest kc, init to first user in list
for (my $i = 0; $i < scalar @activities + scalar @skills; $i++) {
    $top[$i][0] = $users[0];
    $top[$i][1] = 0;
}

my @maxed;
my @capers;
my @banned;
my $infernoindex;

for (my $i = 0; $i < scalar @activities; $i++) {
    if ($activities[$i] eq "TzKal-Zuk") {
    $infernoindex = $i;
    last;
    }
}


foreach my $user (@users) {
    chomp $user;
    print("checking $user\n");
    my $url = "https://secure.runescape.com/m=hiscore_oldschool/index_lite.ws?player=$user";
    my @str = split /[,\n]+/, get($url) or push(@banned, $user);
    print @str;

    for (my $i = 0; $i < scalar @skills; $i++) {
        #print "$user $skills[$i]: $str[2+$i*3]\n";
        if ($str[2+$i*3] > $top[$i][1]) {
            $top[$i][0] = $user;
            $top[$i][1] = $str[2+$i*3];
        }
        elsif ($str[2+$i*3] == $top[$i][1]) {
            $top[$i][0] .= ", $user";
        }
    }

    for (my $i = 0; $i < scalar @activities; $i++) {
    #print("$user, $activities[$i], $str[scalar @skills*3+$i*2+3], $top[$i+scalar @skills][1]\n");
        if ($str[scalar @skills*3+$i*2+3] > $top[$i+scalar @skills][1]) {
            $top[$i+scalar @skills][0] = $user;
            $top[$i+scalar @skills][1] = $str[scalar @skills*3+$i*2+3];
        }
        elsif ($str[scalar @skills*3+$i*2+3] == $top[$i+scalar @skills][1]) {
            $top[$i+scalar @skills][0] .= ", $user";
        }
    }
    #add user to @maxed if their total level is >= 2277
    if ($str[1] >= 2277) {
        push(@maxed, $user);
    }
    #add user to @capers if they have an inferno kc
    if ($str[scalar @skills * 3 + 70 * 2 + 1] >= 1) {
        push(@capers, $user);
    }
}

my $str1;
my $str2;
my $str3;
my $str4;
my $str5;
my $str6;
my $str7;

$str1 .= "## SKILLS\\n";
for (my $i = 0; $i < scalar @skills; $i++) {
    $str1 .= "$emotes[$i] $skills[$i]: **$top[$i][0]** - $top[$i][1] experience\\n";
}

$str2 .= "## BOUNTY HUNTER\\n";
for (my $i = 1; $i < 5; $i++) {
    $str2 .= "$emotes[$i+scalar @skills-1] $activities[$i]: **$top[$i+scalar @skills][0]** - $top[$i+scalar @skills][1] points\\n";
}

$str2 .= "## CLUE SCROLLS\\n";

for (my $i = 5; $i < 12; $i++) {
    $str2 .= "$emotes[$i+scalar @skills-1] $activities[$i]: **$top[$i+scalar @skills][0]** - $top[$i+scalar @skills][1] kc\\n";
}

$str2 .= "## MINIGAMES\\n";

for (my $i = 12; $i < 16; $i++) {
    $str2 .= "$emotes[$i+scalar @skills-1] $activities[$i]: **$top[$i+scalar @skills][0]** - $top[$i+scalar @skills][1]\\n";
}

$str3 .= "## BOSSES\\n";

for (my $i = 16; $i < 35; $i++) {
    $str3 .= "$emotes[$i+scalar @skills-1] $activities[$i]: **$top[$i+scalar @skills][0]** - $top[$i+scalar @skills][1] kc\\n";
}


for (my $i = 35; $i < 53; $i++) {
    $str4 .= "$emotes[$i+scalar @skills-1] $activities[$i]: **$top[$i+scalar @skills][0]** - $top[$i+scalar @skills][1] kc\\n";
}


for (my $i = 53; $i < 78; $i++) {
    $str5 .= "$emotes[$i+scalar @skills-1] $activities[$i]: **$top[$i+scalar @skills][0]** - $top[$i+scalar @skills][1] kc\\n";
}


$str6 .= "## Achievements\\n";
$str6 .= "### <:infernalcape:1126105594361823253> Infernal Cape <:infernalcape:1126105594361823253>\\n";

$str6 .= join(", ", @capers);

$str6 .= "\\n### <:maxcape:1126105935560065114> Max Cape <:maxcape:1126105935560065114>\\n";

$str6 .= join(", ", @maxed);

$str7 = "## Clan members not on hiscores:\\n";

if (@banned) {
    foreach (@banned) {
        print($_);
        $str7 .= "$_\\n";
    }
    send_message($str7, $admin);
}

    
send_message($str1, $wh);
send_message($str2, $wh);
send_message($str3, $wh);
send_message($str4, $wh);
send_message($str5, $wh);
send_message($str6, $wh);

sub getfile {
    my ($filename) = @_;
    open (my $fh, '<', $filename) or die "Could not find file '$filename' $!";
    my @array;
    
    while (my $line = <$fh>) {
        chomp($line);
        push(@array, $line);
    }
    close($fh);
    return @array;
}

sub send_message {
    my ($content, $webhook) = @_;
    my $command = qq(curl -H "Content-Type: application/json" -d '{"username": "WB", "content": "$content"}' "$webhook");
    system($command);
}

sub generate_message {
    my ($title, $start_index, $end_index, $unit, @data) = @_;
    my $str;
    $str = "## $title\\n" if $title;
    for (my $i = $start_index; $i < $end_index; $i++) {
        $str .= "$emotes[$i] $data[$i]: **$top[$i][0]** - $top[$i][1] $unit\\n";
    }
    return $str;
}
