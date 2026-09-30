"! แก้ field ของ customer return หลังสร้างเสร็จ
"! item ผ่าน API_CUSTOMER_RETURN_SRV (V2)
"! header ผ่าน api_customerreturn (V4) เพราะ RAP BO และ API V2 ไม่มี shipping condition
CLASS zcl_zsde002_ret_update DEFINITION
  PUBLIC
  INHERITING FROM zcl_zsde002_doc_update_base
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    " แก้ shipping condition ผ่าน API V4
    METHODS zif_zsde002_doc_update~update_header REDEFINITION.

  PROTECTED SECTION.

    " ชี้ไปที่ A_CustomerReturnItem
    METHODS get_target REDEFINITION.

  PRIVATE SECTION.

    "! outbound service ของ API V4 ใช้แก้ค่าระดับ header
    CONSTANTS gc_service_header TYPE if_com_management=>ty_cscn_outb_srv_id VALUE 'ZSDE002_RET_V4_UPDATE_OUT_REST'.

ENDCLASS.



CLASS zcl_zsde002_ret_update IMPLEMENTATION.


  METHOD get_target.

    rs_result = VALUE #( service      = 'ZSDE002_RET_UPDATE_OUT_REST'
                         entity_set   = `A_CustomerReturnItem`
                         document_key = `CustomerReturn`
                         item_key     = `CustomerReturnItem` ).

  ENDMETHOD.


  METHOD zif_zsde002_doc_update~update_header.

    " ไม่ได้ส่ง shipping condition มา
    " ปล่อยค่าที่ระบบเติมจาก config ไว้
    IF is_header-shipping_condition IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_document) = shift_left( val = CONV string( iv_document ) sub = '0' ).

    rv_message = patch_entity( iv_service = gc_service_header
                               iv_uri     = |/CustomerReturn('{ lv_document }')|
                               iv_body    = |\{"ShippingCondition":"{ is_header-shipping_condition }"\}| ).

  ENDMETHOD.

ENDCLASS.
