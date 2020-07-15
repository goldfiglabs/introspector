from dataclasses import dataclass
from typing import List

from sqlalchemy.orm import Session


@dataclass
class QueryResult:
  columns: List[str]
  rows: List


def run_query(db: Session, query: str) -> QueryResult:
  results = db.execute(query)
  return QueryResult(columns=results.keys(), rows=results.fetchall())
