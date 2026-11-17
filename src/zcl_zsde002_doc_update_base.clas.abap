"! แก้ field ของ sales document ผ่าน OData API ของประเภทเอกสารนั้น
"! logic การเรียก API อยู่ที่นี่ทั้งหมด
"! class ลูกบอกแค่ว่าเรียก service ไหนและ key ของ item ชื่ออะไร
"! ประเภทที่ต้องแก้ค่าระดับ header ด้วยให้ redefine update_header
CLASS zcl_zsde002_doc_update_base DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_zsde002_doc_update.

    ALIASES update_items  FOR zif_zsde002_doc_update~update_items.
    ALIASES update_header FOR zif_zsde002_doc_update~update_header.

  PROTECTED SECTION.

    TYPES:
      "! ปลายทางของ API สำหรับ item ของประเภทเอกสารหนึ่ง
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

    "! GET เพื่อขอ CSRF token และ ETag แล้ว PATCH entity 1 ตัว
    "! ถ้าเอกสารยังบันทึกไม่เสร็จหรือยังถูก lock จะรอแล้วลองใหม่ตาม gc_max_attempt
    "! ใช้ได้ทั้ง OData V2 และ V4
    "! @parameter iv_service | outbound service ใน scenario ZCS_SO_UPDATE_OUT
    "! @parameter iv_uri     | path ของ entity ต่อจาก path prefix ของ service
    "! @parameter iv_body    | JSON ที่มีเฉพาะ field ที่แก้
    "! @parameter rv_message | เหตุผลที่แก้ไม่สำเร็จ ถ้าว่างแปลว่าสำเร็จ
    METHODS patch_entity
      IMPORTING iv_service        TYPE if_com_management=>ty_cscn_outb_srv_id
                iv_uri            TYPE string
                iv_body           TYPE string
      RETURNING VALUE(rv_message) TYPE string.

  PRIVATE SECTION.

    "! outbound communication ที่ชี้ไปหา API ของ tenant เดียวกัน
    CONSTANTS gc_scenario TYPE if_com_management=>ty_cscn_id VALUE 'ZCS_SO_UPDATE_OUT'.

    "! จำนวนครั้งสูงสุดที่ลอง GET + PATCH ต่อ entity
    CONSTANTS gc_max_attempt  TYPE i VALUE 5.

    "! วินาทีที่รอก่อนลองครั้งถัดไป
    CONSTANTS gc_wait_seconds TYPE i VALUE 1.

    "! อ่านข้อความ error จาก response ของ OData
    "! @parameter io_response | response ที่ status ไม่ตรงกับที่คาด
    "! @parameter rv_result   | ข้อความจาก error ของ OData หรือ status code ถ้าอ่านไม่ได้
    METHODS read_error
      IMPORTING io_response      TYPE REF TO if_web_http_response
      RETURNING VALUE(rv_result) TYPE string.

    "! GET เพื่อขอ CSRF token และ ETag แล้ว PATCH entity 1 ตัว 1 รอบ
    "! @parameter iv_service | outbound service ใน scenario ZCS_SO_UPDATE_OUT
    "! @parameter iv_uri     | path ของ entity ต่อจาก path prefix ของ service
    "! @parameter iv_body    | JSON ที่มีเฉพาะ field ที่แก้
    "! @parameter ev_message | เหตุผลที่แก้ไม่สำเร็จ ถ้าว่างแปลว่าสำเร็จ
    "! @parameter ev_retry   | X เมื่อควรลองใหม่ เพราะเอกสารยังบันทึกไม่เสร็จหรือยังถูก lock
    METHODS try_patch
      IMPORTING iv_service TYPE if_com_management=>ty_cscn_outb_srv_id
                iv_uri     TYPE string
                iv_body    TYPE string
      EXPORTING ev_message TYPE string
                ev_retry   TYPE abap_bool.

    "! เช็คว่า error เกิดจากเอกสารถูก lock อยู่หรือไม่
    "! @parameter io_response | response ที่ status ไม่ตรงกับที่คาด
    "! @parameter rv_result   | X เมื่อเป็น message V1/042
    METHODS is_lock_error
      IMPORTING io_response      TYPE REF TO if_web_http_response
      RETURNING VALUE(rv_result) TYPE abap_bool.

