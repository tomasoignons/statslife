-- Enable PostGIS extension if not already enabled
CREATE EXTENSION IF NOT EXISTS postgis;

-- Drop existing tables if they exist
DROP TABLE IF EXISTS statslife.tiles CASCADE;

-- Create tables in the statslife schema
CREATE TABLE statslife.tiles (
    id SERIAL PRIMARY KEY,
    schema VARCHAR(50) NOT NULL,
    grid_id VARCHAR(50) NOT NULL,
    color VARCHAR(50) NOT NULL,
    priority INTEGER NOT NULL, -- Priority for display order
    geom geometry(Polygon, 4326),
    center_point geometry(Point, 4326),
    visited_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(schema, grid_id, color) -- Allow multiple colors per grid cell
);

-- Create indexes
CREATE INDEX idx_tiles_geom ON statslife.tiles USING GIST (geom);
CREATE INDEX idx_tiles_grid_id ON statslife.tiles(schema, grid_id);
CREATE INDEX idx_tiles_color ON statslife.tiles(color);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION statslife.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER;

-- Create triggers for updated_at columns
CREATE TRIGGER update_tiles_updated_at
    BEFORE UPDATE ON statslife.tiles
    FOR EACH ROW
    EXECUTE FUNCTION statslife.update_updated_at_column();

-- Enable RLS
ALTER TABLE statslife.tiles ENABLE ROW LEVEL SECURITY;

-- Grant access to authenticated users
CREATE POLICY "Enable all access for authenticated users" ON statslife.tiles
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Grant access to anon users (for read-only)
CREATE POLICY "Enable read access for all users" ON statslife.tiles
    FOR SELECT
    TO anon
    USING (true); 