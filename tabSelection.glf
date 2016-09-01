package require PWI_Glyph
pw::Script loadTk

wm title . "Selection"
grid [ttk::frame .f -padding "5 5 5 5"] -column 0 -row 0 -sticky nwes
grid columnconfigure . 0 -weight 1
grid rowconfigure    . 0 -weight 1

set infoMessage "Spacebar - Cycle connectors \nEnter - Select connector \nEscape - Exit"

grid [tk::message .f.m -textvariable infoMessage -background beige -bd 2 \
        -relief sunken -padx 5 -pady 5 -justify left -width 250] \
        -column 0 -row 1 -sticky ew

foreach w [winfo children .f] {grid configure $w -padx 5 -pady 5}

wm resizable . 0 0
focus -force .

set e 0
bind all <KeyPress-Escape> {set e 1}

proc HighlightConnectorWhite {con} {

    $con setRenderAttribute ColorMode Entity
    $con setColor "1 1 1"

}

proc HighlightConnectorYellow {con} {

    $con setRenderAttribute ColorMode Entity
    $con setColor "1 1 0"

}

proc ThickenConnector {con} {

    $con setRenderAttribute ColorMode Entity
    $con setRenderAttribute LineWidth 5

    pw::Display update

}

proc GetConnectorInformation {con} {

    set mode  [$con getRenderAttribute ColorMode]
    set color [$con getColor]
    set width [$con getRenderAttribute LineWidth]

    return [list $mode $color $width]

}

proc ResetConnectorColor {con mode color} {

    if {$mode eq "Automatic"} {
        $con setRenderAttribute ColorMode $mode
    } else {
        $con setRenderAttribute ColorMode $mode
        $con setColor $color
    }

}

proc ResetConnectorLineWidth {con width} {

    $con setRenderAttribute LineWidth $width

}

proc RemoveConnectorsFromList {conList cons} {

    global conInfo

    foreach con $cons {

        set idx [lsearch -exact $conList $con]

        if {$idx >= 0} {
            set conList [lreplace $conList $idx $idx]
            ResetConnectorColor $con [lindex $conInfo($con) 0] [lindex $conInfo($con) 1]
            ResetConnectorLineWidth $con [lindex $conInfo($con) 2]
        }

    }

    return $conList

}

proc GetAdjacentConnectors {con} {

    global conInfo

    set adjCons [pw::Connector getAdjacentConnectors $con]
        foreach adjCon $adjCons {
            if {![info exists conInfo($adjCon)]} {
                set conInfo($adjCon) [GetConnectorInformation $adjCon]
            }
            HighlightConnectorYellow $adjCon
        }

    return $adjCons

}

pw::Display getSelectedEntities resultVar

set cons [lindex $resultVar(Connectors) 0]

set selectedCon $cons
set conInfo($selectedCon) [GetConnectorInformation $selectedCon]
HighlightConnectorWhite $selectedCon

set adjCons [GetAdjacentConnectors $selectedCon]

set selectedConnector [lindex $adjCons 0]
ThickenConnector $selectedConnector

set i 1
set n 0

pw::Display update

bind all <space> {

    if {$i > 0} {
        set previousConnector [lindex $adjCons $i-1]
        ResetConnectorLineWidth $previousConnector [lindex $conInfo($previousConnector) 2]
    }

    if {[llength $adjCons] == 1} {
        set selectedConnector [lindex $adjCons 0]
        ThickenConnector $selectedConnector
    } else {
        set selectedConnector [lindex $adjCons $i]
        ThickenConnector $selectedConnector
    }

    if {$i < [llength $adjCons]-1} {
        incr i
    } else {
        set i 0
        set lastConnector [lindex $adjCons end]
        ResetConnectorLineWidth $lastConnector [lindex $conInfo($lastConnector) 2]
    }

}

bind all <KeyPress-Return> {

    lappend cons $selectedConnector

    foreach con $adjCons {
        ResetConnectorColor $con [lindex $conInfo($con) 0] [lindex $conInfo($con) 1]
        ResetConnectorLineWidth $con [lindex $conInfo($con) 2]
    }

    set nextAdjCons [GetAdjacentConnectors $selectedConnector]
    set nextAdjCons [RemoveConnectorsFromList $nextAdjCons $adjCons]
    set adjCons [RemoveConnectorsFromList $nextAdjCons $cons]

    foreach con $cons {
        HighlightConnectorWhite $con
    }

    if {[llength $adjCons] == 0} {
        set e 1
    }

    set selectedConnector [lindex $adjCons 0]
    ThickenConnector $selectedConnector

    set i 1

    pw::Display update

}

vwait e

foreach con $cons {
    ResetConnectorColor $con [lindex $conInfo($con) 0] [lindex $conInfo($con) 1]
    ResetConnectorLineWidth $con [lindex $conInfo($con) 2]
}

foreach con $adjCons {
    ResetConnectorColor $con [lindex $conInfo($con) 0] [lindex $conInfo($con) 1]
    ResetConnectorLineWidth $con [lindex $conInfo($con) 2]
}

pw::Display setSelectedEntities $cons

exit
