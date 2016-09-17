Use the Keyboard to Select Connectors in Pointwise
==================================================

This Pointwise Glyph script facilitates usage of the keyboard to select
a group of connectors in lieu of using the mouse.

Usage
-----

Upon execution this script prompts the user to select a connector unless one
has already been selected at runtime. The user is then enabled to use the
keyboard to cycle through adjacent connectors; the default cycle key is the
'Spacebar'. When the desired connector has been highlighted, then
'Enter/Return' key selects it. Connectors adjacent to the newly selected
connector are then selectable and the user may continue to use the keyboard to
select connectors until they press 'Shift-Enter' at which time the script
terminates and all connectors selected during runtime are returned to the user.
The script attempts to automatically update the view in order to 'follow' the
connectors being selected.

Both the 'Enter' keys (numeric and non-numeric) may be used to select the next
connector.

Pressing the 'Esc' key cancels the script and pressing 'Shift-Enter' exits the
script, returning all selected connectors to the user.

Other key-bindings
------------------

There are several other experimental key bindings enabled by default that
control the view/zoom level during execution of the script.

* `z`: Pressing 'z' while using the script zooms the view to focus only on the
  currently highlighted connector, i.e. the connector that would be selected if
  the user pressed 'Enter'.

* `r`: Pressing 'r' will cause the script to recall the original view, i.e. the
  view when the script was executed. This may or may not be useful, depending
  on the view.

* `b`: Pressing 'b' will change to view to include all connectors that have
  been previously selected during script execution. This is meant to provide an
  overview of all connectors selected so far.

* `x`: Pressing 'x' will cause the script to recall the default view which is
  meant to focus on the previously selected connector and all connectors
  adjacent to it, i.e. all connectors that are currently selectable.

Options
-------

* `cycleKey`: By default the 'Spacebar' is used to cycle through adjacent
  connectors, however the `cycleKey` option may be changed in order to enable
  cycling with the 'Tab' key. Currently the only supported options are 'Tab'
  and 'space'.

* `autocomplete`: This option enables the script to auto-select adjacent
  connectors if there is only one, and hence no other options. This emulates
  Pointwise's 'autocomplete' behavior during domain creation.

* `detectLoop`: This option may be enabled to cause the script to automatically
  detect that a closed loop has been selected and terminate, returning the
  selected loop.
