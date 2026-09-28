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
    "! คู่ item ใน log กับเลข item ที่ SAP ออกให้หลัง commit
    "! payload ส่งเลข item มาไม่ตรงกับที่ SAP ออก จึงต้องจับคู่ด้วย item_uuid
    BEGIN OF ty_item_result,
      item_uuid        TYPE ztsd_e002_item-item_uuid,
      sales_order_item TYPE ztsd_e002_item-sales_order_item,
    END OF ty_item_result,
    tt_item_result TYPE STANDARD TABLE OF ty_item_result WITH EMPTY KEY.

  TYPES:
    "! sales_order_number = เลขเอกสาร SD ที่สร้างได้
    "! items = เลข item ของ SAP ต่อ item ใน log มีค่าเฉพาะเมื่อสร้างเอกสารสำเร็จ
    BEGIN OF ty_result,
      sales_order_number TYPE ty_order-sales_order_number,
      items              TYPE tt_item_result,
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
