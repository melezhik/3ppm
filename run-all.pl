BEGIN { system("sparrow index update 2>/dev/null") };


use Net::EmptyPort qw(empty_port);

next unless /\S+/;
next if /^\s*#/;

my ($p, $m ) = split;

$tests{$p} = $m;

print "running $p for $m ... \n";

system("(date; sparrow plg install $p) > /usr/share/3ppm/$p.txt");

my $port = empty_port();

system("export port=$port && export pid_file=/tmp/app_$port; sparrow plg run $p > /usr/share/3ppm/$p.txt ; echo \$? > /usr/share/3ppm/$p.status;   kill ".'`'."cat /tmp/app_$port".'`');


END {

    print "update summry report ... \n";

    open SUMMARY, ">", "/usr/share/3ppm/index.html" or die $!;

    print SUMMARY "<table>\n";

    print SUMMARY "<th> name </th> <th> module </th> status <th> link </th>\n";

    for my $p (keys %tests){
        open STATUS, "/usr/share/3ppm/$p.txt" or die $!;
        my $st = <STATUS>;
        close STATUS;
        my $status =  ( $st == 0 ) ? 'OK' : 'FAIL';
        print SUMMARY
            "<tr> <td> $p </td> <td> $tests{$p} </td> <td> $status </td> <td> <a href='$p.txt'>report</a> </td> </tr> \n";
    }

    print SUMMARY "</table>\n";
    close SUMMARY;

}
