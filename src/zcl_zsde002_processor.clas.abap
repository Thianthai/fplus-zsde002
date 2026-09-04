CLASS zcl_zsde002_processor DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      ty_request       TYPE zcl_zsde002_http=>ty_request,
      ty_request_order TYPE zcl_zsde002_http=>ty_request-orders,

      ty_order         TYPE ztsd_e002_order,
      ty_order_pricing TYPE ztsd_e002_ordprc,
      tt_order_pricing TYPE STANDARD TABLE OF ztsd_e002_ordprc WITH EMPTY KEY,

      ty_item          TYPE ztsd_e002_item,
      tt_item          TYPE STANDARD TABLE OF ztsd_e002_item WITH EMPTY KEY,
      ty_item_pricing  TYPE ztsd_e002_itmprc,
      tt_item_pricing  TYPE STANDARD TABLE OF ztsd_e002_itmprc WITH EMPTY KEY,

      ty_order_message TYPE ztsd_e002_ordmsg,
      tt_order_message TYPE STANDARD TABLE OF ztsd_e002_ordmsg WITH EMPTY KEY.

    TYPES:
      ty_response TYPE zcl_zsde002_http=>ty_response.

    TYPES:
      BEGIN OF ty_error,
        msgno            TYPE symsgno,
        msgty            TYPE symsgty,
        msgtx            TYPE string,
        sf_header_id_ref TYPE ty_order-sf_header_id_ref,
        sf_item_id_ref   TYPE ty_item-sf_item_id_ref,
        field            TYPE string,
      END OF ty_error,
      tt_error TYPE STANDARD TABLE OF ty_error WITH EMPTY KEY,

      "! 1 แถว = 1 message — order ที่สำเร็จได้ 1 แถว, order ที่พังได้ 1 แถวต่อ 1 error
      BEGIN OF ty_order_out,
        status             TYPE symsgty,
        code               TYPE string,
        message            TYPE string,
        sales_order_number TYPE ty_order-sales_order_number,
        document_type      TYPE ty_order-sales_order_type,
        customer_reference TYPE ty_order-customer_reference,
        sf_header_id_ref   TYPE ty_order-sf_header_id_ref,
        sf_item_id_ref     TYPE ty_item-sf_item_id_ref,
        processing_date    TYPE string,
        processing_time    TYPE string,
        field              TYPE string,
      END OF ty_order_out,
      tt_order_out TYPE STANDARD TABLE OF ty_order_out WITH EMPTY KEY,

      BEGIN OF ty_result,
        request_id TYPE ty_response-request_id,
        status     TYPE symsgty,
        passed     TYPE i,
        failed     TYPE i,
        orders     TYPE tt_order_out,
      END OF ty_result,

      BEGIN OF ty_param,
        t_process_type          TYPE zif_zsde002_master_data=>tt_process_type,
        lr_processtype_stockvan TYPE RANGE OF ty_order-process_type,
        lr_processtype_sfid     TYPE RANGE OF ty_order-process_type,
        lr_processtype_edi      TYPE RANGE OF ty_order-process_type,
        lr_processtype_online   TYPE RANGE OF ty_order-process_type,
        lr_processtype_zt01     TYPE RANGE OF ty_order-process_type,
        lr_processtype_zt02     TYPE RANGE OF ty_order-process_type,
        lr_processtype_zt09     TYPE RANGE OF ty_order-process_type,
        lr_processtype_sloc     TYPE RANGE OF ty_order-process_type,
        lr_processtype_batch    TYPE RANGE OF ty_order-process_type,
        lr_trantype_reason      TYPE RANGE OF ty_order-tran_type,
        lr_order_reason         TYPE RANGE OF I_SalesDocument-SDDocumentReason,
      END OF ty_param,

      "! ผลการเช็ค master data ของทั้ง request — เก็บเฉพาะ key ที่ "ไม่เจอ"
      BEGIN OF ty_unknown,
        sales_area          TYPE zif_zsde002_master_data=>tt_sales_area,
        cust_sales_area     TYPE zif_zsde002_master_data=>tt_cust_sales_area,
        sales_document_type TYPE zif_zsde002_master_data=>tt_sales_document_type,
        payment_terms       TYPE zif_zsde002_master_data=>tt_payment_terms,
        currency            TYPE zif_zsde002_master_data=>tt_currency,
        product             TYPE zif_zsde002_master_data=>tt_product,
        plant               TYPE zif_zsde002_master_data=>tt_plant,
        storage_location    TYPE zif_zsde002_master_data=>tt_storage_location,
        product_unit        TYPE zif_zsde002_master_data=>tt_product_unit,
        condition_type      TYPE zif_zsde002_master_data=>tt_condition_type,
      END OF ty_unknown.

    METHODS constructor
      IMPORTING io_master_data TYPE REF TO zif_zsde002_master_data OPTIONAL
                io_param       TYPE REF TO zcl_param               OPTIONAL.

    METHODS process
      IMPORTING iv_body          TYPE string
      RETURNING VALUE(rs_result) TYPE ty_result.

    CLASS-METHODS message_text
      IMPORTING iv_msgno         TYPE symsgno
                iv_msgty         TYPE symsgty DEFAULT 'E'
                iv_v1            TYPE string OPTIONAL
                iv_v2            TYPE string OPTIONAL
                iv_v3            TYPE string OPTIONAL
                iv_v4            TYPE string OPTIONAL
      RETURNING VALUE(rv_result) TYPE string.

  PRIVATE SECTION.

    DATA go_master_data TYPE REF TO zif_zsde002_master_data.
    DATA go_param       TYPE REF TO zcl_param.
    DATA gs_param       TYPE ty_param.
    DATA gs_unknown     TYPE ty_unknown.

    METHODS get_constant_param
      IMPORTING io_param  TYPE REF TO zcl_param
      CHANGING  cs_param  TYPE ty_param
                cs_result TYPE ty_result.

    METHODS normalize_order
      IMPORTING iv_request_id TYPE ztsd_e002_order-request_id
      CHANGING  cs_order      TYPE ty_order
                ct_pricing    TYPE tt_order_pricing
                ct_error      TYPE tt_error.

    METHODS normalize_item
      IMPORTING is_order   TYPE ty_order
      CHANGING  cs_item    TYPE ty_item
                ct_pricing TYPE tt_item_pricing
                ct_error   TYPE tt_error.

    METHODS validate_order
      IMPORTING is_order        TYPE ty_order
                it_pricing      TYPE tt_order_pricing
      RETURNING VALUE(rt_error) TYPE tt_error.

    METHODS validate_item
      IMPORTING is_order        TYPE ty_order
                is_item         TYPE ty_item
                it_pricing      TYPE tt_item_pricing
      RETURNING VALUE(rt_error) TYPE tt_error.

    "! รวบ key ของทั้ง request แล้วถาม master data ครั้งเดียวต่อประเภท
    METHODS prefetch_master_data
      IMPORTING it_order TYPE zcl_zsde002_http=>tt_order_in.

    METHODS check_order_master_data
      IMPORTING is_order        TYPE ty_order
                it_pricing      TYPE tt_order_pricing
      RETURNING VALUE(rt_error) TYPE tt_error.

    METHODS check_item_master_data
      IMPORTING is_order        TYPE ty_order
                is_item         TYPE ty_item
                it_pricing      TYPE tt_item_pricing
      RETURNING VALUE(rt_error) TYPE tt_error.

    "! คืน SfHeaderIdRef ที่ซ้ำกันภายใน request เดียว
    METHODS find_duplicate_header
      IMPORTING it_order         TYPE zcl_zsde002_http=>tt_order_in
      RETURNING VALUE(rt_result) TYPE string_table.

    METHODS save
      IMPORTING is_order         TYPE ty_order
                it_order_pricing TYPE tt_order_pricing
                it_item          TYPE tt_item
                it_item_pricing  TYPE tt_item_pricing
                it_order_message TYPE tt_order_message
      RETURNING VALUE(rv_result) TYPE abap_bool.

    METHODS post
      IMPORTING it_order_pricing TYPE tt_order_pricing
                it_item          TYPE tt_item
                it_item_pricing  TYPE tt_item_pricing
      CHANGING  cs_order         TYPE ty_order
                ct_error         TYPE tt_error.

    "! ประกอบแถว message ของ order 1 ใบ
    METHODS to_order_out
      IMPORTING is_order         TYPE ty_order
                it_error         TYPE tt_error
      RETURNING VALUE(rt_result) TYPE tt_order_out.

    "! message ระดับ request — ไม่มี order context
    METHODS add_request_message
      IMPORTING iv_msgno  TYPE symsgno
                iv_msgty  TYPE symsgty DEFAULT 'E'
                iv_v1     TYPE string OPTIONAL
                iv_v2     TYPE string OPTIONAL
                iv_v3     TYPE string OPTIONAL
      CHANGING  cs_result TYPE ty_result.

    "! เก็บ JSON ของ order ใบนี้ตามที่ SBPA ส่งมา ก่อนถูก normalize
    METHODS to_request_body
      IMPORTING is_order         TYPE zcl_zsde002_http=>ty_order_in
      RETURNING VALUE(rv_result) TYPE ztsd_e002_order-request_body.

    "! แปลง error ของ order เป็นแถวใน ZTSD_E002_ORDMSG
    METHODS to_order_message
      IMPORTING is_order         TYPE ty_order
                it_error         TYPE tt_error
      RETURNING VALUE(rt_result) TYPE tt_order_message.

    METHODS new_uuid
      RETURNING VALUE(rv_result) TYPE sysuuid_x16.

    "! แปลง finding ของ validator เป็น error ที่พร้อมส่งกลับ (ชื่อ field เป็น JSON แล้ว)
    METHODS to_errors
      IMPORTING it_finding          TYPE zcl_zsde002_validator=>tt_finding
                iv_sf_header_id_ref TYPE ty_order-sf_header_id_ref OPTIONAL
                iv_sf_item_id_ref   TYPE ty_item-sf_item_id_ref    OPTIONAL
      RETURNING VALUE(rt_error)     TYPE tt_error.

