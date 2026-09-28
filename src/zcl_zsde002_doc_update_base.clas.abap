"! แก้ field ของ sales document ผ่าน OData API ของประเภทเอกสารนั้น
"! logic การเรียก API อยู่ที่นี่ทั้งหมด
"! class ลูกบอกแค่ว่าเรียก service ไหนและ key ของ item ชื่ออะไร
CLASS zcl_zsde002_doc_update_base DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_zsde002_doc_update.

    ALIASES update_items FOR zif_zsde002_doc_update~update_items.

  PROTECTED SECTION.

    TYPES:
      "! ปลายทางของ API สำหรับประเภทเอกสารหนึ่ง
      BEGIN OF ty_target,
        service      TYPE if_com_management=>ty_cscn_outb_srv_id,
        entity_set   TYPE string,
        document_key TYPE string,
        item_key     TYPE string,
      END OF ty_target.

    "! outbound service, entity และชื่อ key ของ item ของประเภทเอกสารนี้
    "! @parameter rs_result | ปลายทางของ API
    METHODS get_target ABSTRACT
      RETURNING VALUE(rs_result) TYPE ty_target.

  PRIVATE SECTION.

    "! outbound communication ที่ชี้ไปหา API ของ tenant เดียวกัน
    CONSTANTS gc_scenario TYPE if_com_management=>ty_cscn_id VALUE 'ZCS_SO_UPDATE_OUT'.

    "! GET เพื่อขอ CSRF token และ ETag แล้ว PATCH item 1 ตัว
    "! @parameter io_destination | destination จาก communication arrangement
    "! @parameter is_target      | ปลายทางของ API
    "! @parameter iv_document    | เลขเอกสาร
    "! @parameter is_item        | item ที่ต้องแก้
    "! @parameter rv_message     | เหตุผลที่แก้ไม่สำเร็จ ถ้าว่างแปลว่าสำเร็จ
    METHODS update_item
      IMPORTING io_destination    TYPE REF TO if_http_destination
                is_target         TYPE ty_target
                iv_document       TYPE ztsd_e002_order-sales_order_number
                is_item           TYPE zif_zsde002_doc_update=>ty_item_update
      RETURNING VALUE(rv_message) TYPE string.

    "! อ่านข้อความ error จาก response ของ OData V2
    "! @parameter io_response | response ที่ status ไม่ตรงกับที่คาด
    "! @parameter rv_result   | ข้อความจาก error.message.value หรือ status code ถ้าอ่านไม่ได้
    METHODS read_error
      IMPORTING io_response      TYPE REF TO if_web_http_response
      RETURNING VALUE(rv_result) TYPE string.

ENDCLASS.



