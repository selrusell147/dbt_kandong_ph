{{
    config(
        materialized='incremental',
        unique_key='transaction_id',
        schema='stg_transaction_list'
    )
}}

WITH transaction_list AS (
  SELECT
    transaction_created_at,
    SAFE.FORMAT_TIMESTAMP('%F %T', transaction_created_at, 'Asia/Manila') AS transaction_created_at_sgt,
    transaction_updated_at,
    SAFE.FORMAT_TIMESTAMP('%F %T', transaction_updated_at, 'Asia/Manila') AS transaction_updated_at_sgt,
    transaction_id,
    driver_id,
    customer_id,
    transaction_status,
    transaction_fare
  FROM (
    SELECT 
      *,
      ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_updated_at DESC) AS tr_row
    FROM `kandong-ph.transaction_dataset.transaction_list_raw`
  )
  WHERE tr_row = 1
),

driver_list AS (
  SELECT
    driver_id,
    driver_name,
    driver_phone_number
  FROM (
    SELECT 
      *,
      ROW_NUMBER() OVER (PARTITION BY driver_id ORDER BY driver_updated_at DESC) AS dr_row 
    FROM `kandong-ph.driver_dataset.driver_list`
  )
  WHERE dr_row = 1
),

customer_list AS (
  SELECT
    customer_id,
    customer_name,
    customer_phone_number
  FROM (
    SELECT 
      *,
      ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY customer_updated_at DESC) AS cs_row 
    FROM `kandong-ph.customer_dataset.customer_list`
  )
  WHERE cs_row = 1
)

SELECT
  tl.transaction_created_at,
  tl.transaction_created_at_sgt,
  tl.transaction_updated_at,
  tl.transaction_updated_at_sgt,
  tl.transaction_id,
  tl.driver_id,
  dl.driver_name,
  dl.driver_phone_number,
  tl.customer_id,
  cl.customer_name,
  cl.customer_phone_number,
  tl.transaction_status transaction_booking_status,
  tl.transaction_fare
FROM transaction_list tl
LEFT JOIN driver_list dl ON tl.driver_id = dl.driver_id
LEFT JOIN customer_list cl ON tl.customer_id = cl.customer_id
