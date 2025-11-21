# Grid Tile Generator

This service generates vector tiles from the GRID2022 geodatabase. It's designed to run **once** (or whenever you need to regenerate tiles from updated data).

## What It Does

Converts the `GRID2022.gdb` file into an `.mbtiles` file containing vector tiles with pre-calculated colors based on population data.

## Prerequisites

- Docker with buildx support
- The `GRID2022/GRID2022.gdb` directory with your geodatabase

## Building

```bash
./build.sh
```

This will:
1. Build the Docker image for ARM64 (Raspberry Pi)
2. Push to `kaljo14/grid-tile-generator:latest`

## Running Locally (Docker)

```bash
docker run -v $(pwd)/GRID2022:/app/GRID2022 -v $(pwd)/tiles:/data kaljo14/grid-tile-generator:latest
```

This will generate `tiles/grid.mbtiles`.

## Running on Kubernetes

You can run this as a Kubernetes **Job** (one-time execution):

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: grid-tile-generator
spec:
  template:
    spec:
      containers:
      - name: generator
        image: kaljo14/grid-tile-generator:latest
        volumeMounts:
        - name: tiles
          mountPath: /data
      restartPolicy: Never
      volumes:
      - name: tiles
        persistentVolumeClaim:
          claimName: tiles-pvc
```

## Output

The generated `grid.mbtiles` file will be in the `/data` directory (or your mounted volume). This file is then used by the tileserver to serve the tiles.

## When to Re-run

Only re-run this when:
- You have updated GRID2022 data
- You want to change the color scheme or tile generation parameters
