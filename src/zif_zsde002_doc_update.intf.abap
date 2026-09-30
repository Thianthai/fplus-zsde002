"! แก้ field ของ sales document หลังสร้างเสร็จ
"! ใช้กับ field ที่ RAP BO ของ sales document ไม่เปิดให้ส่งตอน create
INTERFACE zif_zsde002_doc_update
  PUBLIC .

  TYPES:
    "! item ที่ต้องแก้ 1 ตัว
    BEGIN OF ty_item_update,
      sales_order_item TYPE ztsd_e002_item-sales_order_item,
      tax_class        TYPE ztsd_e002_item-mat_tax_class,
    END OF ty_item_update,

    "! item ที่ต้องแก้ของเอกสาร 1 ใบ
    tt_item_update TYPE STANDARD TABLE OF ty_item_update WITH EMPTY KEY.

  TYPES:
    "! item ที่แก้ไม่สำเร็จ พร้อมเหตุผล
    BEGIN OF ty_item_failure,
      sales_order_item TYPE ztsd_e002_item-sales_order_item,
      message          TYPE string,
    END OF ty_item_failure,

    "! item ที่แก้ไม่สำเร็จของเอกสาร 1 ใบ
    tt_item_failure TYPE STANDARD TABLE OF ty_item_failure WITH EMPTY KEY.

  TYPES:
    "! ค่าระดับ header ที่ต้องแก้หลังสร้างเอกสาร
    BEGIN OF ty_header_update,
      shipping_condition TYPE ztsd_e002_order-shipping_conditions,
    END OF ty_header_update.

  "! แก้ item ของเอกสารทีละตัว
  "! @parameter iv_document | เลขเอกสารที่เพิ่งสร้าง
  "! @parameter it_item     | item ที่ต้องแก้
  "! @parameter rt_failure  | item ที่แก้ไม่สำเร็จ ถ้าว่างแปลว่าสำเร็จทุก item
  METHODS update_items
    IMPORTING iv_document       TYPE ztsd_e002_order-sales_order_number
              it_item           TYPE tt_item_update
    RETURNING VALUE(rt_failure) TYPE tt_item_failure.

  "! แก้ค่าระดับ header ของเอกสาร
  "! @parameter iv_document | เลขเอกสารที่เพิ่งสร้าง
  "! @parameter is_header   | ค่าที่ต้องแก้
  "! @parameter rv_message  | เหตุผลที่แก้ไม่สำเร็จ ถ้าว่างแปลว่าสำเร็จหรือไม่มีอะไรต้องแก้
  METHODS update_header
    IMPORTING iv_document       TYPE ztsd_e002_order-sales_order_number
              is_header         TYPE ty_header_update
    RETURNING VALUE(rv_message) TYPE string.

ENDINTERFACE.
