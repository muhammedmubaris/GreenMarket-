const express = require('express');
const router = express.Router();

// ==========================================
// MOCK DATA (In-Memory Database for MVP)
// ==========================================

const trucks = [
    { id: 'TN-58-AB-1234', location: { lat: 9.9390, lng: 78.1217 }, ward: 14, payload_kg: 2450, status: 'active', last_update: new Date() },
    { id: 'TN-59-XY-9876', location: { lat: 9.9195, lng: 78.1195 }, ward: 21, payload_kg: 0, status: 'transit', last_update: new Date() } // Potential Phantom Trip
];

const blackspots = [
    { id: 'BS-001', location: { lat: 9.9250, lng: 78.1150 }, volume_est_kg: 45, status: 'reported', spotted_by: 'CCTV-CAM-14' },
    { id: 'BS-002', location: { lat: 9.9320, lng: 78.1400 }, volume_est_kg: 120, status: 'dispatched', worker_id: 'W-405' }
];

const hygieneLedger = [
    { facility_id: 'PUB-T-Mattuthavani', voc_ammonia_ppm: 14, footfall: 450, score: 88, status: 'Good' },
    { facility_id: 'PUB-T-Periyar', voc_ammonia_ppm: 46, footfall: 890, score: 42, status: 'Critical - Payment Hold' }
];

const b2bMarketplace = [
    { lot_id: 'LOT-991', vendor: 'Ramesh Fruits', type: 'organic_spoilage', amount_kg: 50, price_inr: 50, location: 'Mattuthavani', status: 'available' },
    { lot_id: 'LOT-992', vendor: 'Kannan Veg', type: 'vegetable_peels', amount_kg: 120, price_inr: 100, location: 'Paravai', status: 'sold', buyer: 'GreenBioGas Inc.' }
];

const vellakkalData = {
    baseline_volume_m3: 1500000,
    current_volume_m3: 1485000,
    processed_this_week_tons: 850,
    last_drone_flight: new Date(Date.now() - 86400000 * 2) // 2 days ago
};


// ==========================================
// SOLUTION 1: KUPPAI VANDI (Logistics API)
// ==========================================

// GET all truck locations
router.get('/trucks', (req, res) => {
    res.json({ success: true, count: trucks.length, data: trucks });
});

// GET specific truck by ID (For public tracking)
router.get('/trucks/:id', (req, res) => {
    const truck = trucks.find(t => t.id === req.params.id);
    if (!truck) return res.status(404).json({ success: false, message: 'Truck not found' });
    res.json({ success: true, data: truck });
});


// ==========================================
// SOLUTION 2: BLACK SPOT (Computer Vision API)
// ==========================================

// GET all active black spots
router.get('/blackspots', (req, res) => {
    res.json({ success: true, count: blackspots.length, data: blackspots });
});

// POST to report a new black spot (Webhook for AI Video Analyzer)
router.post('/blackspots', (req, res) => {
    const { lat, lng, volume_est_kg, source } = req.body;
    if (!lat || !lng || !volume_est_kg) {
        return res.status(400).json({ success: false, message: 'Missing required detection telemetry.' });
    }

    const newSpot = {
        id: `BS-${Math.floor(Math.random() * 1000)}`,
        location: { lat, lng },
        volume_est_kg,
        status: 'reported',
        spotted_by: source || 'External API'
    };
    blackspots.push(newSpot);

    // In a real app, this triggers SMS to ward worker
    res.status(201).json({ success: true, message: 'Work order generated.', data: newSpot });
});


// ==========================================
// SOLUTION 3: VELLAKKAL DIGITAL TWIN
// ==========================================

// GET latest volumetric data
router.get('/vellakkal/metrics', (req, res) => {
    res.json({ success: true, data: vellakkalData });
});


// ==========================================
// SOLUTION 4: SMART TOILET HYGIENE LEDGER
// ==========================================

// GET all facility statuses
router.get('/toilets', (req, res) => {
    res.json({ success: true, data: hygieneLedger });
});

// POST IoT sensor telemetry
router.post('/toilets/telemetry', (req, res) => {
    const { facility_id, voc_ammonia_ppm, footfall_increment } = req.body;
    // Logic to update ledger and recalculate score would go here
    res.status(200).json({ success: true, message: 'Telemetry securely logged to ledger pipeline.' });
});


// ==========================================
// SOLUTION 5: B2B WASTE MARKETPLACE
// ==========================================

// GET available organic waste lots
router.get('/market/lots', (req, res) => {
    const available = b2bMarketplace.filter(lot => lot.status === 'available');
    res.json({ success: true, count: available.length, data: available });
});

// POST new waste listing (Vendor PWA)
router.post('/market/lots', (req, res) => {
    const { vendor, type, amount_kg, price_inr, location } = req.body;

    const newLot = {
        lot_id: `LOT-${Math.floor(1000 + Math.random() * 9000)}`,
        vendor, type, amount_kg, price_inr, location,
        status: 'available'
    };

    b2bMarketplace.push(newLot);
    res.status(201).json({ success: true, message: 'Lot listed on marketplace.', data: newLot });
});

module.exports = router;
