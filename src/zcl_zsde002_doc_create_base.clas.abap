CLASS zcl_zsde002_doc_create_base DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_zsde002_doc_create
      ABSTRACT METHODS create.

    ALIASES create FOR zif_zsde002_doc_create~create.

  PROTECTED SECTION.

    TYPES ty_amount   TYPE p LENGTH 11 DECIMALS 2.
    TYPES ty_quantity TYPE p LENGTH 13 DECIMALS 3.
    TYPES ty_ratio    TYPE p LENGTH 11 DECIMALS 3.

    " item ใน log กับ %cid ที่ใช้ตอนสร้าง
    " หลัง commit ใช้ %cid หาเลข item จริงจาก MAPPED
    TYPES: BEGIN OF ty_item_cid,
             item_uuid TYPE ztsd_e002_item-item_uuid,
             cid       TYPE string,
           END OF ty_item_cid,
           tt_item_cid TYPE STANDARD TABLE OF ty_item_cid WITH EMPTY KEY.

    " ค่าที่จะใส่ใน pricing element row พร้อม flag ว่า field ไหนต้องส่ง — ผู้เรียกเอา flag ไปตั้ง %control
    " เพราะ RAP ปฏิเสธ field ที่ condition type นั้นไม่รับ แม้จะส่งค่าว่าง/ศูนย์ก็ตาม
    " (CONDITIONQUANTITY must not be changed due to configuration of condition type ZDI3)
    TYPES: BEGIN OF ty_condition_values,
             rate_amount   TYPE ty_amount,
             rate_ratio    TYPE ty_ratio,
             ratio_unit    TYPE ztsd_e002_ordprc-condition_unit_of_measure,
             currency      TYPE ztsd_e002_ordprc-condition_currency,
             quantity      TYPE ty_quantity,
             quantity_unit TYPE ztsd_e002_ordprc-condition_unit_of_measure,
             send_amount   TYPE abap_bool,
             send_ratio    TYPE abap_bool,
             send_currency TYPE abap_bool,
             send_quantity TYPE abap_bool,
           END OF ty_condition_values.

    CONSTANTS gc_ratio_unit_percent TYPE ztsd_e002_ordprc-condition_unit_of_measure VALUE '%'.

    TYPES: BEGIN OF ty_cid_counter,
             prefix TYPE string,
             seq    TYPE i,
           END OF ty_cid_counter.

    DATA gt_cid_counter TYPE HASHED TABLE OF ty_cid_counter WITH UNIQUE KEY prefix.

    CONSTANTS gc_cid_header TYPE string VALUE 'H01'.
    CONSTANTS gc_langu      TYPE spras  VALUE 'E'.

    METHODS next_cid
      IMPORTING iv_prefix        TYPE string
      RETURNING VALUE(rv_result) TYPE string.

    METHODS to_internal_date
      IMPORTING iv_value         TYPE clike
      RETURNING VALUE(rv_result) TYPE d.

    METHODS to_internal_amount
      IMPORTING iv_value         TYPE clike
      RETURNING VALUE(rv_result) TYPE ty_amount.

    METHODS to_internal_quantity
      IMPORTING iv_value         TYPE clike
      RETURNING VALUE(rv_result) TYPE ty_quantity.

    METHODS to_internal_ratio
      IMPORTING iv_value         TYPE clike
      RETURNING VALUE(rv_result) TYPE ty_ratio.

    "! เลือกว่า condition นี้ส่ง field ชุดไหน ตาม calculation type จาก I_PricingConditionType
    "! A / H / I = Percentage > ratio + '%'
    "! B = fixed amount > amount + currency
    "! C และอื่นๆ = quantity > amount + currency + quantity + unit
    "! condition ที่ไม่มีใน it_calc_type ไม่ควรมาถึงตรงนี้
    METHODS to_condition_values
      IMPORTING iv_condition_type TYPE ztsd_e002_ordprc-condition_type
                iv_amount         TYPE clike
                iv_currency       TYPE clike
                iv_pricing_unit   TYPE clike
                iv_unit           TYPE clike
                it_calc_type      TYPE zif_zsde002_master_data=>tt_condition_calc_type
      RETURNING VALUE(rs_result)  TYPE ty_condition_values.

    "! แปลง flag ของ to_condition_values เป็น %control flag ของ RAP
    METHODS control_flag
      IMPORTING iv_send          TYPE abap_bool
      RETURNING VALUE(rv_result) TYPE abp_behv_flag.

    "! เก็บทุก message จาก REPORTED (ทั้ง modify และ commit)
    "! ข้อความจาก RAP เป็น free text จึงใช้ message 000 แล้วใส่ข้อความลง msgtx ตรงๆ
    "! ไม่ผ่าน message_text เพราะ placeholder ของ T100 ตัดที่ 50 ตัวอักษร
    METHODS collect_reported
      IMPORTING is_reported         TYPE any
                iv_sf_header_id_ref TYPE zif_zsde002_doc_create=>ty_order-sf_header_id_ref
      CHANGING  ct_error            TYPE zif_zsde002_doc_create=>tt_error.

    "! ใส่ custom message error (501 / 502) เฉพาะเคสที่ไม่มี message error จาก RAP มาอธิบาย
    METHODS add_summary
      IMPORTING iv_msgno            TYPE symsgno
                iv_sf_header_id_ref TYPE zif_zsde002_doc_create=>ty_order-sf_header_id_ref
      CHANGING  ct_error            TYPE zif_zsde002_doc_create=>tt_error.

    "! message success (500) พร้อมเลขเอกสาร SD ที่สร้างได้
    METHODS add_success
      IMPORTING iv_document_number  TYPE zif_zsde002_doc_create=>ty_order-sales_order_number
                iv_sf_header_id_ref TYPE zif_zsde002_doc_create=>ty_order-sf_header_id_ref
      CHANGING  ct_error            TYPE zif_zsde002_doc_create=>tt_error.

