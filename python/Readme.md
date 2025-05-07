## Script Details

### biom.py
- A modified and expanded version of [PixelRick's original biom.py script](https://github.com/PixelRick/StarfieldScripts)

```sh
-h
usage: biom.py [-h] -f FILENAME [-o OLD_BIOME] [-n NEW_BIOME] [-e] [-p] [-pb] [-pr] [-u]

Swap biomes in a biom file or export biome data.

options:
  -h, --help            show this help message and exit
  -f, --filename FILENAME
                        Path to the biom file
  -o, --old_biome OLD_BIOME
                        Biome ID to replace (hexadecimal)
  -n, --new_biome NEW_BIOME
                        Biome ID to replace with (hexadecimal)
  -e, --export          Export biome data to text
  -p, --plot            Plot the biome grid
  -pb, --plot_biomes    Plot only biome data
  -pr, --plot_resources
                        Plot only resource data
  -u, --update_biomes   Randomize biomes from the biom_update.csv file
```

- Example: python biom.py -f PlanetBiomes.biom -e (will export the biome FormID grid found in the PlanetBiomes.biom file)

### viewRes.py
- Outputs the resource grid from the [planet].biom file.

```sh
-h
usage: viewRes.py [-h] -f FILE

Parse biome resource grid data

options:
  -h, --help       show this help message and exit
  -f, --file FILE  Path to the .biom file
```

- Example: python viewRes.py -f PlanetBiomes.biom (will export the Resources grid found in the PlanetBiomes.biom file)