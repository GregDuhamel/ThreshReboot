use strict;
use warnings;
use v5.25;
use Log::Log4perl qw(:easy);
use Log::Log4perl::Level;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;
use lib '/home/gduhamel/Projet/Perl/ThreshReboot/lib/';
use Natixis::GenericFunction;

BEGIN {
	use constant FALSE => 0;
	use constant TRUE  => 1;
}

END {
	my $logger = Log::Log4perl->get_logger();
	my ( $package, $filename, $line ) = caller();
	$logger->debug("Cleanning from $package at line $line from $filename");
}

sub ParsingArguments {
	my $logger;
	my $Options;
	Getopt::Long::GetOptions(
		"conf|f=s"   => \$Options->{Configuration},
		"loglevel=s" => \$Options->{LogLevel},
		'help!'      => \$Options->{Help},
		'man!'       => \$Options->{Man},
		'version'    => \$Options->{Version}
	  )
	  or die
"Can't get valid options from command line, please look at the --help option.\n";

	if ( defined $Options->{Version} ) {
		print "Modules, Perl, OS, Program info:\n";
		print "	Perl:   $]\n";
		print "	OS:     $^O\n";
		print "	$0:  v0.0.1\n";
		exit(0);
	}

	if ( defined $Options->{Help} ) {
		pod2usage( -verbose => 1 );
		exit(0);
	}

	if ( defined $Options->{Man} ) {
		pod2usage( -verbose => 2 );
		exit(0);
	}

	if ( defined $Options->{LogLevel}
		&& $Options->{LogLevel} =~
		/FATAL|WARN|OFF|INFO|DEBUG|ERROR|ALL|TRACE/i )
	{
		my $Level = Log::Log4perl::Level::to_priority( $Options->{LogLevel} );
		Log::Log4perl->easy_init($Level);
		$logger = Log::Log4perl->get_logger();
		$logger->info("LogLevel $Options->{LogLevel} defined for this run.");
	}
	else {
		Log::Log4perl->easy_init($INFO);
		$logger = Log::Log4perl->get_logger();
		$logger->info("Default LogLevel INFO defined for this run.");
	}

	if ( defined $Options->{Configuration}
		&& Natixis::GenericFunction::IsValidFile( $Options->{Configuration} ) )
	{
		$logger->info("File $Options->{Configuration} is a valid file.");
	}
	else {
		$logger->error("Please provide a valid configuration file.");
		pod2usage( -verbose => 1 );
		exit(1);
	}

	return ($Options);
}

sub Main {
	my $Options = ParsingArguments();
	my $logger  = Log::Log4perl->get_logger();
	$logger->info("Parsing arguments from command line.");
	$logger->info("Arguments parsed.");
	$logger->info("Parsing YAML file.");
	my $YAML =
	  Natixis::GenericFunction::ReadYamlFile( $Options->{Configuration} );
	unless ($YAML) {
		$logger->error("Can't parse YAML file : $Options->{Configuration}");
		exit(1);
	}
	$logger->info("YAML file : $Options->{Configuration} parsed successfully.");
	$logger->debug( Data::Dumper::Dumper( $YAML->[0] ) );
	exit(0);
}

Main();

=head1 NAME

 ThresholdCheck reboot.

=head1 SYNOPSIS

main.pl -f config.cfg [Options]

=head1 DESCRIPTION

 Search/Check/Update progression of Hedge/Stress/ on OTC and Credit files generation overnight/intraday.

=head1 OPTIONS

=over 6

=item B<--configuration | -f >

	Configuration file associated with this program. Mandatory

=item B<--loglevel>

	Log Level to apply to this program (FATAL|WARN|OFF|INFO|DEBUG|ERROR|ALL|TRACE).

=item B<--help | -h >

	Show the help output.

=item B<--man>

	Give a complete man page for this program.

=item B<--version>

	Print Modules, Perl, OS and Program information.

=back

=head1 AUTHOR

Gregory Duhamel <gregory.duhamel@outlook.com>

=head1 CREDITS

William leduc <william.leduc@natixis.com>

=head1 TESTED

 Perl    		[version 5.22]
 Perl    		[version 5.25]
 Microsoft Windows	[version 6.3.9600]
 Linux                  [all version]

=head1 BUGS

A lot of bugs not found yet.

=head1 TODO

- CPNL Monitoring.

- use Natixis::Database

=head1 UPDATES

=cut
