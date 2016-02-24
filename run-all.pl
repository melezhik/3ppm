BEGIN { system("sparrow index update") };

use Net::EmptyPort qw(empty_port);

next unless /\S+/;
next if /^\s*#/;

my ($p, $m ) = split;


print "running $p for  $m ... \n";
system("sparrow plg install $p");

my $port = empty_port();

print "\n-------\n";
print "http port: $port\n";

system("export port=$port && export pid_file=/tmp/app_$port; sparrow plg run $p; kill ".'`'."cat /tmp/app_$port".'`');