ENDCLASS.



CLASS ZCL_ZSDE002_DOC_UPDATE_BASE IMPLEMENTATION.


  METHOD zif_zsde002_doc_update~update_items.

    DATA(ls_target) = get_target( ).

    " key ใน URL ใช้เลขแบบไม่มีศูนย์นำหน้าและไม่มีช่องว่างท้าย
    " ALPHA = OUT คงความยาวของ field ไว้ ช่องว่างที่เหลือทำให้ request line ใช้ไม่ได้
    " CONV string ตัดช่องว่างท้ายของ field แบบ char ออกก่อน แล้ว shift_left ตัดศูนย์นำหน้า
    DATA(lv_document) = shift_left( val = CONV string( iv_document ) sub = '0' ).

    LOOP AT it_item ASSIGNING FIELD-SYMBOL(<lfs_item>).

      DATA(lv_item) = shift_left( val = CONV string( <lfs_item>-sales_order_item ) sub = '0' ).

      DATA(lv_message) = patch_entity(
                           iv_service = ls_target-service
                           iv_uri     = |/{ ls_target-entity_set }|
                                     && |({ ls_target-document_key }='{ lv_document }',{ ls_target-item_key }='{ lv_item }')|
                           iv_body    = |\{"ProductTaxClassification1":"{ <lfs_item>-tax_class }"\}| ).

      IF lv_message IS NOT INITIAL.
        APPEND VALUE #( sales_order_item = <lfs_item>-sales_order_item
                        message          = lv_message ) TO rt_failure.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_doc_update~update_header.

    " ประเภทเอกสารส่วนใหญ่ไม่มีค่าระดับ header ที่ต้องแก้หลังสร้าง
    " class ลูกที่ต้องแก้ให้ redefine method นี้
    RETURN.

  ENDMETHOD.


  METHOD patch_entity.

    DATA lv_retry TYPE abap_bool.

    " เอกสารเพิ่งสร้างด้วย COMMIT ENTITIES ซึ่งบันทึกใน update task แบบ async
    " ถ้ายิงเร็วเกินไป GET จะยังไม่เจอเอกสาร หรือ PATCH จะชน lock ที่ update task ยังถืออยู่
    " จึงรอแล้วลองใหม่ ถ้าครบจำนวนครั้งแล้วยังไม่ผ่าน คืนข้อความจากรอบสุดท้าย
    DO gc_max_attempt TIMES.

      IF sy-index > 1.
        WAIT UP TO gc_wait_seconds SECONDS.
      ENDIF.

      try_patch( EXPORTING iv_service = iv_service
                           iv_uri     = iv_uri
                           iv_body    = iv_body
                 IMPORTING ev_message = rv_message
                           ev_retry   = lv_retry ).

      IF lv_retry = abap_false.
        RETURN.
      ENDIF.

    ENDDO.

  ENDMETHOD.


  METHOD try_patch.

    " สร้าง client ใหม่ทุกครั้งเพื่อไม่ให้ header ของ entity ก่อนหน้าติดมา
    " ถ้า If-Match ของ entity ก่อนหน้าค้างอยู่ GET ของ entity ถัดไปจะได้ 412
    DATA lo_client TYPE REF TO if_web_http_client.

    CLEAR: ev_message, ev_retry.

    TRY.
        DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
                                 comm_scenario = gc_scenario
                                 service_id    = iv_service ).

        lo_client = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).

        DATA(lo_request) = lo_client->get_http_request( ).
        lo_request->set_uri_path( iv_uri ).
        lo_request->set_header_field( i_name  = 'Accept'
                                      i_value = 'application/json' ).

        " GET ก่อนเพื่อขอ CSRF token และ ETag ของ entity ตัวนี้
        " ETag เป็นระดับเอกสาร แก้ entity ไหนก็เปลี่ยนทั้งใบ จึงต้องขอใหม่ทุกครั้ง
        lo_request->set_header_field( i_name  = 'x-csrf-token'
                                      i_value = 'Fetch' ).

        DATA(lo_response) = lo_client->execute( if_web_http_client=>get ).

        IF lo_response->get_status( )-code <> 200.
          ev_message = read_error( lo_response ).
          " 404 แปลว่า update task ยังเขียนเอกสารลง DB ไม่เสร็จ
          ev_retry   = xsdbool( lo_response->get_status( )-code = 404 ).
        ELSE.

          DATA(lv_token) = lo_response->get_header_field( 'x-csrf-token' ).
          DATA(lv_etag)  = lo_response->get_header_field( 'etag' ).

          " PATCH ส่งเฉพาะ field ที่แก้
          " field อื่นของ entity คงค่าเดิม
          lo_request->set_header_field( i_name  = 'x-csrf-token'
                                        i_value = lv_token ).
          lo_request->set_header_field( i_name  = 'If-Match'
                                        i_value = COND #( WHEN lv_etag IS INITIAL THEN `*` ELSE lv_etag ) ).
          lo_request->set_header_field( i_name  = 'Content-Type'
                                        i_value = 'application/json' ).
          lo_request->set_text( iv_body ).

          lo_response = lo_client->execute( if_web_http_client=>patch ).

          " V2 ตอบ 204 ไม่มี body
          " V4 ตอบ 200 พร้อม entity ที่แก้แล้ว
          IF  lo_response->get_status( )-code <> 200
          AND lo_response->get_status( )-code <> 204.
            ev_message = read_error( lo_response ).
            ev_retry   = is_lock_error( lo_response ).
          ENDIF.

        ENDIF.

      CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error INTO DATA(lx_error).
        ev_message = lx_error->get_text( ).
    ENDTRY.

    IF lo_client IS BOUND.
      TRY.
          lo_client->close( ).
        CATCH cx_web_http_client_error ##NO_HANDLER.
          " ปิดไม่ได้ไม่กระทบผลของ entity ที่แก้ไปแล้ว
      ENDTRY.
    ENDIF.

  ENDMETHOD.


  METHOD read_error.

    DATA lv_body       TYPE string.
    DATA lv_message_v4 TYPE string.
    DATA lv_message_v2 TYPE string.

    DATA(ls_status) = io_response->get_status( ).

    TRY.
        lv_body = io_response->get_text( ).
      CATCH cx_web_message_error.
        " ไม่มี body ให้อ่าน ใช้ status code อย่างเดียว
        CLEAR lv_body.
    ENDTRY.

    " V4 เก็บข้อความไว้ที่ error.message เป็นข้อความตรง ๆ
    " V2 เก็บไว้ที่ error.message.value
    FIND FIRST OCCURRENCE OF PCRE `"message"\s*:\s*"([^"]*)"|"value"\s*:\s*"([^"]*)"`
         IN lv_body SUBMATCHES lv_message_v4 lv_message_v2.

    rv_result = COND #( WHEN lv_message_v4 IS NOT INITIAL THEN lv_message_v4
                        WHEN lv_message_v2 IS NOT INITIAL THEN lv_message_v2
                        ELSE |HTTP { ls_status-code } { ls_status-reason }| ).

  ENDMETHOD.


  METHOD is_lock_error.

    DATA lv_body TYPE string.

    TRY.
        lv_body = io_response->get_text( ).
      CATCH cx_web_message_error.
        RETURN.
    ENDTRY.

    " error.code ของ Gateway เป็น /IWBEP/CM_MGW_RT/022 ซึ่งใช้กับ business error ทุกชนิด
    " message จริงอยู่ใน longtext_url เช็คจากตรงนั้นแทน
    " V1/042 คือเอกสาร SD ถูก lock อยู่ ไม่ขึ้นกับภาษาของ user
    rv_result = xsdbool( lv_body CS `MSGID='V1',MSGNO='042'` ).

  ENDMETHOD.

ENDCLASS.