ENDCLASS.



CLASS zcl_zsde002_processor IMPLEMENTATION.

 METHOD constructor.

    go_master_data = COND #( WHEN io_master_data IS BOUND THEN io_master_data
                             ELSE NEW zcl_zsde002_master_data( ) ).

    DATA(lo_param) = zcl_param=>create_instance( iv_company_code = '' iv_module_id = 'SD' ).
    go_param = COND #( WHEN io_param IS BOUND THEN io_param
                       ELSE lo_param ).

  ENDMETHOD.


  METHOD process.

    DATA ls_request        TYPE ty_request.
    DATA ls_order          TYPE ty_order.
    DATA lt_order_pricings TYPE tt_order_pricing.
    DATA ls_item           TYPE ty_item.
    DATA lt_item           TYPE tt_item.
    DATA lt_item_pricing   TYPE tt_item_pricing.
    DATA lt_item_pricings  TYPE tt_item_pricing.
    DATA lt_error          TYPE tt_error.

    " 1. Constant Parameter --------------------------------------------
    get_constant_param( EXPORTING io_param  = go_param
                        CHANGING  cs_param  = gs_param
                                  cs_result = rs_result ).

    IF rs_result-orders IS NOT INITIAL.
      RETURN.
    ENDIF.

    " 2. Payload -------------------------------------------------------
    IF iv_body IS INITIAL.
      add_request_message( EXPORTING iv_msgno = '010' CHANGING cs_result = rs_result ).
      RETURN.
    ENDIF.

    IF NOT matches( val = iv_body pcre = '^\s*\{' ).
      add_request_message( EXPORTING iv_msgno = '011' CHANGING cs_result = rs_result ).
      RETURN.
    ENDIF.

    " 3. Parse ---------------------------------------------------------
    TRY.
        zcl_zsde002_json=>parse_json_request( EXPORTING iv_body    = iv_body
                                              IMPORTING es_request = ls_request ).
      CATCH zcx_zsde002_error INTO DATA(lcx_error).
        add_request_message( EXPORTING iv_msgno = '012'
                                       iv_v1    = lcx_error->get_text( )
                             CHANGING  cs_result = rs_result ).
        RETURN.
    ENDTRY.

    IF ls_request-orders IS INITIAL.
      add_request_message( EXPORTING iv_msgno = '013' CHANGING cs_result = rs_result ).
      RETURN.
    ENDIF.

    " 4. Request ID ----------------------------------------------------
    IF ls_request-request_id IS INITIAL.
      ls_request-request_id = |{ cl_abap_context_info=>get_system_date( ) }_| &&
                              |{ cl_abap_context_info=>get_system_time( ) }|.
    ENDIF.

    IF strlen( ls_request-request_id ) > 20.
      add_request_message( EXPORTING iv_msgno = '014'
                                     iv_msgty = 'W'
                                     iv_v1    = ls_request-request_id
                                     iv_v2    = `20`
                           CHANGING  cs_result = rs_result ).
    ENDIF.

    rs_result-request_id = ls_request-request_id.

    " 5. Prefetch Master Data ------------------------------------------
    prefetch_master_data( ls_request-orders ).

    DATA(lt_duplicate_header) = find_duplicate_header( ls_request-orders ).

    " 6. Process -------------------------------------------------------
    LOOP AT ls_request-orders ASSIGNING FIELD-SYMBOL(<lfs_order>).

      CLEAR: ls_order,
             lt_order_pricings[],
             ls_item,
             lt_item[],
             lt_item_pricing[],
             lt_item_pricings[],
             lt_error[].

      " 6.1 Normalize --------------------------------------------------
      ls_order          = CORRESPONDING #( <lfs_order> ).
      lt_order_pricings = CORRESPONDING #( <lfs_order>-pricings ).

      " เก็บ JSON ดิบของ order ใบนี้ ต้องอยู่หลัง CORRESPONDING เพราะมันทับทั้ง structure
      ls_order-request_body = to_request_body( <lfs_order> ).

      normalize_order( EXPORTING iv_request_id = CONV #( ls_request-request_id )
                       CHANGING  cs_order      = ls_order
                                 ct_pricing    = lt_order_pricings
                                 ct_error      = lt_error ).

      LOOP AT <lfs_order>-items ASSIGNING FIELD-SYMBOL(<lfs_item>).
        CLEAR: ls_item, lt_item_pricing[].
        ls_item         = CORRESPONDING #( <lfs_item> ).
        lt_item_pricing = CORRESPONDING #( <lfs_item>-pricings ).

        normalize_item( EXPORTING is_order   = ls_order
                        CHANGING  cs_item    = ls_item
                                  ct_pricing = lt_item_pricing
                                  ct_error   = lt_error ).

        APPEND ls_item TO lt_item.
        APPEND LINES OF lt_item_pricing TO lt_item_pricings.
      ENDLOOP.

      " normalize ล้ม = ไม่มี UUID = เขียน log ไม่ได้ ข้าม order นี้ไปเลย
      IF lt_error IS NOT INITIAL.
        rs_result-failed = rs_result-failed + 1.
        APPEND LINES OF to_order_out( is_order = ls_order
                                      it_error = lt_error ) TO rs_result-orders.
        CONTINUE.
      ENDIF.

      " 6.2 Check Duplicate Header -------------------------------------
      " Duplicate SfHeaderIdRef ภายใน request เดียวกัน
      IF  ls_order-sf_header_id_ref IS NOT INITIAL
      AND line_exists( lt_duplicate_header[ table_line = |{ ls_order-sf_header_id_ref }| ] ).
        APPEND VALUE #( msgno            = '015'
                        msgty            = 'E'
                        msgtx            = message_text( iv_msgno = '015'
                                                         iv_v1    = |{ ls_order-sf_header_id_ref }| )
                        sf_header_id_ref = ls_order-sf_header_id_ref
                        field            = zcl_zsde002_json=>to_json_name( 'sf_header_id_ref' )
                      ) TO lt_error.
      ENDIF.

      " 6.3 Check Empty Item -------------------------------------------
      " Order ที่ไม่มี item เลย
      IF lt_item IS INITIAL.
        APPEND VALUE #( msgno            = '016'
                        msgty            = 'E'
                        msgtx            = message_text( iv_msgno = '016'
                                                         iv_v1    = |{ ls_order-sf_header_id_ref }| )
                        sf_header_id_ref = ls_order-sf_header_id_ref
                        field            = `Items`
                      ) TO lt_error.
      ENDIF.

      " 6.4 Validate ---------------------------------------------------
      lt_error = VALUE #( BASE lt_error
                          FOR ls_order_error IN validate_order( is_order   = ls_order
                                                                it_pricing = lt_order_pricings )
                        ( CORRESPONDING #( ls_order_error ) ) ).

      LOOP AT <lfs_order>-items ASSIGNING <lfs_item>.
        CLEAR: ls_item, lt_item_pricing[].
        ls_item         = CORRESPONDING #( <lfs_item> ).
        lt_item_pricing = CORRESPONDING #( <lfs_item>-pricings ).

        lt_error = VALUE #( BASE lt_error
                            FOR ls_item_error IN validate_item( is_order   = ls_order
                                                                is_item    = ls_item
                                                                it_pricing = lt_item_pricing )
                          ( CORRESPONDING #( ls_item_error ) ) ).
      ENDLOOP.

      " 6.5 Post -------------------------------------------------------
      IF NOT line_exists( lt_error[ msgty = 'E' ] ).
        post( EXPORTING it_order_pricing = lt_order_pricings
                        it_item          = lt_item
                        it_item_pricing  = lt_item_pricings
              CHANGING  cs_order         = ls_order
                        ct_error         = lt_error ).
      ENDIF.

      " 6.6 Status -----------------------------------------------------
      ls_order-order_status = COND #( WHEN NOT line_exists( lt_error[ msgty = 'E' ] ) THEN 'S'
                                      WHEN ls_order-sales_order_number IS NOT INITIAL   THEN 'W'
                                      ELSE 'E' ).

      " 6.7 Save -------------------------------------------------------
      " เขียน log เสมอ แม้ order จะไม่ผ่าน validation — ใบที่พังคือใบที่ต้องดูมากที่สุด
      IF save( is_order         = ls_order
               it_order_pricing = lt_order_pricings
               it_item          = lt_item
               it_item_pricing  = lt_item_pricings
               it_order_message = to_order_message( is_order = ls_order
                                                    it_error = lt_error ) ) = abap_false.

        APPEND VALUE #( msgno            = '400'
                        msgty            = 'E'
                        msgtx            = message_text( iv_msgno = '400'
                                                         iv_v1    = |{ ls_order-sf_header_id_ref }| )
                        sf_header_id_ref = ls_order-sf_header_id_ref
                      ) TO lt_error.
      ENDIF.

      " 6.8 Result -----------------------------------------------------
      IF NOT line_exists( lt_error[ msgty = 'E' ] ).
        rs_result-passed = rs_result-passed + 1.
      ELSE.
        rs_result-failed = rs_result-failed + 1.
      ENDIF.

      APPEND LINES OF to_order_out( is_order = ls_order
                                    it_error = lt_error ) TO rs_result-orders.

    ENDLOOP.

    " 7. Request Status ------------------------------------------------
    rs_result-status = COND #( WHEN rs_result-passed = 0 THEN 'E'
                               WHEN rs_result-failed = 0 THEN 'S'
                               ELSE 'W' ).

  ENDMETHOD.


  METHOD get_constant_param.

    TRY.
        io_param->get_range( EXPORTING iv_app_id     = 'SDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'CASH_VAN_SALES'
                             IMPORTING et_range      = cs_param-lr_processtype_stockvan ).

        io_param->get_range( EXPORTING iv_app_id     = 'SDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'SFID'
                             IMPORTING et_range      = cs_param-lr_processtype_sfid ).

        io_param->get_range( EXPORTING iv_app_id     = 'SDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'EDI'
                             IMPORTING et_range      = cs_param-lr_processtype_edi ).

        io_param->get_range( EXPORTING iv_app_id     = 'SDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'ONLINE'
                             IMPORTING et_range      = cs_param-lr_processtype_online ).

        io_param->get_range( EXPORTING iv_app_id     = 'SDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'ZT01'
                             IMPORTING et_range      = cs_param-lr_processtype_zt01 ).

        io_param->get_range( EXPORTING iv_app_id     = 'SDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'ZT02'
                             IMPORTING et_range      = cs_param-lr_processtype_zt02 ).

        io_param->get_range( EXPORTING iv_app_id     = 'SDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'ZT09'
                             IMPORTING et_range      = cs_param-lr_processtype_zt09 ).

        io_param->get_range( EXPORTING iv_app_id     = 'SDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'SLOC'
                             IMPORTING et_range      = cs_param-lr_processtype_sloc ).

        io_param->get_range( EXPORTING iv_app_id     = 'SDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'BATCH'
                             IMPORTING et_range      = cs_param-lr_processtype_batch ).

        io_param->get_range( EXPORTING iv_app_id     = 'SDE002'
                                       iv_param_name = 'TRAN_TYPE'
                                       iv_param_ext  = 'REASON'
                             IMPORTING et_range      = cs_param-lr_trantype_reason ).

        io_param->get_range( EXPORTING iv_app_id     = 'SDE002'
                                       iv_param_name = 'ORDER_REASON'
                                       iv_param_ext  = 'ZT04'
                             IMPORTING et_range      = cs_param-lr_order_reason ).

      CATCH zcx_param INTO DATA(lcx_param).
        add_request_message( EXPORTING iv_msgno = '403'
                                       iv_v1    = `SDE002`
                                       iv_v2    = |{ lcx_param->gv_reason }|
                                       iv_v3    = lcx_param->get_text( )
                             CHANGING  cs_result = cs_result ).
    ENDTRY.

    " master list ของ process type ย้ายมาอยู่ที่ mapping table แล้ว ไม่ได้อยู่ใน param config
    cs_param-t_process_type = go_master_data->read_process_type( ).

    IF cs_param-t_process_type IS INITIAL.
      add_request_message( EXPORTING iv_msgno = '403'
                                     iv_v1    = `PROCESS_TYPE`
                                     iv_v2    = `ZTSD_E002_PRCTYP`
                                     iv_v3    = `mapping table is empty`
                           CHANGING  cs_result = cs_result ).
    ENDIF.

  ENDMETHOD.


  METHOD normalize_order.

    " 1. Order ---------------------------------------------------------
    " Administrative Data — ต้องมาก่อน UUID เพราะถ้า UUID ล้มแล้ว RETURN
    " to_order_out ยังต้องใช้ created_at ทำ processing date/time
    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).
    GET TIME STAMP FIELD DATA(lv_now).

    cs_order-created_by            = lv_user.
    cs_order-created_at            = lv_now.
    cs_order-last_changed_by       = lv_user.
    cs_order-last_changed_at       = lv_now.
    cs_order-local_last_changed_at = lv_now.

    " Order UUID
    TRY.
        cs_order-order_uuid = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error INTO DATA(lo_uuid_error).
        APPEND VALUE #( msgno            = '402'
                        msgty            = 'E'
                        msgtx            = message_text( iv_msgno = '402'
                                                         iv_v1    = lo_uuid_error->get_text( ) )
                        sf_header_id_ref = cs_order-sf_header_id_ref
                      ) TO ct_error.
        RETURN.
    ENDTRY.

    " Request ID
    cs_order-request_id = iv_request_id.

    " Customer
    cs_order-sold_to_party = zcl_zsde002_validator=>to_internal_customer( cs_order-sold_to_party ).
    cs_order-ship_to_party = zcl_zsde002_validator=>to_internal_customer( cs_order-ship_to_party ).
    cs_order-bill_to_party = zcl_zsde002_validator=>to_internal_customer( cs_order-bill_to_party ).
    cs_order-payer         = zcl_zsde002_validator=>to_internal_customer( cs_order-payer ).
    cs_order-stock_van     = zcl_zsde002_validator=>to_internal_customer( cs_order-stock_van ).

    " Administrative Data
    cs_order-created_by            = lv_user.
    cs_order-created_at            = lv_now.
    cs_order-last_changed_by       = lv_user.
    cs_order-last_changed_at       = lv_now.
    cs_order-local_last_changed_at = lv_now.

    " 2. Order Pricing -------------------------------------------------
    LOOP AT ct_pricing ASSIGNING FIELD-SYMBOL(<lfs_pricing>).

      " Order Pricing UUID
      TRY.
          <lfs_pricing>-order_pricing_uuid = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error INTO lo_uuid_error.
          APPEND VALUE #( msgno            = '402'
                          msgty            = 'E'
                          msgtx            = message_text( iv_msgno = '402'
                                                           iv_v1    = lo_uuid_error->get_text( ) )
                          sf_header_id_ref = cs_order-sf_header_id_ref
                        ) TO ct_error.
          RETURN.
      ENDTRY.

      " Order UUID
      <lfs_pricing>-order_uuid = cs_order-order_uuid.

      " Administrative Data
      <lfs_pricing>-created_by            = cs_order-created_by.
      <lfs_pricing>-created_at            = cs_order-created_at.
      <lfs_pricing>-last_changed_by       = cs_order-last_changed_by.
      <lfs_pricing>-last_changed_at       = cs_order-last_changed_at.
      <lfs_pricing>-local_last_changed_at = cs_order-local_last_changed_at.

    ENDLOOP.

  ENDMETHOD.


  METHOD normalize_item.

    " 1. Item ----------------------------------------------------------
    " Item UUID
    TRY.
        cs_item-item_uuid = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error INTO DATA(lo_uuid_error).
        APPEND VALUE #( msgno            = '402'
                        msgty            = 'E'
                        msgtx            = message_text( iv_msgno = '402'
                                                         iv_v1    = lo_uuid_error->get_text( ) )
                        sf_header_id_ref = is_order-sf_header_id_ref
                      ) TO ct_error.
        RETURN.
    ENDTRY.

    " Order UUID
    cs_item-order_uuid = is_order-order_uuid.

    " Administrative Data
    cs_item-created_by            = is_order-created_by.
    cs_item-created_at            = is_order-created_at.
    cs_item-last_changed_by       = is_order-last_changed_by.
    cs_item-last_changed_at       = is_order-last_changed_at.
    cs_item-local_last_changed_at = is_order-local_last_changed_at.

    " 2. Item Pricing --------------------------------------------------
    LOOP AT ct_pricing ASSIGNING FIELD-SYMBOL(<lfs_pricing>).

      " Item Pricing UUID
      TRY.
          <lfs_pricing>-item_pricing_uuid = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error INTO lo_uuid_error.
          APPEND VALUE #( msgno            = '402'
                          msgty            = 'E'
                          msgtx            = message_text( iv_msgno = '402'
                                                           iv_v1    = lo_uuid_error->get_text( ) )
                          sf_header_id_ref = is_order-sf_header_id_ref
                        ) TO ct_error.
          RETURN.
      ENDTRY.

      " Order UUID
      <lfs_pricing>-item_uuid  = cs_item-item_uuid.
      <lfs_pricing>-order_uuid = cs_item-order_uuid.

      " Administrative Data
      <lfs_pricing>-created_by            = cs_item-created_by.
      <lfs_pricing>-created_at            = cs_item-created_at.
      <lfs_pricing>-last_changed_by       = cs_item-last_changed_by.
      <lfs_pricing>-last_changed_at       = cs_item-last_changed_at.
      <lfs_pricing>-local_last_changed_at = cs_item-local_last_changed_at.

    ENDLOOP.

  ENDMETHOD.


  METHOD validate_order.

    " 1. Validate Mandatory --------------------------------------------
    APPEND LINES OF to_errors( it_finding          = zcl_zsde002_validator=>check_order_mandatory(
                                                       EXPORTING is_order = is_order
                                                                 is_param = gs_param )
                               iv_sf_header_id_ref = is_order-sf_header_id_ref
                             ) TO rt_error.

    " 2. Validate Format -----------------------------------------------
    APPEND LINES OF to_errors( it_finding          = zcl_zsde002_validator=>check_order_format(
                                                       EXPORTING is_order   = is_order
                                                                 it_pricing = it_pricing )
                               iv_sf_header_id_ref = is_order-sf_header_id_ref
                             ) TO rt_error.

    " 3. Validate Process Type -----------------------------------------
    " process type ต้องมีใน mapping table และ tran type / doc type / sales area
    " ต้องตรงกับแถวนั้นด้วย ไม่งั้นถือว่า SBPA ส่งชุดข้อมูลที่ระบบไม่รู้จัก
    IF is_order-process_type IS NOT INITIAL.

      DATA(lv_invalid) = abap_false.

      READ TABLE gs_param-t_process_type INTO DATA(ls_process_type)
           WITH TABLE KEY process_type = is_order-process_type.

      IF sy-subrc <> 0.
        lv_invalid = abap_true.

      ELSEIF ls_process_type-tran_type            <> is_order-tran_type
          OR ls_process_type-sales_order_type     <> is_order-sales_order_type
          OR ls_process_type-sales_organization   <> is_order-sales_organization
          OR ls_process_type-distribution_channel <> is_order-distribution_channel
          OR ls_process_type-division             <> is_order-division.
        lv_invalid = abap_true.

      ENDIF.

      IF lv_invalid = abap_true.
        APPEND VALUE #( msgno            = '303'
                        msgty            = 'E'
                        msgtx            = message_text( iv_msgno = '303'
                                                         iv_v1    = |{ is_order-process_type }| )
                        sf_header_id_ref = is_order-sf_header_id_ref
                        field            = zcl_zsde002_json=>to_json_name( 'process_type' )
                      ) TO rt_error.
      ENDIF.

    ENDIF.

    " 4. Validate Master Data ------------------------------------------
    APPEND LINES OF check_order_master_data( is_order   = is_order
                                             it_pricing = it_pricing
                                           ) TO rt_error.

  ENDMETHOD.


  METHOD validate_item.

    " 1. Validate Mandatory --------------------------------------------
    APPEND LINES OF to_errors( it_finding          = zcl_zsde002_validator=>check_item_mandatory(
                                                       EXPORTING is_order = is_order
                                                                 is_item  = is_item
                                                                 is_param = gs_param )
                               iv_sf_header_id_ref = is_order-sf_header_id_ref
                               iv_sf_item_id_ref   = is_item-sf_item_id_ref
                             ) TO rt_error.

    APPEND LINES OF to_errors( it_finding          = zcl_zsde002_validator=>check_item_format(
                                                       EXPORTING is_item    = is_item
                                                                 it_pricing = it_pricing )
                               iv_sf_header_id_ref = is_order-sf_header_id_ref
                               iv_sf_item_id_ref   = is_item-sf_item_id_ref
                             ) TO rt_error.

    " 2. Validate Master Data ------------------------------------------
    APPEND LINES OF check_item_master_data( is_order   = is_order
                                            is_item    = is_item
                                            it_pricing = it_pricing
                                          ) TO rt_error.

  ENDMETHOD.


  METHOD prefetch_master_data.

    DATA lt_sales_area          TYPE zif_zsde002_master_data=>tt_sales_area.
    DATA lt_cust_sales_area     TYPE zif_zsde002_master_data=>tt_cust_sales_area.
    DATA lt_sales_document_type TYPE zif_zsde002_master_data=>tt_sales_document_type.
    DATA lt_payment_terms       TYPE zif_zsde002_master_data=>tt_payment_terms.
    DATA lt_currency            TYPE zif_zsde002_master_data=>tt_currency.
    DATA lt_product             TYPE zif_zsde002_master_data=>tt_product.
    DATA lt_plant               TYPE zif_zsde002_master_data=>tt_plant.
    DATA lt_storage_location    TYPE zif_zsde002_master_data=>tt_storage_location.
    DATA lt_product_unit        TYPE zif_zsde002_master_data=>tt_product_unit.
    DATA lt_condition_type      TYPE zif_zsde002_master_data=>tt_condition_type.

    DATA lv_sales_doc_type      TYPE zif_zsde002_master_data=>ty_sales_document_type.
    DATA lv_payment_terms       TYPE zif_zsde002_master_data=>ty_payment_terms.
    DATA lv_currency            TYPE zif_zsde002_master_data=>ty_currency.
    DATA lv_plant               TYPE zif_zsde002_master_data=>ty_plant.
    DATA lv_condition_type      TYPE zif_zsde002_master_data=>ty_condition_type.
    DATA lv_material            TYPE zif_zsde002_master_data=>ty_product.

    CLEAR gs_unknown.

    LOOP AT it_order ASSIGNING FIELD-SYMBOL(<lfs_order>).

      " Sales Area + Customer Sales Area
      IF  <lfs_order>-sales_organization   IS NOT INITIAL
      AND <lfs_order>-distribution_channel IS NOT INITIAL
      AND <lfs_order>-division             IS NOT INITIAL.

        INSERT VALUE #( sales_organization   = <lfs_order>-sales_organization
                        distribution_channel = <lfs_order>-distribution_channel
                        division             = <lfs_order>-division
                      ) INTO TABLE lt_sales_area.

        LOOP AT VALUE string_table( ( <lfs_order>-sold_to_party )
                                    ( <lfs_order>-ship_to_party )
                                    ( <lfs_order>-bill_to_party )
                                    ( <lfs_order>-payer )
                                    ( <lfs_order>-stock_van ) )
             ASSIGNING FIELD-SYMBOL(<lfs_partner>).

          CHECK <lfs_partner> IS NOT INITIAL.

          INSERT VALUE #( sales_organization   = <lfs_order>-sales_organization
                          distribution_channel = <lfs_order>-distribution_channel
                          division             = <lfs_order>-division
                          customer             = zcl_zsde002_validator=>to_internal_customer( <lfs_partner> )
                        ) INTO TABLE lt_cust_sales_area.
        ENDLOOP.

      ENDIF.

      " Sales Document Type
      IF <lfs_order>-sales_order_type IS NOT INITIAL.
        lv_sales_doc_type = <lfs_order>-sales_order_type.
        INSERT lv_sales_doc_type INTO TABLE lt_sales_document_type.
      ENDIF.

      " Payment Terms
      IF <lfs_order>-payment_term IS NOT INITIAL.
        lv_payment_terms = <lfs_order>-payment_term.
        INSERT lv_payment_terms INTO TABLE lt_payment_terms.
      ENDIF.

      " Currency
      IF <lfs_order>-currency IS NOT INITIAL.
        lv_currency = <lfs_order>-currency.
        INSERT lv_currency INTO TABLE lt_currency.
      ENDIF.

      " Order Condition Type
      LOOP AT <lfs_order>-pricings ASSIGNING FIELD-SYMBOL(<lfs_order_pricing>).
        IF <lfs_order_pricing>-condition_type IS NOT INITIAL.
          lv_condition_type = <lfs_order_pricing>-condition_type.
          INSERT lv_condition_type INTO TABLE lt_condition_type.
        ENDIF.
      ENDLOOP.

      " Item
      LOOP AT <lfs_order>-items ASSIGNING FIELD-SYMBOL(<lfs_item>).

        CLEAR lv_material.

        IF <lfs_item>-material_number IS NOT INITIAL.
          lv_material = zcl_zsde002_validator=>to_internal_material( <lfs_item>-material_number ).
          INSERT lv_material INTO TABLE lt_product.
        ENDIF.

        IF  <lfs_item>-plant            IS NOT INITIAL
        AND <lfs_item>-storage_location IS NOT INITIAL.
          INSERT VALUE #( plant            = <lfs_item>-plant
                          storage_location = <lfs_item>-storage_location
                        ) INTO TABLE lt_storage_location.
        ENDIF.

        IF  lv_material           IS NOT INITIAL
        AND <lfs_item>-sales_unit IS NOT INITIAL.
          INSERT VALUE #( product          = lv_material
                          alternative_unit = <lfs_item>-sales_unit
                        ) INTO TABLE lt_product_unit.
        ENDIF.

        LOOP AT <lfs_item>-pricings ASSIGNING FIELD-SYMBOL(<lfs_item_pricing>).
          IF <lfs_item_pricing>-condition_type IS NOT INITIAL.
            lv_condition_type = <lfs_item_pricing>-condition_type.
            INSERT lv_condition_type INTO TABLE lt_condition_type.
          ENDIF.
        ENDLOOP.

      ENDLOOP.

    ENDLOOP.

    " 10 SELECT ต่อ 1 request
    gs_unknown-sales_area          = go_master_data->find_unknown_sales_area( lt_sales_area ).
    gs_unknown-cust_sales_area     = go_master_data->find_unknown_cust_sales_area( lt_cust_sales_area ).
    gs_unknown-sales_document_type = go_master_data->find_unknown_sales_doc_type( lt_sales_document_type ).
    gs_unknown-payment_terms       = go_master_data->find_unknown_payment_terms( lt_payment_terms ).
    gs_unknown-currency            = go_master_data->find_unknown_currency( lt_currency ).
    gs_unknown-product             = go_master_data->find_unknown_product( lt_product ).
    gs_unknown-plant               = go_master_data->find_unknown_plant( lt_plant ).
    gs_unknown-storage_location    = go_master_data->find_unknown_storage_location( lt_storage_location ).
    gs_unknown-product_unit        = go_master_data->find_unknown_product_unit( lt_product_unit ).
    gs_unknown-condition_type      = go_master_data->find_unknown_condition_type( lt_condition_type ).

  ENDMETHOD.


  METHOD check_order_master_data.

    " master data ถูก prefetch ไว้ใน gs_unknown แล้ว ตรงนี้เทียบในหน่วยความจำล้วน
    TYPES: BEGIN OF ty_partner,
             customer TYPE zif_zsde002_master_data=>ty_cust_sales_area-customer,
             value    TYPE string,
             field    TYPE string,
           END OF ty_partner.

    DATA lt_partner        TYPE STANDARD TABLE OF ty_partner WITH EMPTY KEY.
    DATA lv_sales_doc_type TYPE zif_zsde002_master_data=>ty_sales_document_type.
    DATA lv_payment_terms  TYPE zif_zsde002_master_data=>ty_payment_terms.
    DATA lv_currency       TYPE zif_zsde002_master_data=>ty_currency.
    DATA lv_condition_type TYPE zif_zsde002_master_data=>ty_condition_type.

    IF  is_order-sales_organization   IS NOT INITIAL
    AND is_order-distribution_channel IS NOT INITIAL
    AND is_order-division             IS NOT INITIAL.

      " Sales Area
      IF line_exists( gs_unknown-sales_area[ sales_organization   = is_order-sales_organization
                                             distribution_channel = is_order-distribution_channel
                                             division             = is_order-division ] ).
        APPEND VALUE #( msgno            = '200'
                        msgty            = 'E'
                        msgtx            = message_text( iv_msgno = '200'
                                                         iv_v1    = |{ is_order-sales_organization }|
                                                         iv_v2    = |{ is_order-distribution_channel }|
                                                         iv_v3    = |{ is_order-division }| )
                        sf_header_id_ref = is_order-sf_header_id_ref
                        field            = `SalesOrganization, DistributionChannel, Division`
                      ) TO rt_error.
      ENDIF.

      " Customer Sales Area
      IF is_order-sold_to_party IS NOT INITIAL.
        APPEND VALUE #( customer = zcl_zsde002_validator=>to_internal_customer( is_order-sold_to_party )
                        value    = |{ is_order-sold_to_party }|
                        field    = `sold_to_party` ) TO lt_partner.
      ENDIF.

      IF is_order-ship_to_party IS NOT INITIAL.
        APPEND VALUE #( customer = zcl_zsde002_validator=>to_internal_customer( is_order-ship_to_party )
                        value    = |{ is_order-ship_to_party }|
                        field    = `ship_to_party` ) TO lt_partner.
      ENDIF.

      IF is_order-bill_to_party IS NOT INITIAL.
        APPEND VALUE #( customer = zcl_zsde002_validator=>to_internal_customer( is_order-bill_to_party )
                        value    = |{ is_order-bill_to_party }|
                        field    = `bill_to_party` ) TO lt_partner.
      ENDIF.

      IF is_order-payer IS NOT INITIAL.
        APPEND VALUE #( customer = zcl_zsde002_validator=>to_internal_customer( is_order-payer )
                        value    = |{ is_order-payer }|
                        field    = `payer` ) TO lt_partner.
      ENDIF.

      IF is_order-stock_van IS NOT INITIAL.
        APPEND VALUE #( customer = zcl_zsde002_validator=>to_internal_customer( is_order-stock_van )
                        value    = |{ is_order-stock_van }|
                        field    = `stock_van` ) TO lt_partner.
      ENDIF.

      LOOP AT lt_partner ASSIGNING FIELD-SYMBOL(<lfs_partner>).
        IF line_exists( gs_unknown-cust_sales_area[ sales_organization   = is_order-sales_organization
                                                    distribution_channel = is_order-distribution_channel
                                                    division             = is_order-division
                                                    customer             = <lfs_partner>-customer ] ).
          APPEND VALUE #( msgno            = '201'
                          msgty            = 'E'
                          msgtx            = message_text( iv_msgno = '201'
                                                           iv_v1    = |{ is_order-sales_organization }|
                                                           iv_v2    = |{ is_order-distribution_channel }|
                                                           iv_v3    = |{ is_order-division }|
                                                           iv_v4    = <lfs_partner>-value )
                          sf_header_id_ref = is_order-sf_header_id_ref
                          field            = zcl_zsde002_json=>to_json_name( <lfs_partner>-field )
                        ) TO rt_error.
        ENDIF.
      ENDLOOP.

    ENDIF.

    " Sales Document Type
    IF is_order-sales_order_type IS NOT INITIAL.
      lv_sales_doc_type = is_order-sales_order_type.

      IF line_exists( gs_unknown-sales_document_type[ table_line = lv_sales_doc_type ] ).
        APPEND VALUE #( msgno            = '202'
                        msgty            = 'E'
                        msgtx            = message_text( iv_msgno = '202'
                                                         iv_v1    = |{ is_order-sales_order_type }| )
                        sf_header_id_ref = is_order-sf_header_id_ref
                        field            = zcl_zsde002_json=>to_json_name( 'sales_order_type' )
                      ) TO rt_error.
      ENDIF.
    ENDIF.

    " Payment Terms
    IF is_order-payment_term IS NOT INITIAL.
      lv_payment_terms = is_order-payment_term.

      IF line_exists( gs_unknown-payment_terms[ table_line = lv_payment_terms ] ).
        APPEND VALUE #( msgno            = '203'
                        msgty            = 'E'
                        msgtx            = message_text( iv_msgno = '203'
                                                         iv_v1    = |{ is_order-payment_term }| )
                        sf_header_id_ref = is_order-sf_header_id_ref
                        field            = zcl_zsde002_json=>to_json_name( 'payment_term' )
                      ) TO rt_error.
      ENDIF.
    ENDIF.

    " Currency
    IF is_order-currency IS NOT INITIAL.
      lv_currency = is_order-currency.

      IF line_exists( gs_unknown-currency[ table_line = lv_currency ] ).
        APPEND VALUE #( msgno            = '204'
                        msgty            = 'E'
                        msgtx            = message_text( iv_msgno = '204'
                                                         iv_v1    = |{ is_order-currency }| )
                        sf_header_id_ref = is_order-sf_header_id_ref
                        field            = zcl_zsde002_json=>to_json_name( 'currency' )
                      ) TO rt_error.
      ENDIF.
    ENDIF.

    " Order Condition Type
    LOOP AT it_pricing ASSIGNING FIELD-SYMBOL(<lfs_pricing>).
      CHECK <lfs_pricing>-condition_type IS NOT INITIAL.

      lv_condition_type = <lfs_pricing>-condition_type.

      IF line_exists( gs_unknown-condition_type[ table_line = lv_condition_type ] ).
        APPEND VALUE #( msgno            = '205'
                        msgty            = 'E'
                        msgtx            = message_text( iv_msgno = '205'
                                                         iv_v1    = |{ <lfs_pricing>-condition_type }| )
                        sf_header_id_ref = is_order-sf_header_id_ref
                        field            = zcl_zsde002_json=>to_json_name( 'condition_type' )
                      ) TO rt_error.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD check_item_master_data.

    DATA lv_material       TYPE zif_zsde002_master_data=>ty_product.
    DATA lv_product        TYPE zif_zsde002_master_data=>ty_product.
    DATA lv_plant          TYPE zif_zsde002_master_data=>ty_plant.
    DATA lv_condition_type TYPE zif_zsde002_master_data=>ty_condition_type.

    " Product
    " ส่ง MaterialNumber มา → เช็คกับ I_Product
    " ส่งแต่ CustomerMaterial → ปล่อยให้ SD determine material จาก info record ตอนสร้าง SO
    "   (I_CustomerMaterial ไม่ released สำหรับ ABAP Cloud จึงเช็คฝั่งนี้ไม่ได้)
    IF is_item-material_number IS NOT INITIAL.

      lv_product = zcl_zsde002_validator=>to_internal_material( is_item-material_number ).

      IF line_exists( gs_unknown-product[ table_line = lv_product ] ).
        APPEND VALUE #( msgno            = '250'
                        msgty            = 'E'
                        msgtx            = message_text( iv_msgno = '250'
                                                         iv_v1    = |{ is_item-material_number }| )
                        sf_header_id_ref = is_order-sf_header_id_ref
                        sf_item_id_ref   = is_item-sf_item_id_ref
                        field            = zcl_zsde002_json=>to_json_name( 'material_number' )
                      ) TO rt_error.
      ELSE.
        lv_material = lv_product.
      ENDIF.

    ENDIF.

    " Plant
    IF is_item-plant IS NOT INITIAL.
      lv_plant = is_item-plant.

      IF line_exists( gs_unknown-plant[ table_line = lv_plant ] ).
        APPEND VALUE #( msgno            = '251'
                        msgty            = 'E'
                        msgtx            = message_text( iv_msgno = '251'
                                                         iv_v1    = |{ is_item-plant }| )
                        sf_header_id_ref = is_order-sf_header_id_ref
                        sf_item_id_ref   = is_item-sf_item_id_ref
                        field            = zcl_zsde002_json=>to_json_name( 'plant' )
                      ) TO rt_error.
      ENDIF.
    ENDIF.

    " Storage Location
    IF  is_item-plant            IS NOT INITIAL
    AND is_item-storage_location IS NOT INITIAL.

      IF line_exists( gs_unknown-storage_location[ plant            = is_item-plant
                                                   storage_location = is_item-storage_location ] ).
        APPEND VALUE #( msgno            = '252'
                        msgty            = 'E'
                        msgtx            = message_text( iv_msgno = '252'
                                                         iv_v1    = |{ is_item-storage_location }|
                                                         iv_v2    = |{ is_item-plant }| )
                        sf_header_id_ref = is_order-sf_header_id_ref
                        sf_item_id_ref   = is_item-sf_item_id_ref
                        field            = zcl_zsde002_json=>to_json_name( 'storage_location' )
                      ) TO rt_error.
      ENDIF.
    ENDIF.

    " Sales Unit
    " ข้ามถ้า material ยังหาไม่เจอ จะได้ไม่ขึ้น error ซ้อนกัน 2 บรรทัด
    IF  lv_material        IS NOT INITIAL
    AND is_item-sales_unit IS NOT INITIAL.

      IF line_exists( gs_unknown-product_unit[ product          = lv_material
                                               alternative_unit = is_item-sales_unit ] ).
        APPEND VALUE #( msgno            = '253'
                        msgty            = 'E'
                        msgtx            = message_text( iv_msgno = '253'
                                                         iv_v1    = COND #( WHEN is_item-material_number IS NOT INITIAL
                                                                            THEN |{ is_item-material_number }|
                                                                            ELSE |{ is_item-customer_material }| )
                                                         iv_v2    = |{ is_item-sales_unit }| )
                        sf_header_id_ref = is_order-sf_header_id_ref
                        sf_item_id_ref   = is_item-sf_item_id_ref
                        field            = zcl_zsde002_json=>to_json_name( 'sales_unit' )
                      ) TO rt_error.
      ENDIF.
    ENDIF.

    " Item Condition Type
    LOOP AT it_pricing ASSIGNING FIELD-SYMBOL(<lfs_pricing>).
      CHECK <lfs_pricing>-condition_type IS NOT INITIAL.

      lv_condition_type = <lfs_pricing>-condition_type.

      IF line_exists( gs_unknown-condition_type[ table_line = lv_condition_type ] ).
        APPEND VALUE #( msgno            = '254'
                        msgty            = 'E'
                        msgtx            = message_text( iv_msgno = '254'
                                                         iv_v1    = |{ <lfs_pricing>-condition_type }| )
                        sf_header_id_ref = is_order-sf_header_id_ref
                        sf_item_id_ref   = is_item-sf_item_id_ref
                        field            = zcl_zsde002_json=>to_json_name( 'condition_type' )
                      ) TO rt_error.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD find_duplicate_header.

    DATA lt_seen TYPE string_table.

    LOOP AT it_order ASSIGNING FIELD-SYMBOL(<lfs_order>).

      CHECK <lfs_order>-sf_header_id_ref IS NOT INITIAL.

      IF line_exists( lt_seen[ table_line = <lfs_order>-sf_header_id_ref ] ).
        IF NOT line_exists( rt_result[ table_line = <lfs_order>-sf_header_id_ref ] ).
          APPEND <lfs_order>-sf_header_id_ref TO rt_result.
        ENDIF.
      ELSE.
        APPEND <lfs_order>-sf_header_id_ref TO lt_seen.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD save.

    INSERT ztsd_e002_order FROM @is_order.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
      RETURN.
    ENDIF.

    " ตารางลูกว่างเป็นเรื่องปกติ — INSERT FROM TABLE ที่ไม่ได้เขียนแถวไหนเลยคืน sy-subrc = 4
    " ซึ่งไม่ใช่ error จึงต้องข้าม ไม่ใช่ rollback
    IF it_order_pricing IS NOT INITIAL.
      INSERT ztsd_e002_ordprc FROM TABLE @it_order_pricing.
      IF sy-subrc <> 0.
        ROLLBACK WORK.
        RETURN.
      ENDIF.
    ENDIF.

    IF it_item IS NOT INITIAL.
      INSERT ztsd_e002_item FROM TABLE @it_item.
      IF sy-subrc <> 0.
        ROLLBACK WORK.
        RETURN.
      ENDIF.
    ENDIF.

    IF it_item_pricing IS NOT INITIAL.
      INSERT ztsd_e002_itmprc FROM TABLE @it_item_pricing.
      IF sy-subrc <> 0.
        ROLLBACK WORK.
        RETURN.
      ENDIF.
    ENDIF.

    IF it_order_message IS NOT INITIAL.
      INSERT ztsd_e002_ordmsg FROM TABLE @it_order_message.
      IF sy-subrc <> 0.
        ROLLBACK WORK.
        RETURN.
      ENDIF.
    ENDIF.

    COMMIT WORK AND WAIT.
    rv_result = abap_true.

  ENDMETHOD.


  METHOD post.

    DATA(ls_result) = NEW zcl_zsde002_so_create( )->create(
                        is_order         = cs_order
                        it_order_pricing = it_order_pricing
                        it_item          = it_item
                        it_item_pricing  = it_item_pricing
                        is_param         = gs_param ).

    cs_order-sales_order_number = ls_result-sales_order_number.

    APPEND LINES OF ls_result-errors TO ct_error.

  ENDMETHOD.


  METHOD to_order_out.

    TRY.
        DATA(lv_tzone) = cl_abap_context_info=>get_user_time_zone( ).
      CATCH cx_abap_context_info_error.
        CLEAR lv_tzone.
    ENDTRY.

    IF lv_tzone IS INITIAL.
      lv_tzone = 'UTC'.
    ENDIF.

    CONVERT TIME STAMP is_order-created_at
            TIME ZONE  lv_tzone
            INTO DATE  DATA(lv_date)
                 TIME  DATA(lv_time).

    DATA(lv_date_out) = |{ lv_date+6(2) }-{ lv_date+4(2) }-{ lv_date(4) }|.
    DATA(lv_time_out) = |{ lv_time(2) }:{ lv_time+2(2) }:{ lv_time+4(2) }|.

    " สำเร็จ = มีเลข SO และไม่มี error → 1 แถว
    IF  is_order-sales_order_number IS NOT INITIAL
    AND NOT line_exists( it_error[ msgty = 'E' ] ).

      APPEND VALUE #( status             = is_order-order_status
                      code               = '500'
                      message            = message_text( iv_msgno = '500'
                                                         iv_msgty = 'S'
                                                         iv_v1    = |{ is_order-sales_order_number }| )
                      sales_order_number = is_order-sales_order_number
                      document_type      = is_order-sales_order_type
                      customer_reference = is_order-customer_reference
                      sf_header_id_ref   = is_order-sf_header_id_ref
                      processing_date    = lv_date_out
                      processing_time    = lv_time_out
                    ) TO rt_result.

      RETURN.

    ENDIF.

    " ไม่สำเร็จ → 1 แถวต่อ 1 error
    LOOP AT it_error ASSIGNING FIELD-SYMBOL(<lfs_error>) WHERE msgty = 'E'.

      APPEND VALUE #( status             = is_order-order_status
                      code               = |{ <lfs_error>-msgno }|
                      message            = <lfs_error>-msgtx
                      sales_order_number = is_order-sales_order_number
                      document_type      = is_order-sales_order_type
                      customer_reference = is_order-customer_reference
                      sf_header_id_ref   = is_order-sf_header_id_ref
                      sf_item_id_ref     = <lfs_error>-sf_item_id_ref
                      processing_date    = lv_date_out
                      processing_time    = lv_time_out
                      field              = <lfs_error>-field
                    ) TO rt_result.

    ENDLOOP.

    " กันเคสที่ไม่สำเร็จแต่ไม่มี error message เลย — ไม่ควรเกิด แต่ถ้าเกิดจะทำให้ order หายจาก response
    IF rt_result IS INITIAL.
      APPEND VALUE #( status             = is_order-order_status
                      code               = '501'
                      message            = message_text( iv_msgno = '501'
                                                         iv_v1    = |{ is_order-sf_header_id_ref }| )
                      sales_order_number = is_order-sales_order_number
                      document_type      = is_order-sales_order_type
                      customer_reference = is_order-customer_reference
                      sf_header_id_ref   = is_order-sf_header_id_ref
                      processing_date    = lv_date_out
                      processing_time    = lv_time_out
                    ) TO rt_result.
    ENDIF.

  ENDMETHOD.


  METHOD add_request_message.

    APPEND VALUE #( status  = iv_msgty
                    code    = |{ iv_msgno }|
                    message = message_text( iv_msgno = iv_msgno
                                            iv_msgty = iv_msgty
                                            iv_v1    = iv_v1
                                            iv_v2    = iv_v2
                                            iv_v3    = iv_v3 )
                  ) TO cs_result-orders.

    IF iv_msgty = 'E'.
      cs_result-status = 'E'.
    ENDIF.

  ENDMETHOD.


  METHOD to_request_body.

    TRY.
        rv_result = xco_cp_json=>data->from_abap( is_order
                      )->apply( VALUE #( ( xco_cp_json=>transformation->underscore_to_pascal_case ) )
                      )->to_string( ).
      CATCH cx_root.
        CLEAR rv_result.
    ENDTRY.

  ENDMETHOD.


  METHOD to_order_message.

    LOOP AT it_error ASSIGNING FIELD-SYMBOL(<lfs_error>).

      APPEND VALUE #( order_message_uuid    = new_uuid( )
                      order_uuid            = is_order-order_uuid
                      msg_seq               = sy-tabix
                      message_area          = COND #( WHEN <lfs_error>-sf_item_id_ref IS NOT INITIAL
                                                        OR <lfs_error>-msgno BETWEEN '150' AND '199'
                                                        OR <lfs_error>-msgno BETWEEN '250' AND '299'
                                                      THEN 'ITEM'
                                                      ELSE 'HEADER' )
                      status                = COND #( WHEN <lfs_error>-msgty IS INITIAL
                                                      THEN 'E'
                                                      ELSE <lfs_error>-msgty )
                      message               = <lfs_error>-msgtx
                      created_by            = is_order-created_by
                      created_at            = is_order-created_at
                      last_changed_by       = is_order-last_changed_by
                      last_changed_at       = is_order-last_changed_at
                      local_last_changed_at = is_order-local_last_changed_at
                    ) TO rt_result.

    ENDLOOP.

  ENDMETHOD.


  METHOD new_uuid.

    TRY.
        rv_result = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
        CLEAR rv_result.
    ENDTRY.

  ENDMETHOD.


  METHOD to_errors.

    LOOP AT it_finding ASSIGNING FIELD-SYMBOL(<lfs_finding>).
      APPEND VALUE #( msgno            = <lfs_finding>-msgno
                      msgty            = <lfs_finding>-msgty
                      msgtx            = message_text( iv_msgno = <lfs_finding>-msgno
                                                       iv_msgty = <lfs_finding>-msgty
                                                       iv_v1    = <lfs_finding>-msgv1
                                                       iv_v2    = <lfs_finding>-msgv2
                                                       iv_v3    = <lfs_finding>-msgv3
                                                       iv_v4    = <lfs_finding>-msgv4 )
                      sf_header_id_ref = iv_sf_header_id_ref
                      sf_item_id_ref   = iv_sf_item_id_ref
                      field            = zcl_zsde002_json=>to_json_name( <lfs_finding>-field )
                    ) TO rt_error.
    ENDLOOP.

  ENDMETHOD.


  METHOD message_text.

    " กัน DEFAULT ไม่ทำงานตอนผู้เรียกส่งค่าว่างมาเอง — MESSAGE TYPE ว่างใช้ไม่ได้
    DATA(lv_msgty) = COND symsgty( WHEN iv_msgty IS INITIAL THEN 'E' ELSE iv_msgty ).

    MESSAGE ID 'ZSDE002' TYPE lv_msgty NUMBER iv_msgno
    WITH iv_v1 iv_v2 iv_v3 iv_v4
    INTO rv_result.

  ENDMETHOD.

ENDCLASS.
