CREATE OR REPLACE PROCEDURE
  gcp_lakehouse_ds.create_view_ecommerce()
BEGIN
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
  gcp_lakehouse_ds.gcp_tbl_orders o
INNER JOIN
  gcp_lakehouse_ds.gcp_tbl_order_items i
ON
  o.order_id = i.order_id
INNER JOIN
  `gcp_lakehouse_ds.gcp_tbl_products` p
ON
  i.product_id = p.id
INNER JOIN
  `gcp_lakehouse_ds.gcp_tbl_distribution_centers` d
ON
  p.distribution_center_id = d.id
INNER JOIN
  `gcp_lakehouse_ds.gcp_tbl_users` u
ON
  o.user_id = u.id
;
END 