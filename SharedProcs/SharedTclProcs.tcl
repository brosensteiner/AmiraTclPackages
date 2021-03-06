#################################################
# shared tcl procedurs for Amira script-objects #
# only easily reusable procedures are here      #
#################################################

package provide SharedProcs	1.0
package require Tcl 		8.4

# Create the namespace
namespace eval ::SharedProcs {
    # Export commands
    namespace export *;#all should be exported
}

#proc for returning only the name of the module extracted from $this
proc ::SharedProcs::moduleName { } {
	global this
	return [string map { "\.scro" "" } $this]
}
#proc for returning the author name
proc ::SharedProcs::theAuthor { name } {
	return $name
}

proc ::SharedProcs::sayHello {} {
	if { [catch {global moduleName}] != 1 } {
		global this
		set moduleName $this
	}
	echo "\n************ module \"$moduleName\" loaded successfully :) ************\n"
}
proc ::SharedProcs::say { something } {
	if { [catch {global moduleName}] != 1 } {
		global this
		set moduleName $this
	}
	echo "$moduleName: $something"
}

# this proc is cool :)
# a sort of tcl lamda mapping implementation
# has to be used like this: map {x {return [string length $x]:$x}} {a bb ccc dddd}
proc ::SharedProcs::map {lambda list} {
   set result {}
   foreach item $list {
      lappend result [apply $lambda $item]
   }
   return $result
}

# procedure which can add new parameters to a amira field. 1.arg: the field, 2.arg: a new Bundle, args: pairs of parameter/values (e.g. Color { 1 0 1 })
proc ::SharedProcs::stampField { field theBundle args } {

	$field parameters newBundle $theBundle
	foreach { par val } $args {
		eval "$field parameters $theBundle setValue $par $val"
	}
}
# clear items in a specified Bundle in a amira field (saves some typing): \
  "args" is the "path" to a nested bundle
proc ::SharedProcs::clearBundle { field args } {

	if { [llength $args] > 1 } {
		set lastElement [lindex $args end]
		set restElements [lrange $args 0 end-1]
	} else {# when only one bundle in args (e.g. Materials)
		set lastElement $args
		set restElements ""
	}
	
	foreach item [eval "$field $restElements parameters $lastElement list"] {
		eval "$field $restElements parameters $lastElement $item setFlag NO_DELETE 0"
		eval "$field $restElements parameters $lastElement remove $item"
	}
}

# simple port test: procedure returns 1 when module has port, otherwise it returns 0
proc ::SharedProcs::hasPort {modul port} {
	upvar #1 $modul myModule
	if { [lsearch [$myModule allPorts] $port] != -1 } then { return 1 } else { return 0 }
}

# procedure which creates moduleType and connects it with sourceName module and checks if connection is valid \
  moduleName is the name of the module in the pool \
  if moduleName module does not exist it also gets created in the pool \
  function returns the name of the newly created module
proc ::SharedProcs::createModuleAndConnectIfOkToSource { moduleType moduleName sourceName { conPortIndex 0 } } {
	
	# test if module is already in the pool and assigne the moduleToReturn variable as appropriate:
	if { [lsearch [all $moduleType] $moduleName] == -1 } {
		set moduleToReturn [create $moduleType $moduleName]
		$moduleToReturn hideIcon;#set hideNewModules 1 does not work
	} else {
		set moduleToReturn $moduleName
	}
	# sets the desired connectionPort name, default is 0:
	set theConnectionPort [lindex [$moduleName connectionPorts] $conPortIndex]
	# connect:
	if	{
		 [$moduleName $theConnectionPort validSource $sourceName]
	}	{
		$moduleName $theConnectionPort connect $sourceName
	} else {
		say "tried to connect \"$moduleName\" to \"$sourceName\", but connection is not valid source"
	}
	
	return $moduleToReturn
}

#simple proc for switching between positiv and negative numbers:
proc ::SharedProcs::switchNumberSigns { args } {
	set list [list]
	foreach i $args { lappend list [expr -$i] }
	return $list
}

#proc which translates a point in 3D space. argument point has to be in cartesian coordinates
proc ::SharedProcs::translateTo { point pointToTranslateTo } {

	set point [split $point " "]
	set pointToTranslateTo [split $pointToTranslateTo " "]

	set transformList [list]
	for { set i 0 } { $i < [llength $point]  } { incr i } {
		lappend transformList [expr [lindex $point $i] - [lindex $pointToTranslateTo $i]]
	}
	return $transformList
}

