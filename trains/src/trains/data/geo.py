"""GeoJSON data loading utilities for the train game map."""

import os.path

import geojson_pydantic
from geojson_pydantic import Feature, FeatureCollection, Polygon

_dir = os.path.dirname(os.path.abspath(__file__))

# Load North America data
usdata: FeatureCollection[Feature[Polygon, dict]] = (
    geojson_pydantic.FeatureCollection.model_validate_json(
        open(os.path.join(_dir, "../usa.json")).read()
    )
)

canadata: FeatureCollection[Feature[Polygon, dict]] = (
    geojson_pydantic.FeatureCollection.model_validate_json(
        open(os.path.join(_dir, "../canada.json")).read()
    )
)

mexicodata: FeatureCollection[Feature[Polygon, dict]] = (
    geojson_pydantic.FeatureCollection.model_validate_json(
        open(os.path.join(_dir, "../mexico.json")).read()
    )
)

# Rivers and lakes
rivers_nadata: FeatureCollection[Feature[Polygon, dict]] = (
    geojson_pydantic.FeatureCollection.model_validate_json(
        open(os.path.join(_dir, "../rivers_na.json")).read()
    )
)

rivers_50_nadata: FeatureCollection[Feature[Polygon, dict]] = (
    geojson_pydantic.FeatureCollection.model_validate_json(
        open(os.path.join(_dir, "../rivers_50_na.json")).read()
    )
)

ne_50m_lakesdata: FeatureCollection[Feature[Polygon, dict]] = (
    geojson_pydantic.FeatureCollection.model_validate_json(
        open(os.path.join(_dir, "../ne_50m_lakes.json")).read()
    )
)


def get_all_na_countries() -> FeatureCollection[Feature[Polygon, dict]]:
    """Combine USA, Canada, and Mexico into a single FeatureCollection."""
    features = []
    for fc in [usdata, canadata, mexicodata]:
        features.extend(fc.features)

    return FeatureCollection(type="FeatureCollection", features=features)


def get_all_water_features() -> FeatureCollection[Feature[Polygon, dict]]:
    """Combine rivers and lakes into a single FeatureCollection."""
    features = []
    for fc in [rivers_nadata, rivers_50_nadata, ne_50m_lakesdata]:
        features.extend(fc.features)

    return FeatureCollection(type="FeatureCollection", features=features)
