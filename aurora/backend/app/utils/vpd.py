"""
VPD utilities using Tetens formula.
Functions return values in kPa.
"""
import math


def saturation_vapor_pressure_kpa(temp_c: float) -> float:
    """Calculate saturation vapor pressure (kPa) using Tetens formula.

    es(T) = 0.6108 * exp(17.27 * T / (T + 237.3))
    where T is degrees Celsius and es is in kPa.
    """
    es = 0.6108 * math.exp((17.27 * temp_c) / (temp_c + 237.3))
    return es


def actual_vapor_pressure_kpa(temp_c: float, rh_percent: float) -> float:
    """Calculate actual vapor pressure ea = RH/100 * es(T).

    Args:
        temp_c: temperature in °C
        rh_percent: relative humidity in % (0-100)
    Returns:
        ea in kPa
    """
    es = saturation_vapor_pressure_kpa(temp_c)
    rh = max(0.0, min(100.0, rh_percent))
    ea = es * (rh / 100.0)
    return ea


def vpd_kpa(temp_c: float, rh_percent: float) -> float:
    """Calculate Vapor Pressure Deficit in kPa.

    VPD = es(T) - ea
    """
    es = saturation_vapor_pressure_kpa(temp_c)
    ea = actual_vapor_pressure_kpa(temp_c, rh_percent)
    vpd = es - ea
    return vpd


if __name__ == "__main__":
    # simple demo
    for T in [20.0, 22.0, 25.0, 28.0]:
        for RH in [40.0, 50.0, 60.0]:
            print(f"T={T}C RH={RH}% -> VPD={vpd_kpa(T,RH):.3f} kPa")
