package VerySimpleLog;
use strict;
use warnings;
use List::Util qw (any);
use File::Temp qw(tempdir);
use Config::Tiny;
use Moo;
with 'MooX::Singleton';

use lib '/home/gduhamel/Projet/AKB/Linux/LIB';
use Natixis::GenericFunction qw(GetSysTime IsValidFile IsValidPath);

has INI => (is => 'ro', required => 1);
has config => (is => 'rw');

BEGIN
{

    use constant FALSE => 0;
    use constant TRUE  => 1;
}

sub BUILD
{
    my ($self) = @_;

    unless (IsValidFile($self->{'INI'}))
    {
        die print(
            "ERROR : No valid INI configuration file found. Doesn't exists or can't be read. \n");
    }

    $self->_config();
    $self->_init();

    return (TRUE);
}

sub _config
{
    my ($self) = @_;

    my $configuration = Config::Tiny->read($self->{INI}, 'utf8')
      or die sprintf(
        "ERROR : Error parsing configuration file named %s with module Config::Tiny. \n",
        $self->{INI});

    unless (exists $configuration->{'Global'}
            && $configuration->{Global}->{Logger} =~ /File|Output|Database|ALL/i)
    {
        print STDERR
          "[WARN] Error reading Global section in $self->{INI} file. Will use Standard Output by default. \n";
        $configuration->{Global} = "Output";
        $configuration->{Output}->{LogLevel} = "ALL";
    }

    $self->config($configuration);

    return (TRUE);
}

sub _init
{
    my ($self) = @_;

    if ($self->config->{Global}->{Logger} =~ /ALL/i)
    {
        $self->config->{Global}->{Logger} = "File,Output,Database";
    }

    my @ConfigOutput = split(',', $self->config->{Global});

    if (any { "File" } @ConfigOutput && exists $self->config->{File})
    {
        unless (exists $self->config->{File}->{LogLevel})
        {
            $self->config->{File}->{LogLevel} = "ALL";
        }

        unless (exists $self->config->{File}->{Directory}
                && IsValidPath($self->config->{File}->{Directory}))
        {
            $self->config->{File}->{Directory} = tempdir();
        }

        unless (exists $self->config->{File}->{Filename})
        {
            my $time = _getLogTime();
            $self->config->{File}->{Filename} = "$0-$time.log";
        }

        $self->{isfile} = TRUE;
    }

    if (any { "Database" } @ConfigOutput && exists $self->config->{Database})
    {
        unless (exists $self->config->{File}->{LogLevel})
        {
            $self->config->{File}->{LogLevel} = "ALL";
        }
        $self->{isdatabase} = TRUE;
    }

    if (any { "Output" } @ConfigOutput)
    {
        unless (exists $self->config->{File}->{LogLevel})
        {
            $self->config->{File}->{LogLevel} = "ALL";
        }
        $self->{isoutput} = TRUE;
    }
}

sub log
{
    my ($self, $type, $message) = @_;

    unless ($type && $message)
    {
        return (FALSE);
    }

    return (TRUE);
}

sub _getLogTime
{
    my ($self) = @_;

    unless ($self->_setLogTime())
    {
        return (FALSE);
    }
    return ($self->{LogTime});
}

sub _setLogTime
{
    my ($self) = @_;

    _setLastLogTime();

    $self->{LogTime} = GetSysTime();

    unless ($self->{LogTime})
    {
        return (FALSE);
    }
    return (TRUE);
}

sub _setLastLogTime
{
    my ($self) = @_;

    unless ($self->{LogTime})
    {
        return (FALSE);
    }

    $self->{LastLogTime} = $self->{LogTime};

    return (TRUE);
}

sub _getLastLogTime
{
    my ($self) = @_;

    unless ($self->{LastLogTime})
    {
        return (FALSE);
    }
    return ($self->{LastLogTime});
}

END
{
    my ($package, $filename, $line) = caller();
    print "Clean $package.\n";
}

1;
