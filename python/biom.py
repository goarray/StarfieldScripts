import argparse
from pathlib import Path
from construct import Struct, Const, Rebuild, this, len_
from construct import Int32ul as UInt32, Int16ul as UInt16, Int8ul as UInt8
import random
import csv
import numpy as np
import plotly.graph_objects as plgo
from pathlib import Path

# from PIL import Image

GRID_SIZE = [0x100, 0x100]
GRID_FLATSIZE = GRID_SIZE[0] * GRID_SIZE[1]

CsSF_Biom = Struct(
    "magic" / Const(0x105, UInt16),
    "_numBiomes" / Rebuild(UInt32, len_(this.biomeIds)),
    "biomeIds" / UInt32[this._numBiomes],
    Const(2, UInt32),
    Const(GRID_SIZE, UInt32[2]),
    Const(GRID_FLATSIZE, UInt32),
    "biomeGridN" / UInt32[GRID_FLATSIZE],
    Const(GRID_FLATSIZE, UInt32),
    "resrcGridN" / UInt8[GRID_FLATSIZE],
    Const(GRID_SIZE, UInt32[2]),
    Const(GRID_FLATSIZE, UInt32),
    "biomeGridS" / UInt32[GRID_FLATSIZE],
    Const(GRID_FLATSIZE, UInt32),
    "resrcGridS" / UInt8[GRID_FLATSIZE],
)

KNOWN_RESOURCE_IDS = (8, 88, 0, 80, 1, 81, 2, 82, 3, 83, 4, 84)

with open(Path(__file__).parent.resolve() / "./biomes.csv", newline="") as csvfile:
    reader = csv.DictReader(csvfile, fieldnames=("edid", "id", "name"))
    KNOWN_BIOMES = {int(x["id"], 16): (x["edid"], x["name"]) for x in reader}


def get_biome_names(id):
    entry = KNOWN_BIOMES.get(id, None)
    return entry if entry else (str(id), str(id))


