"! แก้ field ของ sales document หลังสร้างเสร็จผ่าน OData API_SALES_ORDER_SRV
"! ใช้กับ field ที่ RAP BO ของ sales document ไม่เปิดให้ส่งตอน create
CLASS zcl_zsde002_so_update DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

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

    "! แก้ tax classification ของ item ทีละตัว
    "! @parameter iv_sales_order | เลขเอกสารที่เพิ่งสร้าง
    "! @parameter it_item        | item ที่ต้องแก้
    "! @parameter rt_failure     | item ที่แก้ไม่สำเร็จ ถ้าว่างแปลว่าสำเร็จทุก item
    METHODS update_tax_class
      IMPORTING iv_sales_order    TYPE ztsd_e002_order-sales_order_number
                it_item           TYPE tt_item_update
      RETURNING VALUE(rt_failure) TYPE tt_item_failure.

  PRIVATE SECTION.

    CONSTANTS:
      "! outbound communication ที่ชี้ไปหา API_SALES_ORDER_SRV ของ tenant เดียวกัน
      BEGIN OF gc_comm,
        scenario TYPE if_com_management=>ty_cscn_id          VALUE 'ZCS_SO_CREATE_OUT',
        service  TYPE if_com_management=>ty_cscn_outb_srv_id VALUE 'ZSDE002_SO_CREATE_OUT_REST',
      END OF gc_comm.

    "! GET เพื่อขอ CSRF token และ ETag แล้ว PATCH item 1 ตัว
    "! @parameter io_destination | destination จาก communication arrangement
    "! @parameter iv_sales_order | เลขเอกสาร
    "! @parameter is_item        | item ที่ต้องแก้
    "! @parameter rv_message     | เหตุผลที่แก้ไม่สำเร็จ ถ้าว่างแปลว่าสำเร็จ
    METHODS update_item
      IMPORTING io_destination    TYPE REF TO if_http_destination
                iv_sales_order    TYPE ztsd_e002_order-sales_order_number
                is_item           TYPE ty_item_update
      RETURNING VALUE(rv_message) TYPE string.

    "! อ่านข้อความ error จาก response ของ OData V2
    "! @parameter io_response | response ที่ status ไม่ตรงกับที่คาด
    "! @parameter rv_result   | ข้อความจาก error.message.value หรือ status code ถ้าอ่านไม่ได้
    METHODS read_error
      IMPORTING io_response      TYPE REF TO if_web_http_response
      RETURNING VALUE(rv_result) TYPE string.

ENDCLASS.



CLASS zcl_zsde002_so_update IMPLEMENTATION.


  METHOD update_tax_class.

    IF it_item IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
                                 comm_scenario = gc_comm-scenario
                                 service_id    = gc_comm-service ).

      CATCH cx_http_dest_provider_error INTO DATA(lx_destination).
        " หา destination ไม่เจอ ทุก item จึงไม่ได้แก้
        rt_failure = VALUE #( FOR ls_item IN it_item
                              ( sales_order_item = ls_item-sales_order_item
                                message          = lx_destination->get_text( ) ) ).
        RETURN.
    ENDTRY.

    LOOP AT it_item ASSIGNING FIELD-SYMBOL(<lfs_item>).

      DATA(lv_message) = update_item( io_destination = lo_destination
                                      iv_sales_order = iv_sales_order
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
    DATA(lv_sales_order) = shift_left( val = CONV string( iv_sales_order )           sub = '0' ).
    DATA(lv_item)        = shift_left( val = CONV string( is_item-sales_order_item ) sub = '0' ).

    DATA(lv_uri) = |/A_SalesOrderItem(SalesOrder='{ lv_sales_order }',SalesOrderItem='{ lv_item }')|.

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
