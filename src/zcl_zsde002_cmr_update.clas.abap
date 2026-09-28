"! แก้ field ของ credit memo request หลังสร้างเสร็จผ่าน API_CREDIT_MEMO_REQUEST_SRV
CLASS zcl_zsde002_cmr_update DEFINITION
  PUBLIC
  INHERITING FROM zcl_zsde002_doc_update_base
  FINAL
  CREATE PUBLIC .

  PROTECTED SECTION.

    " ชี้ไปที่ A_CreditMemoRequestItem
    METHODS get_target REDEFINITION.

ENDCLASS.



CLASS zcl_zsde002_cmr_update IMPLEMENTATION.

  METHOD get_target.

    rs_result = VALUE #( service      = 'ZSDE002_CMR_UPDATE_OUT_REST'
                         entity_set   = `A_CreditMemoRequestItem`
                         document_key = `CreditMemoRequest`
                         item_key     = `CreditMemoRequestItem` ).

  ENDMETHOD.

ENDCLASS.