class BiomFile(object):
    def __init__(self):
        self.planet_name = None
        self.biomeIds = set()
        self.resourcesPerBiomeId = dict()
        self.biomeGridN = []
        self.resrcGridN = []
        self.biomeGridS = []
        self.resrcGridS = []

    def load(self, filename):
        assert filename.endswith(".biom")
        with open(filename, "rb") as f:
            data = CsSF_Biom.parse_stream(f)
            assert not f.read()
        self.biomeIds = tuple(data.biomeIds)
        self.biomeGridN = np.array(data.biomeGridN)
        self.biomeGridS = np.array(data.biomeGridS)
        self.resrcGridN = np.array(data.resrcGridN)
        self.resrcGridS = np.array(data.resrcGridS)
        resourcesPerBiomeId = {biomeId: set() for biomeId in self.biomeIds}
        for i, biomeId in enumerate(self.biomeGridN):
            resourcesPerBiomeId[biomeId].add(self.resrcGridN[i])
        for i, biomeId in enumerate(self.biomeGridS):
            resourcesPerBiomeId[biomeId].add(self.resrcGridS[i])
        self.resourcesPerBiomeId = resourcesPerBiomeId
        self.biomesDesc = {
            "{}_{}".format(get_biome_names(id), id): sorted(value)
            for id, value in self.resourcesPerBiomeId.items()
        }
        self.planet_name = Path(filename).stem
        print(f"Loaded '{filename}'.")

    def save(self, filename):
        assert filename.endswith(".biom")
        obj = dict(
            biomeIds=sorted(set(self.biomeGridN) | set(self.biomeGridS)),
            biomeGridN=self.biomeGridN,
            biomeGridS=self.biomeGridS,
            resrcGridN=self.resrcGridN,
            resrcGridS=self.resrcGridS,
        )
        assert len(self.biomeGridN) == 0x10000
        assert len(self.biomeGridS) == 0x10000
        assert len(self.resrcGridN) == 0x10000
        assert len(self.resrcGridS) == 0x10000
        with open(filename, "wb") as f:
            CsSF_Biom.build_stream(obj, f)
        print(f"Saved '{filename}'.")

    def export_to_text(self, filename="biom_export.txt"):
        with open(filename, "w") as f:
            f.write(f"Planet: {self.planet_name}\n")
            f.write(f"Biome IDs: {self.biomeIds}\n\n")

            f.write("Northern Hemisphere:\n")
            for y in range(GRID_SIZE[1]):
                row = " ".join(f"{self.biomeGridN[y * GRID_SIZE[0] + x]:02X}" for x in range(GRID_SIZE[0]))
                f.write(row + "\n")

            f.write("\nSouthern Hemisphere:\n")
            for y in range(GRID_SIZE[1]):
                row = " ".join(f"{self.biomeGridS[y * GRID_SIZE[0] + x]:02X}" for x in range(GRID_SIZE[0]))
                f.write(row + "\n")

            f.write("\nResource Data:\n")
            for biome_id, resources in self.resourcesPerBiomeId.items():
                biome_name = get_biome_names(biome_id)[1]
                resource_list = ", ".join(str(r) for r in sorted(resources))
                f.write(f"Biome {biome_name} ({biome_id}): {resource_list}\n")

        print(f"Exported data to {filename}.")

    def swap_biomes(self, old_biome, new_biome):
        # Convert old and new biome IDs from hex to int
        old_biome_int = int(old_biome, 16)
        new_biome_int = int(new_biome, 16)

        # Log resource counts before swap
        old_biome_resources = np.sum(self.biomeGridN == old_biome_int)
        print(
            f"Old biome {old_biome}: {old_biome_resources} resources in the north grid."
        )

        # Swap biomes
        self.biomeGridN[self.biomeGridN == old_biome_int] = new_biome_int
        self.biomeGridS[self.biomeGridS == old_biome_int] = new_biome_int

        # Log resource counts after swap
        new_biome_resources = np.sum(self.biomeGridN == new_biome_int)
        print(
            f"New biome {new_biome}: {new_biome_resources} resources in the north grid."
        )

        # Swap resource grids as well
        self.resrcGridN[self.biomeGridN == old_biome_int] = self.resrcGridN[
            self.biomeGridN == old_biome_int
        ]
        self.resrcGridS[self.biomeGridS == old_biome_int] = self.resrcGridS[
            self.biomeGridS == old_biome_int
        ]

        # Update resources per biome ID map
        if old_biome_int in self.resourcesPerBiomeId:
            self.resourcesPerBiomeId[new_biome_int] = self.resourcesPerBiomeId.pop(
                old_biome_int
            )

        print(
            f"Replaced biome {old_biome} with {new_biome} in the grids, with resources."
        )

    def randomize_biomes(self, csv_file):
        # Read CSV file to create a mapping of biome names to their hex IDs
        biome_options = {}
        
        # Check if the CSV file exists in the directory and is readable
        import os
        if not os.path.isfile(csv_file):
            print(f"Error: The file {csv_file} does not exist.")
            return
        
        print(f"Updating biomes with new ones from {csv_file}.")
        
        # Read the CSV file
        with open(csv_file, 'r') as f:
            reader = csv.reader(f, delimiter=',')
            
            # Skip the first row (header row)
            next(reader)
            
            for row in reader:
                # Skip empty rows or rows that don't have the expected number of columns
                if len(row) < 2:
                    continue  # Skip this row
                
                biome_name = row[0]  # Biome name
                biome_id = row[1]    # Biome ID (hex)
                print(f"Found biome: {biome_name} with ID: {biome_id}")  # Debug log
                
                # Populate the biome options dictionary
                if biome_name not in biome_options:
                    biome_options[biome_name] = biome_id

        # Debug print the contents of biome_options
        print(f"Biomes loaded from CSV: {biome_options}")
        
        # Check if the biome list is empty
        if not biome_options:
            print("Error: No valid biomes found in the CSV file.")
            return

        # Replace biomes in both grids randomly
        for i in range(self.biomeGridN.size):  # Iterate over all grid positions
            # Randomly pick a new biome ID from the available biomes
            random_biome = random.choice(list(biome_options.values()))
            self.biomeGridN.flat[i] = np.uint32(int(random_biome, 16))  # Convert to uint32
            self.biomeGridS.flat[i] = np.uint32(int(random_biome, 16))  # Convert to uint32

        print(f"Biomes have been randomly replaced with those from {csv_file}.")

    def plot2d(self, only_biomes=False, only_resources=False):
        b2i = {id: i for i, id in enumerate(self.biomeIds)}
        b2n = {id: get_biome_names(id) for id in self.biomeIds}
        r2i = {id: i for i, id in enumerate(KNOWN_RESOURCE_IDS)}

        biomeNameGridN = np.reshape([b2n[x][0] for x in self.biomeGridN], GRID_SIZE)
        biomeNameGridS = np.reshape([b2n[x][0] for x in self.biomeGridS], GRID_SIZE)
        biomeShortNameGridN = np.reshape(
            [b2n[x][1] for x in self.biomeGridN], GRID_SIZE
        )
        biomeShortNameGridS = np.reshape(
            [b2n[x][1] for x in self.biomeGridS], GRID_SIZE
        )
        biomeIdxGridN = np.reshape([b2i[x] for x in self.biomeGridN], GRID_SIZE)
        biomeIdxGridS = np.reshape([b2i[x] for x in self.biomeGridS], GRID_SIZE)
        resGridN = np.reshape(self.resrcGridN, GRID_SIZE)
        resGridS = np.reshape(self.resrcGridS, GRID_SIZE)
        resIdxGridN = np.reshape([r2i[x] for x in self.resrcGridN], GRID_SIZE)
        resIdxGridS = np.reshape([r2i[x] for x in self.resrcGridS], GRID_SIZE)

        biomeNameGrid = np.hstack((biomeNameGridN, biomeNameGridS))
        biomeShortNameGrid = np.hstack((biomeShortNameGridN, biomeShortNameGridS))
        biomeIdxGrid = np.hstack((biomeIdxGridN, biomeIdxGridS))
        resGrid = np.hstack((resGridN, resGridS))
        resIdxGrid = np.hstack((resIdxGridN, resIdxGridS))

        if only_biomes:
            combinedGrid = biomeIdxGrid
        elif only_resources:
            combinedGrid = resIdxGrid
        else:
            combinedGrid = (resIdxGrid + 1) * len(b2i) + biomeIdxGrid * 2

        # fig = plsp.make_subplots(rows=2, cols=1)
        fig = plgo.Figure()
        fig.add_trace(
            plgo.Heatmap(
                z=np.rot90(combinedGrid.T),
                customdata=np.dstack(
                    (
                        np.rot90(biomeNameGrid.T),
                        np.rot90(biomeShortNameGrid.T),
                        np.rot90(resGrid.T),
                    )
                ),
                hovertemplate="%{customdata[0]}<br>%{customdata[1]}<br>resource: %{customdata[2]}",
                colorscale="Cividis",
                showscale=False,
                name="",
            )
        )
        pname = self.planet_name.capitalize()
        space_index = pname.find(" ")
        if space_index > 0:
            pname = pname[:space_index] + pname[space_index:].upper()
        fig.update_layout(
            yaxis=dict(
                scaleanchor="x",
                scaleratio=1,
            ),
            title_text=f"<b>{pname}</b>",
        )
        fig.show()

    # def save_png(self):
    # im2 = Image.fromarray(biome_b).convert('RGB')
    # im2.save(r'./biome_b.png')
    # raise

