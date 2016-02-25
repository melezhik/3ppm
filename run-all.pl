BEGIN { 
    if (!$ENV{skip_test} and !$ENV{skip_index_update}){
        system("sparrow index update 2>/dev/null") 
    }
};


use Net::EmptyPort qw(empty_port);
use Time::Piece;
use Sparrow::Constants;

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

export prove_options="'-P HTML=outfile:/usr/share/cpanparty/$p.html,css_uri:style.css,js_uri:foo.js,force_inline_css:0'"

sparrow plg run $p >> /usr/share/cpanparty/$p.txt

echo \$? > /usr/share/cpanparty/$p.status

kill `cat /tmp/app_$port`

HERE



END {

    print "update summry report ... \n";

    open SUMMARY, ">", "/usr/share/cpanparty/index.html" or die $!;


print SUMMARY <<HERE;

<head>
    <title>cpanparty.org - Third Party Tests for CPAN modules</title>
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
            <div class="panel-heading">CPAN Party Test Reports </div>
            <div class="panel-body">
	            <table class="table table-stripped">
HERE

    print SUMMARY<<HERE;
	    <th> check date </th> 
    	<th> test suite </th> 
	    <th> module </th>
    	<th> status </th> 
	    <th> report </th>
    	<th> summary </th> 
HERE

    for my $t (@tests){

        my $p = $t->[0];
        my $m = $t->[1];

        open my $status_fh, "/usr/share/cpanparty/$p.status" or die $!;
        my $st = <$status_fh>;
        close $status_fh;
        my @s = stat("/usr/share/cpanparty/$p.status"); 

    	my $check_date = gmtime($s[9])->strftime("%d %b %Y %H:%S");
        my $status =  ( $st == 0 ) ? 
		'<span class="label label-success">Passed</span>' : 
		'<span class="label label-danger">Failed</span>';
   	    my $st_class = ( $st == 0 ) ? 'success' : 'danger';

        open my $report_fh, "/usr/share/cpanparty/$p.txt" or die $!;
        my $report_summary = join "<br>", (<$report_fh>)[-2];
        close $report_fh;

        print SUMMARY<<HERE;
            <tr> 
		        <td><small>$check_date</small></td> 
		        <td> $p </td> 
		        <td><strong> $m </strong> </td> 
		        <td> $status </td>
		        <td>
                    <a href="$p.txt" target="_blank">text</a><br>
                    <a href="$p.html" target="_blank">html</a>
                </td> 
                <td class="breadcrumb"><small>$report_summary</small><td>
	         </tr>

HERE

    }

    print SUMMARY "</table></div></div></div>\n";
    close SUMMARY;

}