# procs which rotates a given object(s) on a given axis (axis == world origin to evecPointAxis)
proc ::SharedProcs::rotateAll { theObjectList evecPointAxis { degrees 180 } } {

	upvar $theObjectList upvList $evecPointAxis upvevecPointAxis
	foreach item $upvList {
		eval "$item rotate $upvevecPointAxis $degrees"
	}
}
proc ::SharedProcs::rotateObject { object evecPointAxis { degrees 180 } } {

	upvar $object upvObject $evecPointAxis upvevecPointAxis
	eval "$upvObject rotate $upvevecPointAxis $degrees"
}

# procedure which connects $this to all modules in the pool when invoked.
# default is HxSurface when no argument
# module must implement "allEmptyConPorts" list, which holds all names of the not connected connectionPorts!!! 
proc ::SharedProcs::autoConnectToAll { {moduleclass HxSurface} } {

	global this allEmptyConPorts
	
	foreach item [$this connectionPorts] {
		if { [$this $item isOfType "HxConnection"] } then { $this $item disconnect };#disconnects only HxConnection connection ports (e.g. not colormap port)
	}
	#(re)connects to all labelfields in pool: 
	foreach item [all $moduleclass] {
		$this [lindex $allEmptyConPorts 0] connect $item
		$this compute
	}
}

# procedure for extracting a bunch of values from an amira spreadsheet object generated from the ShapeAnalysis modul. :\
  return value is an array which holds the values ("array set varName extractFromSpreadsheet spreadObj" catches the array returned \
  by extractFromSpreadsheet again in an array). This proc works only in conjunctions with the ShapeAnalysis module \
  because the generated spreadsheet from this module has a particular order of rows and columns (labelfields are coded in the spreadsheet as their bundle-index not as there names!!!) \
  getting the values from the array for example: $theArray(bundleindex,evector1)
proc ::SharedProcs::extractFromSpreadsheet { spreadObj } {
	
	array set spreadExtractArray {}
	set theNumRows [$spreadObj getNumRows]
	#put volume in array:
	for { set i 0 } { $i < $theNumRows  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],v) [list [$spreadObj getValue 1 $i]]
	}
	#put mass in array:
	for { set i 0 } { $i < $theNumRows  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],m) [list [$spreadObj getValue 32 $i]]
	}
	#put area in array:
	for { set i 0 } { $i < $theNumRows  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],a) [list [$spreadObj getValue 33 $i]]
	}
	#put center point x, y, z in array:
	for { set i 0 } { $i < $theNumRows  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],c) [list	[$spreadObj getValue 2 $i]\
																	[$spreadObj getValue 3 $i]\
																	[$spreadObj getValue 4 $i]\
																	]
	}
	#put eigenvalues x, y, z in array:
	for { set i 0 } { $i < $theNumRows  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],evalue) [list	[$spreadObj getValue 8 $i]\
																		[$spreadObj getValue 9 $i]\
																		[$spreadObj getValue 10 $i]\
																		]
	}
	#put eigenvector 1x, 1y, 1z in array:
	for { set i 0 } { $i < $theNumRows  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],evector1) [list	[$spreadObj getValue 11 $i]\
																			[$spreadObj getValue 12 $i]\
																			[$spreadObj getValue 13 $i]\
																			]
	}
	#put eigenvector 2x, 2y, 2z in array:
	for { set i 0 } { $i < $theNumRows  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],evector2) [list	[$spreadObj getValue 14 $i]\
																			[$spreadObj getValue 15 $i]\
																			[$spreadObj getValue 16 $i]\
																			]
	}
	#put eigenvector 3x, 3y, 3z in array:
	for { set i 0 } { $i < $theNumRows  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],evector3) [list	[$spreadObj getValue 17 $i]\
																			[$spreadObj getValue 18 $i]\
																			[$spreadObj getValue 19 $i]\
																			]
	}
	#put moments of inertia ixx, Iyy, Izz in array:
	for { set i 0 } { $i < $theNumRows  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],moinertia) [list	[$spreadObj getValue 28 $i]\
																			[$spreadObj getValue 29 $i]\
																			[$spreadObj getValue 30 $i]\
																			]
	}
	return [array get spreadExtractArray]
}

#proc which tests a simple topology invariant criterion:
proc ::SharedProcs::testTopology { surfaceList } {

	upvar $surfaceList surfaceListUpd
	foreach surface $surfaceListUpd {
		array set tempArray [$surface getTopology]
		set answer "(Euler characteristic: $tempArray(Euler-Poincare:), Genus: $tempArray(Genus:))"
		if { $tempArray(Euler-Poincare:) != [expr 2 - 2*$tempArray(Genus:)] || \
			 $tempArray(Genus:) < 0
		   } {
			say "!!! there is something wrong with $surface !!!"
			echo "maybe polygon islands or not closed ... $answer"
		} else {
			say "$surface: Toplology OK $answer"
		}
	}
}