def main():
    parser = argparse.ArgumentParser(
        description="Swap biomes in a biom file or export biome data."
    )
    parser.add_argument(
        "-f", "--filename", type=str, required=True, help="Path to the biom file"
    )
    parser.add_argument(
        "-o", "--old_biome", type=str, help="Biome ID to replace (hexadecimal)"
    )
    parser.add_argument(
        "-n", "--new_biome", type=str, help="Biome ID to replace with (hexadecimal)"
    )
    parser.add_argument(
        "-e", "--export", action="store_true", help="Export biome data to text"
    )
    parser.add_argument("-p", "--plot", action="store_true", help="Plot the biome grid")
    parser.add_argument(
        "-pb", "--plot_biomes", action="store_true", help="Plot only biome data"
    )
    parser.add_argument(
        "-pr", "--plot_resources", action="store_true", help="Plot only resource data"
    )
    parser.add_argument(
        "-u", "--update_biomes", action="store_true", help="Randomize biomes from the biom_update.csv file"
    )

    args = parser.parse_args()

    biom = BiomFile()
    biom.load(args.filename)

    if args.export:
        biom.export_to_text()
        return  # Exit after exporting
    
    # If the update flag is set, randomize the biomes from the CSV file
    if args.update_biomes:
        if not args.filename.endswith(".biom"):
            print("The file should be a .biom file for biome update.")
            return
        csv_file = "biom_update.csv"  # Define the CSV path here
        biom.randomize_biomes(csv_file)
        biom.save(args.filename)  # Save the updated file
        return

    # Plot the biomes if -p/--plot is provided, limit to biomes if -pb or recources if -pr
    if args.plot or args.plot_biomes or args.plot_resources:
        biom.plot2d(only_biomes=args.plot_biomes, only_resources=args.plot_resources)

    #if args.plot3d or (args.plot3d_biomes and args.plot3d_resources):
    #    biom.plot3d("both")  # Assuming the function can handle this
    #elif args.plot3d_biomes:
    #    biom.plot3d("biomes")
    #elif args.plot3d_resources:
    #    biom.plot3d("resources")

    if args.old_biome and args.new_biome:
        biom.swap_biomes(args.old_biome, args.new_biome)
        new_filename = f"{args.new_biome}_{Path(args.filename).name}"
        biom.save(new_filename)
    else:
        print("No biome swap requested, just loaded the file.")

if __name__ == "__main__":
    main()
