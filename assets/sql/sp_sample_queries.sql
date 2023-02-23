-- Copyright 2023 Google LLC
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

/*
Use Cases:
    - BigQuery supports full SQL syntax and many analytic functions that make complex queries of lots of data easy

Description:
    - Show joins, date functions, rank, partition, pivot

Reference:
    - Rank/Partition: https://cloud.google.com/bigquery/docs/reference/standard-sql/analytic-function-concepts
    - Pivot: https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#pivot_operator

Clean up / Reset script:
    n/a
*/

--Rank, Pivot, Json

-- Query: Get number of orders by category, name, id
SELECT
  oi.product_id AS product_id,
  p.name AS product_name,
  p.category AS product_category,
  COUNT(*) AS num_of_orders
FROM
  `solutions-2023-testing-c.gcp_lakehouse_ds.gcp_tbl_products` AS p
JOIN
  `solutions-2023-testing-c.gcp_lakehouse_ds.gcp_tbl_order_items` AS oi
ON
  p.id = oi.product_id
GROUP BY
  1,
  2,
  3
ORDER BY
  num_of_orders DESC