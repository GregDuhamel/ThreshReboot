package Natixis::DataBaseUtils;

use strict;
use warnings;
use DBI;
use String::Util qw(trim);
use Log::Log4perl qw(:easy);
use Log::Log4perl::Level;
use lib '/home/gduhamel/Projet/Perl/ThreshReboot/lib/';
use Natixis::GenericFunction qw(GetSysTime);

BEGIN {
	require Exporter;
	our $VERSION = 2.0;
	use base qw(Exporter);
	our @EXPORT_OK = qw(Connect QueryAllRecords Disconnect Commit);
	use constant ERROR => 0;
	use constant TRUE  => 1;
}

sub new {
	my $class = shift;

	my (
		$Techno,   $Driver,  $DataBase, $Host, $Login,
		$Password, $Options, $LogLevel, $logger
	) = @_;

	my $self = bless {
		Techno   => $Techno,
		Driver   => $Driver,
		DataBase => $DataBase,
		Host     => $Host,
		Login    => $Login,
		Password => $Password,
		Options  => $Options,
		LogLevel => $LogLevel
	}, $class;

	if ( defined $self->{LogLevel}
		&& $self->{LogLevel} =~ /FATAL|WARN|OFF|INFO|DEBUG|ERROR|ALL|TRACE/i )
	{
		my $Level = Log::Log4perl::Level::to_priority( $self->{LogLevel} );
		Log::Log4perl->easy_init($Level);
	}
	else {
		Log::Log4perl->easy_init($INFO);
	}

	unless ( $self->initialize() ) {
		$self = undef;
		return (ERROR);
	}

	return $self;
}

sub BuildConString {
	my $self   = shift;
	my $logger = Log::Log4perl->get_logger();

	if ( $self->{'Driver'} =~ /^ODBC/i ) {
		$logger->info("Using ODBC ...");

		$self->{'ConString'} = "dbi:ODBC:$self->{'DataBase'}";
		$self->{'ConString'} = trim( $self->{'ConString'} );

		$logger->info("ConString Build : $self->{'ConString'}");
	}
	elsif ( $self->{'Driver'} =~ /^DRIVER/i ) {
		$logger->info("Using direct DBI driver ....");

		$self->{'Techno'} = lc( $self->{'Techno'} );

		$self->{'ConString'} =
		  "DBI:$self->{'Techno'}:database=$self->{'DataBase'}";
		$self->{'ConString'} = trim( $self->{'ConString'} );
	}
	else {
		$logger->info(
"Driver => $self->{'Driver'} is not yet available (use DRIVER/ODBC)."
		);
		$self->{'Blocked'} = 1;
		return (ERROR);
	}
	return (TRUE);
}

sub initialize {
	my $self   = shift;
	my $logger = Log::Log4perl->get_logger();

	unless ( defined $self->{'Techno'} ) {
		$self->{'Blocked'} = 1;
		$logger->error(
			"Missing parameter Techno, (should be sybase,mysql,sqlserver, ...)"
		);
		$logger->debug("End of initialize function.");
		return (ERROR);
	}

	unless ( defined $self->{'Driver'} ) {
		$self->{'Blocked'} = 1;
		$logger->error("Missing parameter Driver, (should be ODBC,DRIVER ...)");
		$logger->debug("End of initialize function.");
		return (ERROR);
	}

	unless ( defined $self->{'DataBase'} ) {
		$self->{'Blocked'} = 1;
		$logger->error(
			"Missing parameter DataBase (should be SX_TP_FR, SP_TP_FR2 ...");
		$logger->debug("End of initialize function.");
		return (ERROR);
	}

	unless ( $self->BuildConString() ) {
		$self->{'Blocked'} = 1;
		return (ERROR);
	}

	$self->{'Blocked'} = 0;
	return (TRUE);
}

