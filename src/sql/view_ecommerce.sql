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
CREATE OR REPLACE VIEW
  gcp_lakehouse_ds.view_ecommerce AS
SELECT
  o.order_id,
  o.user_id order_user_id,
  o.status order_status,
  o.created_at order_created_at,
  o.returned_at order_returned_at,
  o.shipped_at order_shipped_at,
  o.delivered_at order_delivered_at,
  o.num_of_item order_number_of_items,
  i.id AS order_items_id,
  i.product_id AS order_items_product_id,
  i.status order_items_status,
  i.sale_price order_items_sale_price,
  p.id AS product_id,
  p.cost product_cost,
  p.category product_category,
  p.name product_name,
  p.brand product_brand,
  p.retail_price product_retail_price,
  p.department product_department,
  p.sku product_sku,
  p.distribution_center_id,
  d.name AS dist_center_name,
  d.latitude dist_center_lat,
  d.longitude dist_center_long,
  u.id AS user_id,
  u.first_name user_first_name,
  u.last_name user_last_name,
  u.age user_age,
  u.gender user_gender,
  u.state user_state,
  u.postal_code user_postal_code,
  u.city user_city,
  u.country user_country,
  u.latitude user_lat,
  u.longitude user_long,
  u.traffic_source user_traffic_source
FROM
  gcp_primary_staging.thelook_ecommerce_orders o
INNER JOIN
  gcp_primary_staging.thelook_ecommerce_order_items i
ON
  o.order_id = i.order_id
INNER JOIN
  `gcp_primary_staging.thelook_ecommerce_products` p
ON
  i.product_id = p.id
INNER JOIN
  `gcp_primary_staging.thelook_ecommerce_distribution_centers` d
ON
  p.distribution_center_id = d.id
INNER JOIN
  `gcp_primary_staging.thelook_ecommerce_users` u
ON
  o.user_id = u.id
;
