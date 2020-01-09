package require PWI_Glyph
pw::Script loadTk

# This option allows for customization of the 'cycle' key; by default it is the
# Spacebar, but it may be set to the Tab key by replacing 'space' with 'Tab'.
# NOTE: only 'space' and 'Tab' are currently supported.
set cycleKey space

wm title . "Selection Script"
grid [ttk::frame .f -padding "5 5 5 5"] -column 0 -row 0 -sticky nwes
grid columnconfigure . 0 -weight 1
grid rowconfigure    . 0 -weight 1

# Set 'cycleKey' to 'space' if it is not neither 'Tab' nor 'space'
if {![string compare "Tab" $cycleKey] && ![string compare "space" $cycleKey]} {
  set cycleKey space
}

set cycleString [expr ![string compare "Tab" $cycleKey]?"Tab":"Spacebar"]
set infoMessage [concat $cycleString " - Cycle connectors \nEnter - Select connector \nEscape - Abort \nShift-Enter - Exit"]

grid [tk::message .f.m -textvariable infoMessage -background beige -bd 2 \
  -relief sunken -padx 5 -pady 5 -justify left -width 250] \
  -column 0 -row 1 -sticky ew

foreach w [winfo children .f] {grid configure $w -padx 5 -pady 5}

wm resizable . 0 0
focus -force .

# Save the current view
set preScriptView [pw::Display getCurrentView]

# Parameterize the animation speed
set animationSpeed 0.25

# Exit variable/code; -1 means abort, 1 means success.
set e 0

# Counter to track number of connectors selected by the user by pressing enter.
set selectionCount 0

# This parameter controls whether or not the script detects that the user has
# selected a loop and terminates. If the user wants to use this script to
# select closed loops this should be set to 'true', if however, the user just
# wants to select some connected connectors and not to end if they close the
# loop, this should be set to 'false'.
set detectLoop true

# Pressing Escape cancels/aborts the script.
bind all <KeyPress-Escape> {set e -1}

# Pressing Shift-Return successfully exits the script.
bind all <Shift-Return> {set e 1}

# I found this tcl do-while loop implementation at
# https://groups.google.com/forum/#!topic/comp.lang.tcl/dSZW_ngNCyo
# and I do not understand how it works, but it does seem to work!
proc do {body while condition} {
  if {![string match "while" $while]} {
    error "incorrect 'do-while' usage: should be do body while condition"
  }

  set body "$body\nif {$condition} {continue} {break}"
  uplevel [list while 1 $body]
}

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

# This procedure is *roughly* equivalent to hitting Shift-F2 on the keyboard.
# It will center the connectors given by $cons in the screen.
proc CenterConnectors {cons} {
  global animationSpeed

  # This function should return if there are no connectors in the list as might
  # happen if we have reached the end of an unclosed set of connectors.
  if { [llength $cons] == 0 } { return }

  set bbox [pwu::Extents empty]

  foreach con $cons {
    set bbox [pwu::Extents enclose $bbox [$con getExtents]]
  }

  # Create the new view.
  set zoomView [pw::Display calculateView [pwu::Extents minimum $bbox] [pwu::Extents maximum $bbox]]

  # Set the new view.
  set retValue [pw::Display setCurrentView -animate $animationSpeed $zoomView]
}

set autocomplete true

#
# Use selected connector or prompt user for selection if nothing is selected at
# run time.
#
set mask [pw::Display createSelectionMask -requireConnector {}]

if { !([pw::Display getSelectedEntities -selectionmask $mask selection]) } {
  # No connector was selected at runtime; prompt for one now.

  if { !([pw::Display selectEntities \
         -selectionmask $mask \
         -description "Select initial connector" \
       selection]) } {

    puts "Error: Unsuccessfully selected connector... exiting"
    exit
  }
}

# Only use the first connector if there are more than one selected.
set cons [lindex $selection(Connectors) 0]

set selectedCon $cons
set conInfo($selectedCon) [GetConnectorInformation $selectedCon]
HighlightConnectorWhite $selectedCon

set adjCons [GetAdjacentConnectors $selectedCon]

CenterConnectors [list {*}$adjCons {*}$selectedCon]

set selectedConnector [lindex $adjCons 0]
ThickenConnector $selectedConnector

set i 1
set n 0

pw::Display update

# I would like to figure out how to bind both <Tab> and <space> to this
# functionality; creating a virtual event like the one used to select
# connectors does not work here with <Tab> for some reason.
bind all <$cycleKey> {
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

# Zoom/peek at the currently selected candidate connector.
bind all <KeyPress-z> {
  # Save the current view
  #set preZoomView [pw::Display getCurrentView]
  CenterConnectors $selectedConnector
}

# Zoom back out to view all current connectors.
bind all <KeyPress-x> {
  CenterConnectors [list {*}$adjCons {*}$selectedConnector]
}

# Zoom out to view all currently selected connectors.
bind all <KeyPress-b> {
  CenterConnectors [list {*}$cons {*}$adjCons {*}$selectedConnector]
}

# Zoom out to original view: the view when the script was launched.
bind all <KeyPress-r> {
  set retValue [pw::Display setCurrentView -animate $animationSpeed $preScriptView]
}

# Both the normal Enter/Return key and the Enter key on the numeric keypad will
# work here.
event add <<select>> <KeyPress-KP_Enter> <KeyPress-Return>
bind all <<select>> {
  incr selectionCount

  do {
    lappend cons $selectedConnector

    foreach con $adjCons {
      ResetConnectorColor $con [lindex $conInfo($con) 0] [lindex $conInfo($con) 1]
      ResetConnectorLineWidth $con [lindex $conInfo($con) 2]
    }

    set nextAdjCons [GetAdjacentConnectors $selectedConnector]
    set nextAdjCons [RemoveConnectorsFromList $nextAdjCons $adjCons]

    # Does the script need to detect if it has closed a loop?
    if {$detectLoop} {
    # If the original connector exists now in the nextAdjCons list the loop is
    # complete/closed.
      set idx [lsearch -exact $nextAdjCons [lindex $cons 0]]
      if {$idx >= 0 && $selectionCount != 1} {
        set e 1

        # This is a bit messy and needs to be here so that all connectors have
        # their original size/color when the script completes.
        foreach con $nextAdjCons {
          ResetConnectorColor $con [lindex $conInfo($con) 0] [lindex $conInfo($con) 1]
          ResetConnectorLineWidth $con [lindex $conInfo($con) 2]
        }

        return
      }
    }

    set adjCons [RemoveConnectorsFromList $nextAdjCons $cons]

    foreach con $cons {
      HighlightConnectorWhite $con
    }

    set selectedConnector [lindex $adjCons 0]

  } while {([llength $adjCons] == 1) && $autocomplete}

  CenterConnectors [list {*}$adjCons {*}$selectedConnector]

  # No more connectors
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

if {$e == 1} { # Success
  # Set the final view so that all selected connectors are centered.
  CenterConnectors $cons
  pw::Display setSelectedEntities $cons
} elseif {$e == -1} { # Abort
  # Reset the original view.
  set retValue [pw::Display setCurrentView -animate 1 $preScriptView]
} else { # Something else
  puts "Warning: received exit code <$e>"
}

exit

# vim: set ft=tcl:
