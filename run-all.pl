BEGIN { system("sparrow index update 2>/dev/null") unless $ENV{skip_test}};


use Net::EmptyPort qw(empty_port);
use Date::Format;
use File::stat;

next unless /\S+/;
next if /^\s*#/;


my ($p, $m ) = split;

$tests{$p} = $m;

next if $ENV{skip_test};

print "running $p for $m ... \n";

system("(date; sparrow plg install $p) > /usr/share/3ppm/$p.txt");

my $port = empty_port();

system("export port=$port && export pid_file=/tmp/app_$port; sparrow plg run $p > /usr/share/3ppm/$p.txt ; echo \$? > /usr/share/3ppm/$p.status;   kill ".'`'."cat /tmp/app_$port".'`');


END {

    print "update summry report ... \n";

    open SUMMARY, ">", "/usr/share/3ppm/index.html" or die $!;


print SUMMARY <<HERE;

<!-- Latest compiled and minified CSS -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">

<!-- Optional theme -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css" integrity="sha384-fLW2N01lMqjakBkx3l/M9EahuwpSfeNvV63J5ezn3uZzapT0u7EYsXMjQV+0En5r" crossorigin="anonymous">

<!-- Latest compiled and minified JavaScript -->
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js" integrity="sha384-0mSbJDEHialfmuBBQP6A4Qrprq5OVfW37PRR3j5ELqxss1yVqOtnepnHVP9aJ7xS" crossorigin="anonymous"></script>

HERE

    print SUMMARY "<table class='table table-stripped'>\n";

    print SUMMARY "
	<th> test suite </th> 
	<th> module </th>
	<th> status </th> 
	<th> report </th>\n";

    for my $p (keys %tests){
        open my $status_fh, "/usr/share/3ppm/$p.status" or die $!;
        my $st = <$status_fh>;
        close $status_fh;
	my @stat = stat("/usr/share/3ppm/$p.status");
	my $check_date = time2str("%Y/%m/%d %T\n", $stat[0][9]);
        my $status =  ( $st == 0 ) ? 'OK' : 'FAIL';
	my $st_class = ( $st == 0 ) ? 'success' : 'danger';
        print SUMMARY
            "<tr> 
		<td> $p </td> 
		<td> $tests{$p} </td> 
		<td class='$st_class'> $status </td>
		<td> <a href='$p.txt'>$check_date</a> </td> 
	    </tr> \n";
    }

    print SUMMARY "</table>\n";
    close SUMMARY;

}
