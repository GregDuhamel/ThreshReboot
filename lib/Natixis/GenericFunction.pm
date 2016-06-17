package Natixis::GenericFunction;

use	strict;
use	warnings;
use	Net::Ping;
use	POSIX qw(strftime);
use	Sys::Hostname;
use	Config;
use	YAML::Tiny;


BEGIN
{
require Exporter;
our $VERSION = 1.10;
use base qw(Exporter);
our @EXPORT_OK = qw(GetSysTime GetSysDate GetSysHour GetHostType GetHostName IsValidFile IsValidHost ReadFile IsValidPath ReadYamlFile);
use constant FALSE	=> 0;
use constant TRUE	=> 1;
}

sub	GetSysTime
{
	my $self;
	
	$self = strftime("%d-%m-%Y-%H-%M-%S", localtime);
	
	return($self);
}

sub	GetSysDate
{
	my $self;
	
	$self = strftime("%d-%m-%Y", localtime);
	
	return($self);
}

sub	GetSysHour
{
	my $self;
	
	$self = strftime("%H-%M-%S", localtime);
	
	return($self);
}

sub	GetHostName
{
	my $self;
	
	$self = hostname;
	
	return($self);
}

sub	GetHostType
{
	my $self;
	
	$self = $Config{osname};
	
	return($self);
}

sub	IsValidPath
{
	my $Path = shift;
	
	unless($Path && -d $Path && -w $Path)
	{
		return(FALSE);
	}
	
	return(TRUE);
}

sub	IsValidFile
{	
	my $File = shift;
	
	unless($File && -f $File && -r $File)
	{
		return(FALSE);
	}	
	return(TRUE);
}

sub	IsValidHost
{
	my $Host = shift;
	
	my $p = Net::Ping->new();
	unless ($p->ping($Host))
	{
		$p->close();
		return(FALSE);
	}
	$p->close();
	return(TRUE);
}

sub	HaveEnoughRAM
{
	return(TRUE);
}

sub	HaveEnoughCPU
{	
	return(TRUE);
}

sub	IsAlreadyRunning
{	
	return(TRUE);
}

sub	ReadFile
{
	my $FilePath = shift;
	
	my $Fh;
	
	open ($Fh, '<:encoding(UTF-8)', $FilePath) or return(FALSE);
	
	return($Fh);
}

sub	ReadYamlFile
{
	my $FilePath = shift;
	my $YAML;
	
	unless(IsValidFile($FilePath))
	{
		return(FALSE);
	}
	
	unless ($YAML = YAML::Tiny->read($FilePath))
	{
		return(FALSE);
	}
	return($YAML);
}

1;