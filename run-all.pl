BEGIN { 
    if (!$ENV{skip_test} and !$ENV{skip_index_update}){
        system("sparrow index update 2>/dev/null") 
    }
};


use Net::EmptyPort qw(empty_port);
use Time::Piece;
use Sparrow::Constants;
use File::Copy;

next unless /\S+/;
next if /^\s*#/;

my ($p, $m ) = split;

push @tests, [$p, $m];

next if $ENV{skip_test};

print "processing $p for $m ... \n";

print "calculating test suite check sum ... \n";

if ( -d sparrow_root()."/plugins/public/$p" ){
    system('find '.sparrow_root()."/plugins/public/$p". ' -type f \( -not -iname 02packages.details.txt \)  -print0 | xargs -0 md5sum > /tmp/a.txt');
}else{
    print "plugin not installed ... skip check sum calculation\n";
    system("echo > /tmp/a.txt");
}

print "updating plugin ... \n";

system("sparrow plg install $p");

print "calculating test suite check sum after update ... \n";

system('find '.sparrow_root()."/plugins/public/$p". ' -type f \( -not -iname 02packages.details.txt \)  -print0 | xargs -0 md5sum > /tmp/b.txt');


if ( ! system('diff -q /tmp/a.txt /tmp/b.txt') ){
    
    if ($ENV{run_old_tests}){
        print "test suite is uptodate - continue due to run_old_tests  \n";
    }else{
        print "test suite is uptodate - skip test run \n";
        next;
    }
}

print "running $p test suite for $m ... \n";

my $port = empty_port();

system <<HERE;

export port=$port

export pid_file=/tmp/app_$port 


echo  >> /usr/share/cpanparty/$p.txt

echo  >> /usr/share/cpanparty/$p.txt

if test -f ~/sparrow/plugins/public/$p/app.psgi; then

    echo "### tested application code " > /usr/share/cpanparty/$p.txt
    echo  >> /usr/share/cpanparty/$p.txt
    cat ~/sparrow/plugins/public/$p/app.psgi  >> /usr/share/cpanparty/$p.txt
    echo  >> /usr/share/cpanparty/$p.txt
    echo  >> /usr/share/cpanparty/$p.txt

elif test -f ~/sparrow/plugins/public/$p/app.pl; then

    echo "### tested application code " > /usr/share/cpanparty/$p.txt
    echo  >> /usr/share/cpanparty/$p.txt
    cat ~/sparrow/plugins/public/$p/app.pl  >> /usr/share/cpanparty/$p.txt
    echo  >> /usr/share/cpanparty/$p.txt
    echo  >> /usr/share/cpanparty/$p.txt

fi


sparrow plg run $p >> /usr/share/cpanparty/$p.txt

echo \$? > /usr/share/cpanparty/$p.status

kill `cat /tmp/app_$port`

rm /tmp/app_$port

HERE



END {

    print "update summry report ... \n";

    open SUMMARY, ">", "/usr/share/cpanparty/index.html" or die $!;


print SUMMARY <<HERE;

<head>
    <title>CPANParty - Third Party Tests for CPAN Modules</title>
    <meta content="text/html;charset=utf-8" http-equiv="Content-Type">
    <meta content="utf-8" http-equiv="encoding">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap-theme.min.css">
    <script src="https://code.jquery.com/jquery-2.1.4.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
</head>

HERE

    print SUMMARY<<HERE;

    <div class="container">
	    <div class="panel panel-default">
            <div class="panel-heading">
                CPANParty - Third Party Tests for CPAN Modules ... There is more than one way to test it!
            </div>
            <div class="panel-body">
	            <table class="table">
HERE

    print SUMMARY<<HERE;
	    <th> check date </th> 
    	<th> test suite </th> 
	    <th> module </th>
    	<th> status </th> 
	    <th> report </th>
	    <th> environment </th>
    	<th> summary </th> 
HERE

    for my $t (@tests){

        my $p = $t->[0];
        my $m = $t->[1];

        open my $status_fh, "/usr/share/cpanparty/$p.status" or die $!;
        my $st = <$status_fh>;
        close $status_fh;
        my @s = stat("/usr/share/cpanparty/$p.status"); 

    	my $check_date = gmtime($s[9])->strftime("%d %b %Y %H:%M");
        my $status =  ( $st == 0 ) ? 
		'<span class="label label-success">Passed</span>' : 
		'<span class="label label-danger">Failed</span>';
   	    my $st_class = ( $st == 0 ) ? 'success' : 'danger';

        open my $report_fh, "/usr/share/cpanparty/$p.txt" or die $!;
        my $report_summary = join "<br>", (<$report_fh>)[-2];
        close $report_fh;

        open my $cpansnap_fh, sparrow_root()."/plugins/public/$p/cpanfile.snapshot" or die $!;
        my $cpansnap_str = join "", <$cpansnap_fh>;
        my $mod_version;
        $cpansnap_str=~/\s+$m\s+(\S+)/ and $mod_version=$1;

        close $cpanspan_fh;
        copy(sparrow_root()."/plugins/public/$p/cpanfile.snapshot", "/usr/share/cpanparty/$p.env.txt") 
            or die "Copy failed: $!";

        print SUMMARY<<HERE;
            <tr> 
		        <td><nobr><small>$check_date</small></nobr></td> 
		        <td> 
                    <a href="https://sparrowhub.org/info/$p" target="_blank">$p</a><br>
                </td> 
		        <td><strong> <nobr>$m $mod_version</nobr> </strong> </td> 
		        <td> $status </td>
		        <td>
                    <a href="$p.txt" target="_blank">view</a><br>
                </td> 
		        <td>
                    <a href="$p.env.txt" target="_blank">view</a><br>
                </td> 
                <td class="breadcrumb"><small>$report_summary</small><td>
	         </tr>

HERE

    }

    print SUMMARY <<HERE;

                </table>
            </div>
            <div class="panel-footer">
                Want to test your cpan distribution? 
                Create an issue at <a href="https://github.com/melezhik/cpanparty">cpanparty</a>!
                </a>
            </div>

        </div>
    </div>

HERE

    close SUMMARY;

}
