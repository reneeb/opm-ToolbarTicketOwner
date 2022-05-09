# --
# Copyright (C) 2017 - 2022 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::ToolBar::TicketOwner;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
    'Kernel::Output::HTML::Layout',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get UserID param
    $Self->{UserID} = $Param{UserID} || die "Got no UserID!";

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(Config)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my $Count = $TicketObject->TicketSearch(
        Result      => 'COUNT',
        StateType   => 'Open',
        OwnerIDs    => [ $Self->{UserID} ],
        UserID      => 1,
        Permission  => 'ro',
    );
    my $CountNew = $TicketObject->TicketSearch(
        Result     => 'COUNT',
        StateType  => 'Open',
        OwnerIDs   => [ $Self->{UserID} ],
        TicketFlag => {
            Seen => 1,
        },
        TicketFlagUserID => $Self->{UserID},
        UserID           => 1,
        Permission       => 'ro',
    );
    $CountNew = $Count - $CountNew;

    my $CountReached = $TicketObject->TicketSearch(
        Result                        => 'COUNT',
        StateType                     => ['pending reminder'],
        OwnerIDs                      => [ $Self->{UserID} ],
        TicketPendingTimeOlderMinutes => 1,
        UserID                        => 1,
        Permission                    => 'ro',
    );

    my $CountAvailable = $TicketObject->TicketSearch(
        Result     => 'COUNT',
        StateType  => 'Open',
        Locks      => ['unlock'],
        OwnerIDs   => [ $Self->{UserID} ],
        UserID     => 1,
        Permission => 'ro',
    );

    my $Class          = $Param{Config}->{CssClass};
    my $ClassNew       = $Param{Config}->{CssClassNew};
    my $ClassReached   = $Param{Config}->{CssClassReached};
    my $ClassAvailable = $Param{Config}->{CssAvailable};

    my $Icon          = $Param{Config}->{Icon};
    my $IconNew       = $Param{Config}->{IconNew};
    my $IconReached   = $Param{Config}->{IconReached};
    my $IconAvailable = $Param{Config}->{IconAvailable};

    my $URL = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->{Baselink};
    my %Return;
    my $Priority = $Param{Config}->{Priority};
    if ($CountNew && $IconNew ) {
        $Return{ $Priority++ } = {
            Block       => 'ToolBarItem',
            Description => Translatable('Owner Tickets New'),
            Count       => $CountNew,
            Class       => $ClassNew,
            Icon        => $IconNew,
            Link        => $URL . 'Action=AgentTicketOwnerView;Filter=New',
            AccessKey   => $Param{Config}->{AccessKeyNew} || '',
        };
    }
    if ($CountReached && $IconReached ) {
        $Return{ $Priority++ } = {
            Block       => 'ToolBarItem',
            Description => Translatable('Owner Tickets Reminder Reached'),
            Count       => $CountReached,
            Class       => $ClassReached,
            Icon        => $IconReached,
            Link        => $URL . 'Action=AgentTicketOwnerView;Filter=ReminderReached',
            AccessKey   => $Param{Config}->{AccessKeyReached} || '',
        };
    }
    if ($CountAvailable && $IconAvailable ) {
        $Return{ $Priority++ } = {
            Block       => 'ToolBarItem',
            Description => Translatable('Owner Tickets Available'),
            Count       => $CountAvailable,
            Class       => $ClassAvailable,
            Icon        => $IconAvailable,
            Link        => $URL . 'Action=AgentTicketOwnerView;Filter=Available',
            AccessKey   => $Param{Config}->{AccessKeyAvailable} || '',
        };
    }
    if ($Count && $Icon) {
        $Return{ $Priority++ } = {
            Block       => 'ToolBarItem',
            Description => Translatable('Owner Tickets Total'),
            Count       => $Count,
            Class       => $Class,
            Icon        => $Icon,
            Link        => $URL . 'Action=AgentTicketOwnerView',
            AccessKey   => $Param{Config}->{AccessKey} || '',
        };
    }
    return %Return;
}

1;