sub Connect {
	my $self   = shift;
	my $logger = Log::Log4perl->get_logger();

	if ( not exists $self->{'Blocked'} || $self->{'Blocked'} == 1 ) {
		$logger->warn("Can't connect to $self->{'DataBase'} ...");
		return (ERROR);
	}

	if ( $self->{'Driver'} =~ /^ODBC/i ) {
		unless ( defined $self->{'Options'} ) {
			$self->{'DBHandle'} =
			  DBI->connect( $self->{'ConString'}, $self->{'Login'},
				$self->{'Password'} );
		}
		$self->{'DBHandle'} = DBI->connect(
			$self->{'ConString'}, $self->{'Login'},
			$self->{'Password'},  $self->{'Options'}
		);
	}
	elsif ( $self->{'Driver'} =~ /^DRIVER/i ) {
		unless ( defined $self->{'Options'} ) {
			$self->{'DBHandle'} =
			  DBI->connect( "$self->{'ConString'};$self->{'Host'}",
				$self->{'Login'}, $self->{'Password'} );
		}
		$self->{'DBHandle'} =
		  DBI->connect( "$self->{'ConString'};$self->{'Host'}",
			$self->{'Login'}, $self->{'Password'}, $self->{'Options'} );
	}

	unless ( defined $self->{'DBHandle'} ) {
		$self->{'Blocked'} = 1;
		$logger->error(
			"Can't connect to $self->{'DataBase'} with Login : $self->{'Login'}"
		);
		$logger->error("Following error catched : $DBI::errstr");
		$logger->debug("End of SybaseConnect function.");
		return (ERROR);
	}

	$self->{'Blocked'} = 0;
	$logger->info(
		"Connected to $self->{'DataBase'} with Login : $self->{'Login'}");
	$logger->debug("End of SybaseConnect function.");
	return (TRUE);
}

# Request database and return the first row returned.
sub QueryAllRecords {
	my $self   = shift;
	my $logger = Log::Log4perl->get_logger();

	my $SqlRequest = shift;

	if ( not defined $self->{'Blocked'} || $self->{'Blocked'} == 1 ) {
		$logger->warn("Not connected to $self->{'DataBase'} ...");
		return (ERROR);
	}

	my $Sth = $self->{'DBHandle'}->prepare($SqlRequest);

	unless ($Sth) {
		$logger->error("Failed to prepare Following request : $SqlRequest");
		$logger->error("Following error catched : $self->{DBHandle}->errstr");
		$logger->debug("End of QueryAllRecords function.");
		return (ERROR);
	}

	$logger->info("Following request is now prepared : $SqlRequest");
	$logger->info("Executing ...");

	my $Res = $Sth->execute();

	if ( $Sth->{NUM_OF_FIELDS} > 0 ) {
		unless ($Res) {
			$logger->error("Failed to execute the request");
			$logger->error("Following error catched : $Sth->errstr");
			$logger->debug("End of QueryAllRecords function.");
			return (ERROR);
		}
		$logger->info("Request successfully executed.");
	}
	else {
		unless ( $Res && $Res > 0 ) {
			$logger->error("Failed to execute the request");
			$logger->error("Following error catched : $Sth->errstr");
			$logger->debug("End of QueryAllRecords function.");
			return (ERROR);
		}
		$logger->info("Request successfully executed.");
	}

	$logger->info("Fetching the result ...");
	my $Rows = $Sth->fetchrow_arrayref();

	unless ($Rows) {
		$logger->error(
			"No row returned or issue encountered during fetching ...");
		$logger->error("Following error catched : $Sth->err");
		$logger->debug("End of QueryAllRecords function.");
		return (ERROR);
	}
	my $NbRows = scalar( keys %$Rows );
	$logger->info("Request sucessfully executed, returned $NbRows row(s).");
	$logger->debug("End of QueryAllRecords function.");
	return ($Rows);
}

sub Commit {
	my $self   = shift;
	my $logger = Log::Log4perl->get_logger();

	if ( not defined $self->{'Blocked'} || $self->{'Blocked'} == 1 ) {
		$logger->error("Not connected to $self->{'DataBase'} ...");
		return (ERROR);
	}

	my $Res = $self->{'DBHandle'}->commit;

	unless ($Res) {
		$logger->error(
"Transaction aborted.Following error catched : $self->{'DBHandle'}->errstr"
		);
		$logger->warn("Issuing rollback ...");

		my $Rol = $self->{'DBHandle'}->rollback;
		unless ($Rol) {
			$logger->warn("Rollback failed ...");
			$logger->debug("End of Commit function.");
			return (ERROR);
		}
		$logger->warn("Transaction Rollbacked.");
		$logger->debug("End of Commit function.");
		return (ERROR);
	}
	$logger->info("Commit Successfull.");
	$logger->debug("End of Commit function.");
	return (TRUE);
}

sub Disconnect {
	my $self   = shift;
	my $logger = Log::Log4perl->get_logger();

	if ( not defined $self->{'Blocked'} || $self->{'Blocked'} == 1 ) {
		$logger->error("Not connected to $self->{'DataBase'} ...");
		return (ERROR);
	}

	my $Dis = $self->{'DBHandle'}->disconnect;

	unless ($Dis) {
		$logger->warn("Can't disconnect now.");
		$logger->warn("Following error catched :  $self->{'DBHandle'}->errstr");
		$logger->debug("End of Disconnect function.");
		return (ERROR);
	}

	$logger->info("Disconnected from $self->{'DataBase'}.");
	$logger->debug("End of Disconnect function.");
	return (TRUE);
}

1;
