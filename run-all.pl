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

system <<HERE;

rm -rf /usr/share/cpanparty/$p.install.ok

sparrow plg install $p 1> /usr/share/cpanparty/$p.install.txt 2>&1 && \
touch /usr/share/cpanparty/$p.install.ok

echo 'sparrow index update' > /usr/share/cpanparty/$p.howto.txt
echo 'sparrow plg install $p' >> /usr/share/cpanparty/$p.howto.txt
echo 'sparrow plg run $p' >> /usr/share/cpanparty/$p.howto.txt

HERE

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
my $report="/usr/share/cpanparty/$p.html";

system <<HERE;

export port=$port

export pid_file=/tmp/app_$port 

truncate -s 0 $report

echo '<link rel="stylesheet" type="text/css" href="cpanparty.css" media="screen" />' >> $report
echo '<head><title>cpanparty test report. $p for $m</title></head>' >> $report

if test -f ~/sparrow/plugins/public/$p/app.psgi; then

    echo "### tested application code" >> $report
    echo  >> $report
    echo '<pre class="code">' >> $report
    cat ~/sparrow/plugins/public/$p/app.psgi  >> $report
    echo '</pre>' >> $report
    echo  >> $report
    echo  >> $report

elif test -f ~/sparrow/plugins/public/$p/app.pl; then

    echo "### tested application code" >> /usr/share/cpanparty/$p.html
    echo  >> $report
    echo '<pre class="code">' >> $report
    cat ~/sparrow/plugins/public/$p/app.pl  >> $report
    echo '</pre>' >> $report
    echo  >> $report
    echo  >> $report

fi

if test -f ~/sparrow/plugins/public/$p/config.yml; then

    echo "### tested application config" >> $report
    echo  >> $report
    echo '<pre class="config">' >> $report
    cat ~/sparrow/plugins/public/$p/config.yml  >> $report
    echo '</pre>' >> $report
    echo  >> $report
    echo  >> $report

elif test -f ~/sparrow/plugins/public/$p/config.yaml; then

    echo "### tested application config" >> $report
    echo  >> $report
    echo '<pre class="config">' >> $report
    cat ~/sparrow/plugins/public/$p/config.yaml  >> $report
    echo '</pre>' >> $report
    echo  >> $report
    echo  >> $report

fi

export outth_show_story=1

#export swat_disable_color=1

export match_l=1000

export swat_purge_cache=1


echo  '<pre>' >> $report

sparrow plg run $p | ansi2html >> $report

echo "</pre>" >> $report

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
	    <th> module  </th>
    	<th> status  </th> 
	    <th> install </th>
	    <th> environment </th>
	    <th> how to run </th>
    	<th> perlmalink </th> 
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

        open my $report_fh, "/usr/share/cpanparty/$p.html" or die $!;
        my $report_summary = join "<br>", (<$report_fh>)[-2];
        close $report_fh;

        open my $cpansnap_fh, sparrow_root()."/plugins/public/$p/cpanfile.snapshot" or die $!;
        my $cpansnap_str = join "", <$cpansnap_fh>;
        my $mod_version;
        $cpansnap_str=~/\s+$m\s+(\S+)/ and $mod_version=$1;

        close $cpanspan_fh;
        copy(sparrow_root()."/plugins/public/$p/cpanfile.snapshot", "/usr/share/cpanparty/$p.env.txt") 
            or die "Copy failed: $!";

        my $install_status = -f "/usr/share/cpanparty/$p.install.ok" ? 
            '<span class="label label-info">OK</span>' :
            '<span class="label label-warning">FAIL</span>';

        print SUMMARY<<HERE;
            <tr> 
		        <td id="$p"><nobr><small>$check_date</small></nobr></td> 
		        <td> 
                    <a href="https://sparrowhub.org/info/$p" target="_blank">$p</a><br>
                </td> 
		        <td><strong> <nobr>$m $mod_version</nobr> </strong> </td> 
		        <td> $status - 
                    <a href="$p.html" target="_blank">report</a><br>
                </td> 
		        <td>
                    $install_status - 
                    <a href="$p.install.txt" target="_blank">install log</a><br>
                </td> 
		        <td>
                    <a href="$p.env.txt" target="_blank">env</a><br>
                </td> 
		        <td>
                    <a href="$p.howto.txt" target="_blank">how to run</a><br>
                </td> 
		        <td>
                    <a href="#$p" >permalink</a><br>
                </td> 
	         </tr>

HERE

    }

    print SUMMARY <<HERE;

                </table>
            </div>
            <div class="panel-footer">
                Want to test your cpan distribution? 
                Create an issue at <a href="https://github.com/melezhik/cpanparty">cpanparty</a>!
            </div>

        </div>
    </div>

HERE

    close SUMMARY;

}
