from __future__ import annotations
from kfp.dsl import component, Output, Dataset, Metrics

@component
def data_ingestion(
    project: str,
    dataset: str,
    table: str,
    pii_forbidden_columns: list,
    output_dataset: Output[Dataset],
) -> None:
    pass
