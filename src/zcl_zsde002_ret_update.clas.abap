"! แก้ field ของ customer return หลังสร้างเสร็จผ่าน API_CUSTOMER_RETURN_SRV
CLASS zcl_zsde002_ret_update DEFINITION
  PUBLIC
  INHERITING FROM zcl_zsde002_doc_update_base
  FINAL
  CREATE PUBLIC .

  PROTECTED SECTION.

    " ชี้ไปที่ A_CustomerReturnItem
    METHODS get_target REDEFINITION.

ENDCLASS.



CLASS zcl_zsde002_ret_update IMPLEMENTATION.

  METHOD get_target.

    rs_result = VALUE #( service      = 'ZSDE002_RET_UPDATE_OUT_REST'
                         entity_set   = `A_CustomerReturnItem`
                         document_key = `CustomerReturn`
                         item_key     = `CustomerReturnItem` ).

  ENDMETHOD.

ENDCLASS.