ENDCLASS.



CLASS ZCL_ZSDE002_DOC_CREATE_BASE IMPLEMENTATION.


  METHOD next_cid.

    FIELD-SYMBOLS <lfs_counter> TYPE ty_cid_counter.

    READ TABLE gt_cid_counter ASSIGNING <lfs_counter>
    WITH TABLE KEY prefix = iv_prefix.

    IF sy-subrc <> 0.
      INSERT VALUE #( prefix = iv_prefix
                      seq    = 0
                    ) INTO TABLE gt_cid_counter ASSIGNING <lfs_counter>.
    ENDIF.

    <lfs_counter>-seq = <lfs_counter>-seq + 1.

    rv_result = |{ iv_prefix }{ <lfs_counter>-seq }|.

  ENDMETHOD.


  METHOD to_internal_date.

    DATA(lv_internal) = zcl_zsde002_json=>to_internal_date( CONV #( iv_value ) ).

    IF strlen( lv_internal ) = 8.
      rv_result = lv_internal.
    ENDIF.

  ENDMETHOD.


  METHOD to_internal_amount.

    IF iv_value IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        rv_result = CONV #( iv_value ).
      CATCH cx_sy_conversion_no_number.
        CLEAR rv_result.
    ENDTRY.

  ENDMETHOD.


  METHOD to_internal_quantity.

    IF iv_value IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        rv_result = CONV #( iv_value ).
      CATCH cx_sy_conversion_no_number.
        CLEAR rv_result.
    ENDTRY.

  ENDMETHOD.


  METHOD to_internal_ratio.

    IF iv_value IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        rv_result = CONV #( iv_value ).
      CATCH cx_sy_conversion_no_number.
        CLEAR rv_result.
    ENDTRY.

  ENDMETHOD.


  METHOD to_condition_values.

    DATA(lv_calc_type) = VALUE #( it_calc_type[ condition_type = iv_condition_type ]-calculation_type
                                  OPTIONAL ).

    CASE lv_calc_type.

      WHEN 'A' OR 'H' OR 'I'.
        rs_result-rate_ratio    = to_internal_ratio( iv_amount ).
        rs_result-ratio_unit    = gc_ratio_unit_percent.
        rs_result-send_ratio    = abap_true.

      WHEN 'B'.
        rs_result-rate_amount   = to_internal_amount( iv_amount ).
        rs_result-currency      = iv_currency.
        rs_result-send_amount   = abap_true.
        rs_result-send_currency = abap_true.

      WHEN OTHERS.
        rs_result-rate_amount   = to_internal_amount( iv_amount ).
        rs_result-currency      = iv_currency.
        rs_result-quantity      = to_internal_quantity( iv_pricing_unit ).
        rs_result-quantity_unit = iv_unit.
        rs_result-send_amount   = abap_true.
        rs_result-send_currency = abap_true.
        rs_result-send_quantity = abap_true.

    ENDCASE.

  ENDMETHOD.


  METHOD control_flag.
    rv_result = COND #( WHEN iv_send = abap_true THEN if_abap_behv=>mk-on
                                                 ELSE if_abap_behv=>mk-off ).
  ENDMETHOD.


  METHOD collect_reported.

    FIELD-SYMBOLS <lft_reported> TYPE ANY TABLE.
    FIELD-SYMBOLS <lfs_row>      TYPE any.
    FIELD-SYMBOLS <lfo_msg>      TYPE REF TO if_abap_behv_message.

    DATA(lo_reported) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( is_reported ) ).

    LOOP AT lo_reported->components ASSIGNING FIELD-SYMBOL(<lfs_comp>).
      ASSIGN COMPONENT <lfs_comp>-name OF STRUCTURE is_reported TO <lft_reported>.
      CHECK sy-subrc = 0.

      LOOP AT <lft_reported> ASSIGNING <lfs_row>.

        ASSIGN COMPONENT '%MSG' OF STRUCTURE <lfs_row> TO <lfo_msg>.
        CHECK sy-subrc = 0 AND <lfo_msg> IS BOUND.

        APPEND VALUE #( msgno            = '000'
                        msgty            = <lfo_msg>->m_severity
                        msgtx            = <lfo_msg>->if_message~get_text( )
                        sf_header_id_ref = iv_sf_header_id_ref
                      ) TO ct_error.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.


  METHOD add_summary.

    IF line_exists( ct_error[ msgty = 'E' ] ).
      RETURN.
    ENDIF.

    APPEND VALUE #( msgno            = iv_msgno
                    msgty            = 'E'
                    msgtx            = zcl_zsde002_processor=>message_text(
                                         iv_msgno = iv_msgno
                                         iv_v1    = |{ iv_sf_header_id_ref }| )
                    sf_header_id_ref = iv_sf_header_id_ref
                  ) TO ct_error.

  ENDMETHOD.


  METHOD add_success.

    APPEND VALUE #( msgno            = '500'
                    msgty            = 'S'
                    msgtx            = zcl_zsde002_processor=>message_text(
                                         iv_msgno = '500'
                                         iv_msgty = 'S'
                                         iv_v1    = |{ iv_document_number }| )
                    sf_header_id_ref = iv_sf_header_id_ref
                  ) TO ct_error.

  ENDMETHOD.
ENDCLASS.
