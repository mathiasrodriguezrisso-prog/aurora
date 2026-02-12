# Aurora Climate APIs Documentation

**Base URL:** `/climate`  
**Authentication:** Optional  
**Rate Limiting:** None (currently unlimited)

---

## Overview

The Climate APIs provide real-time calculations for Vapor Pressure Deficit (VPD) and climate condition recommendations. VPD is crucial for optimizing cannabis cultivation and plant health.

**What is VPD?**
Vapor Pressure Deficit (VPD) is the difference between the amount of moisture in the air and how much moisture the air can hold at a given temperature. It's measured in kilopascals (kPa) and influences:
- Plant transpiration rates
- Nutrient uptake efficiency
- Growth velocity
- Bud development and density

---

## Endpoints

### 1. GET /climate/vpd

Calculate current VPD and get growth stage recommendations.

**Query Parameters:**
```
temp: float    (required) - Temperature in °C (-50 to 50)
humidity: float (required) - Relative humidity in % (0-100)
```

**Response (200 OK):**
```json
{
  "temperature_c": 25.0,
  "relative_humidity_percent": 60,
  "vpd_kpa": 1.583,
  "saturation_vapor_pressure_kpa": 3.167,
  "actual_vapor_pressure_kpa": 1.584,
  "growth_stage_optimal": "Vegetative Growth",
  "growth_stage_acceptable": "Vegetative (2-8 weeks)",
  "recommendations": [
    "VPD is ideal for vegetative growth",
    "Plants should show strong transpiration",
    "Maintain consistent light and ventilation"
  ],
  "warning": null
}
```

**Formula Used:**
```
Saturation VP: es(T) = 0.6108 × exp(17.27 × T / (T + 237.3))
Actual VP: ea = RH% / 100 × es(T)
VPD = es(T) - ea
```

**Request Examples:**

**Curl Example:**
```bash
curl "http://localhost:8000/climate/vpd?temp=25&humidity=60"
```

**Python Example:**
```python
import requests

response = requests.get(
    "http://localhost:8000/climate/vpd",
    params={
        "temp": 25.0,
        "humidity": 60
    }
)

vpd_data = response.json()
print(f"VPD: {vpd_data['vpd_kpa']} kPa")
print(f"Stage: {vpd_data['growth_stage_optimal']}")
print(f"Tips: {vpd_data['recommendations']}")
```

