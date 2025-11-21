import os
import json
import geopandas as gpd
import mapclassify
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import subprocess

# Configuration
GDB_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "GRID2022/GRID2022.gdb"))
OUTPUT_DIR = "/data" # This will be mounted to ./tiles
GEOJSON_PATH = os.path.join(OUTPUT_DIR, "grid.geojson")
MBTILES_PATH = os.path.join(OUTPUT_DIR, "grid.mbtiles")

def generate_tiles():
    print(f"Loading data from {GDB_PATH}...")
    
    try:
        # 1. Load Data
        gdf = gpd.read_file(GDB_PATH, engine="pyogrio")
        
        # Reproject if needed
        if gdf.crs and gdf.crs.to_string() != "EPSG:4326":
            print("Reprojecting to EPSG:4326...")
            gdf = gdf.to_crs(epsg=4326)

        # 2. Generate Colors
        print("Generating colors...")
        population = gdf['T'].fillna(0).values
        k = 7
        classifier = mapclassify.NaturalBreaks(population, k=k)
        cmap = plt.cm.get_cmap('plasma', k)
        
        classes = classifier(population)
        
        # Add color column to GeoDataFrame
        # We do this vectorized for performance instead of iterating
        colors_hex = [mcolors.to_hex(cmap(c)) for c in classes]
        gdf['fillColor'] = colors_hex
        gdf['fillOpacity'] = 0.7
        gdf['weight'] = 1
        
        # 3. Export to GeoJSON
        print(f"Exporting to {GEOJSON_PATH}...")
        # Ensure output directory exists
        os.makedirs(OUTPUT_DIR, exist_ok=True)
        
        gdf.to_file(GEOJSON_PATH, driver="GeoJSON")
        
        # 4. Run Tippecanoe
        print(f"Running Tippecanoe to generate {MBTILES_PATH}...")
        # -zg: Automatically choose zoom levels
        # --drop-densest-as-needed: Drop features if too many at low zooms
        # --extend-zooms-if-still-dropping: Allow deeper zooms if needed
        # --force: Overwrite existing
        cmd = [
            "tippecanoe",
            "-o", MBTILES_PATH,
            "-zg",
            "--drop-densest-as-needed",
            "--extend-zooms-if-still-dropping",
            "--force",
            GEOJSON_PATH
        ]
        
        subprocess.run(cmd, check=True)
        
        print("Tile generation complete!")
        
        # Cleanup GeoJSON to save space
        if os.path.exists(GEOJSON_PATH):
            os.remove(GEOJSON_PATH)
            print("Cleaned up temporary GeoJSON file.")
            
    except Exception as e:
        print(f"Error generating tiles: {e}")
        exit(1)

if __name__ == "__main__":
    generate_tiles()
