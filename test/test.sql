SELECT DIGEST_TEXT
  FROM performance_schema.events_statements_summary_by_digest
 WHERE SUM_ERRORS > 0
