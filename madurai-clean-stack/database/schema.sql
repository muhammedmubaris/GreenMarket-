-- ==============================================================================
-- MADURAI CLEAN-STACK POSTGRESQL SCHEMA WITH POSTGIS
-- Description: Core database schema for Logistics, IoT, and Marketplace
-- Note: Requires PostGIS extension enabled (CREATE EXTENSION postgis;)
-- ==============================================================================

-- Enable PostGIS for geospatial data handling (Trucks, Dump spots, etc)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- SOLUTION 1: KUPPAI VANDI (GARBAGE TRUCKS)
-- ==========================================
CREATE TABLE IF NOT EXISTS trucks (
    id SERIAL PRIMARY KEY,
    vehicle_number VARCHAR(20) UNIQUE NOT NULL,
    ward_assigned INT NOT NULL,
    capacity_kg DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'transit', 'off_duty')),
    last_known_location GEOMETRY(Point, 4326), -- Longitude, Latitude
    current_payload_kg DECIMAL(10, 2) DEFAULT 0.00,
    last_telemetry_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS truck_telemetry_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    truck_id INT REFERENCES trucks(id) ON DELETE CASCADE,
    location GEOMETRY(Point, 4326),
    payload_kg DECIMAL(10, 2),
    speed_kmh INT DEFAULT 0,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indices for fast geospatial querying
CREATE INDEX idx_truck_location ON trucks USING GIST (last_known_location);


-- ==========================================
-- SOLUTION 2: BLACK SPOT (COMPUTER VISION)
-- ==========================================
CREATE TABLE IF NOT EXISTS black_spots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location GEOMETRY(Point, 4326) NOT NULL,
    ward_id INT,
    estimated_volume_kg DECIMAL(10, 2),
    status VARCHAR(50) DEFAULT 'reported' CHECK (status IN ('reported', 'dispatched', 'cleaning', 'resolved')),
    spotted_by_camera_id VARCHAR(100), -- ID of the CCTV or Dashcam
    image_proof_url TEXT, -- S3/GCP bucket URL to the initial frame
    resolved_image_url TEXT, -- Worker upload proof
    assigned_worker_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

CREATE INDEX idx_blackspot_location ON black_spots USING GIST (location);


-- ==========================================
-- SOLUTION 3: VELLAKKAL DIGITAL TWIN
-- ==========================================
CREATE TABLE IF NOT EXISTS vellakkal_biomining_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    survey_date DATE NOT NULL,
    baseline_volume_m3 DECIMAL(15, 2) NOT NULL,
    estimated_current_volume_m3 DECIMAL(15, 2) NOT NULL,
    processed_volume_m3 DECIMAL(15, 2) GENERATED ALWAYS AS (baseline_volume_m3 - estimated_current_volume_m3) STORED,
    drone_mesh_url TEXT, -- 3D model link (GLTF/OBJ)
    auditor_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ==========================================
-- SOLUTION 4: SMART TOILET HYGIENE LEDGER
-- ==========================================
CREATE TABLE IF NOT EXISTS smart_toilets (
    facility_id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location GEOMETRY(Point, 4326),
    ward_id INT NOT NULL,
    contractor_id VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'operational'
);

CREATE TABLE IF NOT EXISTS hygiene_telemetry (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    facility_id VARCHAR(100) REFERENCES smart_toilets(facility_id) ON DELETE CASCADE,
    voc_ammonia_ppm DECIMAL(8, 2) NOT NULL, -- Odor sensor
    footfall_count INT DEFAULT 0,
    daily_hygiene_score DECIMAL(5, 2), -- 0 to 100
    blockchain_tx_hash VARCHAR(255), -- If anchored on Polygon
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ==========================================
-- SOLUTION 5: B2B WASTE MARKETPLACE
-- ==========================================
CREATE TABLE IF NOT EXISTS marketplace_vendors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    business_type VARCHAR(100), -- 'Market', 'Restaurant', etc.
    upi_id VARCHAR(255),
    location GEOMETRY(Point, 4326),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS organic_waste_lots (
    lot_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id UUID REFERENCES marketplace_vendors(id) ON DELETE CASCADE,
    waste_type VARCHAR(100) NOT NULL, -- 'fruits', 'veg_peels', 'mixed_organic'
    amount_kg DECIMAL(10, 2) NOT NULL,
    price_inr DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'available' CHECK (status IN ('available', 'reserved', 'sold', 'expired')),
    buyer_id VARCHAR(100), -- ID of biogas/compost plant
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sold_at TIMESTAMP
);

CREATE INDEX idx_vendor_location ON marketplace_vendors USING GIST (location);

-- ==========================================
-- MOCK DATA INJECTION
-- ==========================================

-- Insert Default Trucks
INSERT INTO trucks (vehicle_number, ward_assigned, capacity_kg, status, last_known_location, current_payload_kg)
VALUES 
('TN-58-AB-1234', 14, 5000, 'active', ST_GeomFromText('POINT(78.1217 9.9390)', 4326), 2450.00),
('TN-59-XY-9876', 21, 5000, 'transit', ST_GeomFromText('POINT(78.1195 9.9195)', 4326), 0.00);

-- Insert Default Black Spots
INSERT INTO black_spots (location, ward_id, estimated_volume_kg, status, spotted_by_camera_id)
VALUES
(ST_GeomFromText('POINT(78.1150 9.9250)', 4326), 14, 45.5, 'reported', 'CCTV-CAM-14'),
(ST_GeomFromText('POINT(78.1400 9.9320)', 4326), 21, 120.0, 'dispatched', 'BUS-DASH-45');

-- Insert Smart Toilets
INSERT INTO smart_toilets (facility_id, name, location, ward_id, contractor_id)
VALUES
('PUB-T-Mattuthavani', 'Mattuthavani Bus Stand Block A', ST_GeomFromText('POINT(78.1510 9.9440)', 4326), 45, 'CONT-001'),
('PUB-T-Periyar', 'Periyar Bus Stand', ST_GeomFromText('POINT(78.1147 9.9168)', 4326), 7, 'CONT-002');

-- Insert Market Vendor & Lot
INSERT INTO marketplace_vendors (name, business_type, upi_id, location)
VALUES
('Ramesh Fruits', 'Market Vendor', 'ramesh@paytm', ST_GeomFromText('POINT(78.1515 9.9430)', 4326));

INSERT INTO organic_waste_lots (vendor_id, waste_type, amount_kg, price_inr)
SELECT id, 'spoiled_tomatoes', 50.00, 50.00 
FROM marketplace_vendors 
WHERE name = 'Ramesh Fruits';
