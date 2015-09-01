use strict;
use warnings;
use v5.23;
use lib '/home/gduhamel/Projet/TreshReboot/lib';
use VerySimpleLog;

BEGIN
{
    use constant FALSE => 0;
    use constant TRUE  => 1;
}

END
{
    print "END.\n";
}

sub coucou
{
    my $l = VerySimpleLog->instance();
    $l->log();
}

sub Main
{
    my $file = "/home/gduhamel/Projet/TreshReboot/etc/vsl.ini";
    my $l = VerySimpleLog->instance(INI => $file);
    coucou();
}

Main();
