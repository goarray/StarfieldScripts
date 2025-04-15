Note, this is not going to biome 'paint' the planet(s) for you, you'll need to use a separate method for that. This simple generates the biom files and adds the appropriate Biome FormIDs.

The Biomes.CSV file contains all of the base biomes minus named ones, eg, sandyearth. You can use the Starfield_AddBiomesFromBiomesCSV to add 7 generic (random) biomes to selected planet(s) in xEdit.

----

Instructions:

Place the contents of /DropInxEditRoot/ in your xEdit.exe directory. The scripts in /Edit Scripts/ should wind up alongside your user created scripts.

In xEdit, select the planet(s) you wish to generate .biom files for, run the Starfield_ExportBiomesToPlanetBiomesCSV script. 

This will generate a PlanetBiomes.CSV in xEdit's root directory which contains all of the biomes for the selected planet(s)

Place this CSV file in same directory as PlanetBiomes.bat. 

Run PlanetBiomes.bat.  