**JavaScript Example:**
```javascript
const response = await fetch(
  '/climate/vpd?temp=25&humidity=60'
);
const data = await response.json();
console.log(`VPD: ${data.vpd_kpa} kPa`);
console.log(`Recommendations: ${data.recommendations}`);
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| temperature_c | float | Input temperature in Celsius |
| relative_humidity_percent | float | Input relative humidity (0-100%) |
| vpd_kpa | float | Calculated VPD in kilopascals |
| saturation_vapor_pressure_kpa | float | es(T) - saturation VP |
| actual_vapor_pressure_kpa | float | ea - actual VP at given RH |
| growth_stage_optimal | string | Optimal growth stage for VPD |
| growth_stage_acceptable | string | Acceptable growth stages |
| recommendations | array | Actionable tips for conditions |
| warning | string OR null | Alert if conditions are critical |

**Possible Errors:**

| Status | Description |
|--------|-------------|
| 400 | Invalid temperature or humidity value |
| 500 | CLIMATE_VPD_ERROR - Calculation failure |

**Error Response Example:**
```json
{
  "error": "VPD calculation failed",
  "detail": "An unexpected error occurred",
  "code": "CLIMATE_VPD_ERROR"
}
```

---

## VPD Optimal Ranges by Growth Stage

### Seedling (0-2 weeks)
- **Optimal VPD:** 0.5-1.0 kPa
- **Temperature:** 18-22°C
- **Humidity:** 60-80%
- **Why:** High humidity protects young plants, slower initial growth is normal

### Vegetative (2-8 weeks)
- **Optimal VPD:** 1.0-1.3 kPa
- **Temperature:** 22-26°C
- **Humidity:** 45-65%
- **Why:** Moderate VPD promotes strong leaf/stem development

### Early Flower (0-2 weeks)
- **Optimal VPD:** 1.2-1.5 kPa
- **Temperature:** 24-28°C
- **Humidity:** 40-60%
- **Why:** Transitioning to flowering requires stable climate

### Peak Flower (2-6 weeks)
- **Optimal VPD:** 1.0-1.5 kPa
- **Temperature:** 22-28°C
- **Humidity:** 40-55%
- **Why:** Critical for bud development and resin production

### Late Flower (6-8 weeks)
- **Optimal VPD:** 0.8-1.2 kPa
- **Temperature:** 20-26°C
- **Humidity:** 40-50%
- **Why:** Reduced humidity helps reduce mold risk during finish

---

## VPD Interpretation Guide

| VPD Range | Interpretation | Actions |
|-----------|-----------------|---------|
| < 0.3 kPa | **Critical Low** | Increase temp or lower humidity immediately |
| 0.3-0.5 kPa | **Too Low** | High disease risk, improve air circulation |
| 0.5-1.0 kPa | **Seedling Optimal** | Good for young plants, gradual transitions |
| 1.0-1.3 kPa | **Vegetative Optimal** | Ideal for growth, strong transpiration |
| 1.3-1.5 kPa | **Flowering Optimal** | Best for bud development |
| 1.5-1.8 kPa | **High** | Monitor closely, ensure water availability |
| 1.8-2.0 kPa | **Very High** | Plants may be stressed, increase humidity |
| > 2.0 kPa | **Critical** | Severe stress, immediate action needed |

---

## Quick Reference: Temperature & Humidity Combos

**For 25°C target temperature:**

| Humidity | VPD | Stage | Notes |
|----------|-----|-------|-------|
| 80% | 0.63 | Seedling | Very humid, good for clones |
| 70% | 0.95 | Early Veg | Transitioning |
| 60% | 1.27 | Vegetative | Ideal for growth |
| 50% | 1.58 | Flowering | Good for flowers |
| 40% | 1.90 | Late Flower | Dry, watch for stress |
| 30% | 2.21 | Critical | Too dry, stress |

---

## Climate Control Strategies

### To Increase VPD (Too Humid: < 1.0 kPa)
1. ✅ **Increase temperature** (easiest, most effective)
2. ✅ **Lower humidity** using dehumidifier
3. ✅ **Improve ventilation** with exhaust fans
4. ✅ **Reduce watering frequency**

### To Decrease VPD (Too Dry: > 1.5 kPa)
1. ✅ **Lower temperature** slightly
2. ✅ **Increase humidity** 
   - Add humidifier
   - Mist plants (NOT during lights-on)
   - Add water trays
3. ✅ **Reduce air circulation** (partially close exhaust)
4. ✅ **Ensure water availability** (deeper watering)

### Golden Rule
> **VPD control = Temperature + Humidity management together, not separately**

Temperature changes cause the biggest VPD shifts, so adjust humidity accordingly.

---

## Real-World Examples

### Example 1: Seedling Setup
```
Question: What conditions for new seedlings?
Request: GET /climate/vpd?temp=20&humidity=75

Response:
{
  "vpd_kpa": 0.58,
  "growth_stage_optimal": "Seedling / Early Vegetative",
  "recommendations": [
    "VPD is good for seedlings and early propagation",
    "Maintain current conditions or adjust gradually if transitioning"
  ]
}
```

### Example 2: Vegetative Growth
```
Question: Optimizing for strong vegetative growth
Request: GET /climate/vpd?temp=25&humidity=55

Response:
{
  "vpd_kpa": 1.27,
  "growth_stage_optimal": "Vegetative Growth",
  "recommendations": [
    "VPD is ideal for vegetative growth",
    "Plants should show strong transpiration",
    "Maintain consistent light and ventilation"
  ]
}
```

### Example 3: Early Flower Transition
```
Question: Transitioning to flowering
Request: GET /climate/vpd?temp=26&humidity=50

Response:
{
  "vpd_kpa": 1.35,
  "growth_stage_optimal": "Early Flowering",
  "recommendations": [
    "VPD is optimal for flowering",
    "Focus on maintaining stable temperature and humidity"
  ]
}
```

### Example 4: Problem Diagnosis
```
Question: Plants wilting, what's wrong?
Request: GET /climate/vpd?temp=32&humidity=30