CLASS zcl_zsde002_doc_update_base IMPLEMENTATION.

  METHOD zif_zsde002_doc_update~update_items.

    IF it_item IS INITIAL.
      RETURN.
    ENDIF.

    DATA(ls_target) = get_target( ).

    TRY.
        DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
                                 comm_scenario = gc_scenario
                                 service_id    = ls_target-service ).

      CATCH cx_http_dest_provider_error INTO DATA(lx_destination).
        " หา destination ไม่เจอ ทุก item จึงไม่ได้แก้
        rt_failure = VALUE #( FOR ls_item IN it_item
                              ( sales_order_item = ls_item-sales_order_item
                                message          = lx_destination->get_text( ) ) ).
        RETURN.
    ENDTRY.

    LOOP AT it_item ASSIGNING FIELD-SYMBOL(<lfs_item>).

      DATA(lv_message) = update_item( io_destination = lo_destination
                                      is_target      = ls_target
                                      iv_document    = iv_document
                                      is_item        = <lfs_item> ).

      IF lv_message IS NOT INITIAL.
        APPEND VALUE #( sales_order_item = <lfs_item>-sales_order_item
                        message          = lv_message ) TO rt_failure.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD update_item.

    " สร้าง client ใหม่ทุก item เพื่อไม่ให้ header ของ item ก่อนหน้าติดมา
    " ถ้า If-Match ของ item ก่อนหน้าค้างอยู่ GET ของ item ถัดไปจะได้ 412
    DATA lo_client TYPE REF TO if_web_http_client.

    " key ใน URL ใช้เลขแบบไม่มีศูนย์นำหน้าและไม่มีช่องว่างท้าย
    " ALPHA = OUT คงความยาวของ field ไว้ ช่องว่างที่เหลือทำให้ request line ใช้ไม่ได้
    " CONV string ตัดช่องว่างท้ายของ field แบบ char ออกก่อน แล้ว shift_left ตัดศูนย์นำหน้า
    DATA(lv_document) = shift_left( val = CONV string( iv_document ) sub = '0' ).
    DATA(lv_item)     = shift_left( val = CONV string( is_item-sales_order_item ) sub = '0' ).

    DATA(lv_uri) = |/{ is_target-entity_set }|
                && |({ is_target-document_key }='{ lv_document }',{ is_target-item_key }='{ lv_item }')|.

    TRY.
        lo_client = cl_web_http_client_manager=>create_by_http_destination( io_destination ).

        DATA(lo_request) = lo_client->get_http_request( ).

        lo_request->set_uri_path( lv_uri ).

        lo_request->set_header_field( i_name  = 'Accept'
                                      i_value = 'application/json' ).

        " GET ก่อนเพื่อขอ CSRF token และ ETag ของ item ตัวนี้
        lo_request->set_header_field( i_name  = 'x-csrf-token'
                                      i_value = 'Fetch' ).

        DATA(lo_response) = lo_client->execute( if_web_http_client=>get ).

        IF lo_response->get_status( )-code <> 200.
          rv_message = read_error( lo_response ).
        ELSE.

          DATA(lv_token) = lo_response->get_header_field( 'x-csrf-token' ).

          DATA(lv_etag)  = lo_response->get_header_field( 'etag' ).

          " PATCH ส่งเฉพาะ field ที่แก้
          " field อื่นของ item คงค่าเดิม
          lo_request->set_header_field( i_name  = 'x-csrf-token'
                                        i_value = lv_token ).

          lo_request->set_header_field( i_name  = 'If-Match'
                                        i_value = COND #( WHEN lv_etag IS INITIAL THEN `*` ELSE lv_etag ) ).

          lo_request->set_header_field( i_name  = 'Content-Type'
                                        i_value = 'application/json' ).

          lo_request->set_text( |\{"ProductTaxClassification1":"{ is_item-tax_class }"\}| ).

          lo_response = lo_client->execute( if_web_http_client=>patch ).

          IF lo_response->get_status( )-code <> 204.
            rv_message = read_error( lo_response ).
          ENDIF.

        ENDIF.

      CATCH cx_web_http_client_error cx_web_message_error INTO DATA(lx_error).
        rv_message = lx_error->get_text( ).
    ENDTRY.

    IF lo_client IS BOUND.
      TRY.
          lo_client->close( ).
        CATCH cx_web_http_client_error ##NO_HANDLER.
          " ปิดไม่ได้ไม่กระทบผลของ item ที่แก้ไปแล้ว
      ENDTRY.
    ENDIF.

  ENDMETHOD.


  METHOD read_error.

    DATA lv_body TYPE string.
    DATA lv_text TYPE string.

    DATA(ls_status) = io_response->get_status( ).

    TRY.
        lv_body = io_response->get_text( ).
      CATCH cx_web_message_error.
        " ไม่มี body ให้อ่าน ใช้ status code อย่างเดียว
        CLEAR lv_body.
    ENDTRY.

    " OData V2 เก็บข้อความไว้ที่ error.message.value
    FIND FIRST OCCURRENCE OF PCRE `"value"\s*:\s*"([^"]*)"` IN lv_body SUBMATCHES lv_text.

    rv_result = COND #( WHEN lv_text IS NOT INITIAL THEN lv_text
                        ELSE |HTTP { ls_status-code } { ls_status-reason }| ).

  ENDMETHOD.

ENDCLASS.
