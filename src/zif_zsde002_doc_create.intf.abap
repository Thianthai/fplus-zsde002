INTERFACE zif_zsde002_doc_create
  PUBLIC .

  TYPES:
    ty_order         TYPE ztsd_e002_order,
    tt_order_pricing TYPE STANDARD TABLE OF ztsd_e002_ordprc WITH EMPTY KEY,
    tt_item          TYPE STANDARD TABLE OF ztsd_e002_item   WITH EMPTY KEY,
    tt_item_pricing  TYPE STANDARD TABLE OF ztsd_e002_itmprc WITH EMPTY KEY,
    ty_param         TYPE zcl_zsde002_processor=>ty_param,
    tt_error         TYPE zcl_zsde002_processor=>tt_error.

  TYPES:
    "! sales_order_number = เลขเอกสาร SD ที่สร้างได้
    BEGIN OF ty_result,
      sales_order_number TYPE ty_order-sales_order_number,
      errors             TYPE tt_error,
    END OF ty_result.

  "! สร้างเอกสาร SD 1 ใบ ไม่ว่าจะเป็น Order, Credit memo, Debit memo หรือ Return
  METHODS create
    IMPORTING is_order         TYPE ty_order
              it_order_pricing TYPE tt_order_pricing
              it_item          TYPE tt_item
              it_item_pricing  TYPE tt_item_pricing
              is_param         TYPE ty_param
    RETURNING VALUE(rs_result) TYPE ty_result.

ENDINTERFACE.
