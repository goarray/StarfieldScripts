import argparse
from construct import Struct, Const, Int32ul as UInt32, Int16ul as UInt16, Int8ul as UInt8
import csv

# Argument parser setup
parser = argparse.ArgumentParser(description="Parse biome resource grid data")
parser.add_argument("-f", "--file", required=True, help="Path to the .biom file")
args = parser.parse_args()

GRID_SIZE = [256, 256]
GRID_FLATSIZE = GRID_SIZE[0] * GRID_SIZE[1]

CsSF_Biom = Struct(
    "magic" / Const(0x105, UInt16),
    "_numBiomes" / UInt32,
    "biomeIds" / UInt32[lambda ctx: ctx._numBiomes],
    "unknownBlock1" / UInt32,
    "gridSize1" / UInt32[2],
    "flatSize1" / UInt32,
    "biomeGridN" / UInt32[GRID_FLATSIZE],
    "flatSize2" / UInt32,
    "resrcGridN" / UInt8[GRID_FLATSIZE],
    "gridSize2" / UInt32[2],
    "flatSize3" / UInt32,
    "biomeGridS" / UInt32[GRID_FLATSIZE],
    "flatSize4" / UInt32,
    "resrcGridS" / UInt8[GRID_FLATSIZE],
)

# CSV file name (auto-generated based on input file name)
csv_filename = args.file.replace(".biom", "_resource_grid.csv")

# Open the specified .biom file
with open(args.file, "rb") as f:
    biom_data = CsSF_Biom.parse_stream(f)

# Open CSV for writing
with open(csv_filename, mode="w", newline="", encoding="utf-8") as csv_file:
    writer = csv.writer(csv_file)

    # Write column headers (optional)
    writer.writerow(["Col_" + str(i) for i in range(GRID_SIZE[0])])

    # Write the grid rows with binary formatting
    for row in range(GRID_SIZE[1]):
        start_idx = row * GRID_SIZE[0]
        end_idx = start_idx + GRID_SIZE[0]

        # Convert values to binary and ensure two digits
        binary_row = [bin(val)[2:].zfill(8) for val in biom_data.resrcGridN[start_idx:end_idx]]  
        
        writer.writerow(binary_row)

print(f"Grid data successfully saved to {csv_filename} with bit formatting!")


