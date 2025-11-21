FROM python:3.9-slim

# Install system dependencies for GDAL
# Install system dependencies for GDAL and Tippecanoe
RUN apt-get update && apt-get install -y \
    gdal-bin \
    libgdal-dev \
    g++ \
    make \
    libsqlite3-dev \
    zlib1g-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# Build and install Tippecanoe
RUN git clone https://github.com/mapbox/tippecanoe.git \
    && cd tippecanoe \
    && make -j \
    && make install \
    && cd .. \
    && rm -rf tippecanoe

# Set environment variables for GDAL
ENV CPLUS_INCLUDE_PATH=/usr/include/gdal
ENV C_INCLUDE_PATH=/usr/include/gdal

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Create directory for tiles
RUN mkdir -p /data

# Run the generation script
CMD ["python", "generate_tiles.py"]
