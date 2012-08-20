# Tcl packages for my script-objects for Amira

In order to get my Amira scipt-objects to work you must install this tcl packages. For working with Amira script-objects it is advisable to make a local amira directory (look in the online Amira documentation on how to do it).

#Installation

Probably the easiest way is to append the package path to Tcl´s auto\_path variable, so it is possible to have a costum file path. To do this execute the following steps:

- open the Amira.init file ($AMIRA\_ROOT/share/resources/Amira/Amira.init)
- add the following line (does´t matter where): lappend auto\_path "here stands the path to the package file"
- at the next start of Amira write in the amira console: "echo $auto\_path"
- if the output contains your path all is ok :)

## Installation

Type the following in terminal:

```bash
    cd ~/***here comes your download path***
    git clone git://github.com/brosensteiner/AmiraTclPackages.git
```
