"! แก้ field ของ debit memo request หลังสร้างเสร็จผ่าน API_DEBIT_MEMO_REQUEST_SRV
CLASS zcl_zsde002_dmr_update DEFINITION
  PUBLIC
  INHERITING FROM zcl_zsde002_doc_update_base
  FINAL
  CREATE PUBLIC .

  PROTECTED SECTION.

    " ชี้ไปที่ A_DebitMemoRequestItem
    METHODS get_target REDEFINITION.

ENDCLASS.



CLASS zcl_zsde002_dmr_update IMPLEMENTATION.

  METHOD get_target.

    rs_result = VALUE #( service      = 'ZSDE002_DMR_UPDATE_OUT_REST'
                         entity_set   = `A_DebitMemoRequestItem`
                         document_key = `DebitMemoRequest`
                         item_key     = `DebitMemoRequestItem` ).

  ENDMETHOD.

ENDCLASS.
