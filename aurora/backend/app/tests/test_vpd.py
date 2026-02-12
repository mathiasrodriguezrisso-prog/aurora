import math
import pytest
from app.utils.vpd import saturation_vapor_pressure_kpa, actual_vapor_pressure_kpa, vpd_kpa


def test_saturation_vapor_pressure_known_value():
    # Known value: at 25°C, es ≈ 3.167 kPa (using Tetens)
    es = saturation_vapor_pressure_kpa(25.0)
    assert es == pytest.approx(3.167, rel=1e-3)


def test_vpd_at_25c_50rh():
    # At 25°C and 50% RH, VPD ≈ 1.5835 kPa
    vpd = vpd_kpa(25.0, 50.0)
    assert vpd == pytest.approx(1.5835, rel=1e-3)


def test_actual_vapor_pressure_bounds():
    # RH bounds should be clamped between 0 and 100
    ea_neg = actual_vapor_pressure_kpa(20.0, -10.0)
    ea_high = actual_vapor_pressure_kpa(20.0, 200.0)
    es = saturation_vapor_pressure_kpa(20.0)
    assert ea_neg == pytest.approx(0.0, abs=1e-6)
    assert ea_high == pytest.approx(es, rel=1e-6)