Response:
{
  "vpd_kpa": 3.95,
  "warning": "Very high VPD - plants may be experiencing severe leaf transpiration stress",
  "recommendations": [
    "⚠️  VPD is very high - plants may be stressed",
    "Increase humidity by reducing temperature or adding moisture",
    "Improve air circulation to prevent localized dry pockets",
    "Monitor for calcium and magnesium deficiencies",
    "Temperature is high - improve ventilation and cooling"
  ]
}
```

---

## Expert Tips

### Monitor Over Time
- Check VPD multiple times daily
- Record with timestamps to identify patterns
- Adjust climate controls proactively

### Seasonal Changes
- Summer: May need to lower temps or increase humidity
- Winter: May need to increase temps or lower humidity
- Spring/Fall: Transition periods require gradual adjustments

### Co2 + VPD Interaction
- Higher CO2 levels allow higher VPD tolerance
- With standard ambient CO2: keep VPD 1.0-1.3 kPa
- With enriched CO2 (1500 ppm): can tolerate VPD up to 1.5 kPa

### Disease Prevention
- **VPD < 0.4:** High risk of mold, mildew (fungal)
- **VPD > 1.8:** High risk of spider mites, thrips (pests)
- **Optimal 0.8-1.3:** Lowest disease pressure

---

## API Status & Future Endpoints

**Currently Available:**
- ✅ GET /climate/vpd (full implementation)

**Planned:**
- 🔄 GET /climate/recommendation - Stage-specific guidance
- 🔄 GET /climate/history - Historical climate tracking
- 🔄 POST /climate/alert - Set VPD threshold alerts
- 🔄 GET /climate/optimal - Suggest temp/humidity combinations

---

## Technical Details

### Tetens Formula
The VPD calculation uses the Tetens approximation, which is accurate within ±1% for temperatures between -30°C and 50°C.

```
es(T) = 0.6108 × exp((17.27 × T) / (T + 237.3))

Where:
- es = saturation vapor pressure (kPa)
- T = temperature (°C)
```

### Calculation Order
1. Calculate saturation vapor pressure (es) using Tetens formula
2. Clamp relative humidity to 0-100%
3. Calculate actual vapor pressure: ea = RH% / 100 × es
4. Calculate VPD: VPD = es - ea

### Units
- **Temperature:** Celsius (°C)
- **Humidity:** Percentage (%)
- **Pressure:** Kilopascals (kPa)
- **1 kPa = 10.2 mmH2O = 0.0987 atm**

---

## Troubleshooting

| Problem | Likely Cause | Solution |
|---------|--------------|----------|
| VPD too high (>2.0) | Too dry/hot | Lower temp, add humidity, reduce airflow |
| VPD too low (<0.3) | Too humid/cold | Raise temp, dehumidify, increase airflow |
| VPD stuck at one value | Sensor error | Recalibrate thermometer/hygrometer |
| Plants wilting despite adequate water | High VPD stress | Follow stress recommendations above |
| Mold/mildew appearing | Low VPD | Increase air circulation, lower humidity |

---

## API Limits

| Setting | Limit |
|---------|-------|
| Temperature Range | -50°C to +50°C |
| Humidity Range | 0% to 100% |
| Max Requests | Unlimited (currently) |
| Response Time | < 50ms |
| Precision | 3 decimal places (kPa) |

---

## Examples by Language

### Python
```python
import requests

def get_vpd(temp: float, humidity: float) -> dict:
    """Get VPD and recommendations"""
    response = requests.get(
        "http://localhost:8000/climate/vpd",
        params={"temp": temp, "humidity": humidity}
    )
    return response.json()

# Usage
data = get_vpd(25, 60)
print(f"Current VPD: {data['vpd_kpa']} kPa")
print(f"Stage: {data['growth_stage_optimal']}")
if data['warning']:
    print(f"⚠️  {data['warning']}")
```

### JavaScript
```javascript
async function getVPD(temp, humidity) {
  const params = new URLSearchParams({ temp, humidity });
  const response = await fetch(`/climate/vpd?${params}`);
  return response.json();
}

// Usage
const data = await getVPD(25, 60);
console.log(`VPD: ${data.vpd_kpa} kPa`);
console.log(`Recommendations:`, data.recommendations);
```

### cURL
```bash
# Basic query
curl "http://localhost:8000/climate/vpd?temp=25&humidity=60"

# Pretty JSON output (with jq)
curl -s "http://localhost:8000/climate/vpd?temp=25&humidity=60" | jq '.'

# Store in variable
VPD_DATA=$(curl -s "http://localhost:8000/climate/vpd?temp=25&humidity=60")
echo $VPD_DATA | jq '.vpd_kpa'
```

---

## References

- **Tetens Formula:** Alduchov, O. A., and R. E. Eskridge, 1996: Improved Magnus Form Approximation of Saturation Vapor Pressure
- **Cannabis VPD Research:** Cannabis research shows optimal VPD for flowering around 1.2-1.5 kPa
- **Plant Physiology:** VPD affects stomatal conductance and photosynthetic rates

---

**Questions?** Check the [main API documentation](API_DOCUMENTATION.md) or audit the [VPD utility source code](app/utils/vpd.py).
