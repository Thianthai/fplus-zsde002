"! แก้ field ของ sales order หลังสร้างเสร็จผ่าน API_SALES_ORDER_SRV
CLASS zcl_zsde002_so_update DEFINITION
  PUBLIC
  INHERITING FROM zcl_zsde002_doc_update_base
  FINAL
  CREATE PUBLIC .

  PROTECTED SECTION.

    " ชี้ไปที่ A_SalesOrderItem
    METHODS get_target REDEFINITION.

ENDCLASS.



CLASS zcl_zsde002_so_update IMPLEMENTATION.

  METHOD get_target.

    rs_result = VALUE #( service      = 'ZSDE002_SO_UPDATE_OUT_REST'
                         entity_set   = `A_SalesOrderItem`
                         document_key = `SalesOrder`
                         item_key     = `SalesOrderItem` ).

  ENDMETHOD.

ENDCLASS.
